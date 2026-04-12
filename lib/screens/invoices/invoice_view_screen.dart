import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../services/pdf_service.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class InvoiceViewScreen extends StatelessWidget {
  final String id;

  const InvoiceViewScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final invoice = provider.store.findInvoice(id);

        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: Text(s.invoices)),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        final client = provider.store.findClient(invoice.clientId ?? '');

        final fmt     = NumberFormat('#,##0.00');
        final intFmt  = NumberFormat('#,###');
        final dateFmt = DateFormat('dd/MM/yyyy');
        final sym     = provider.settings.currencySymbol;

        String dateStr = invoice.date;
        try {
          dateStr = dateFmt.format(DateTime.parse(invoice.date));
        } catch (_) {}

        final isPaid = invoice.paymentStatus == PaymentStatus.paid;

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.number),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/invoices'),
            ),
            actions: [
              if (!isPaid)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: s.markPaid,
                  onPressed: () => _markPaid(context, provider),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: s.edit,
                onPressed: () => context.push('/invoices/$id/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: s.print,
                onPressed: () => _printPdf(
                  context,
                  invoice: invoice,
                  client: client,
                  brickTypes: provider.brickTypes,
                  settings: provider.settings,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header card ──────────────────────────────────────
                _HeaderCard(
                  invoice: invoice,
                  dateStr: dateStr,
                  sym: sym,
                  fmt: fmt,
                ),
                const SizedBox(height: 12),

                // ── Client info ───────────────────────────────────────
                if (client != null)
                  _InfoCard(
                    title: '${s.billTo}  •  ជូនដល់',
                    children: [
                      InfoRow(
                        label: s.name,
                        value: client.name,
                        valueStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (client.address.isNotEmpty)
                        InfoRow(label: s.address, value: client.address),
                      if (client.phone.isNotEmpty)
                        InfoRow(label: s.phone, value: client.phone),
                      InfoRow(label: s.date, value: dateStr),
                    ],
                  ),
                const SizedBox(height: 12),

                // ── Items ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.list_alt,
                                color: AppColors.forest, size: 18),
                            const SizedBox(width: 8),
                            Text(s.items,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 16),
                        _tableHeader(s),
                        const Divider(height: 4),
                        ...invoice.items.asMap().entries.map((e) =>
                            _tableRow(
                              e.key,
                              e.value,
                              sym,
                              fmt,
                              intFmt,
                              provider.store.findBrickType(
                                  e.value.brickTypeId ?? ''),
                            )),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '${s.subtotal}: $sym${fmt.format(invoice.subtotal)}',
                                    style: const TextStyle(fontSize: 13)),
                                if (invoice.tax > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                      'Tax: $sym${fmt.format(invoice.tax)}',
                                      style: const TextStyle(fontSize: 13)),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${s.total}: $sym${fmt.format(invoice.total)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Notes ─────────────────────────────────────────────
                if (invoice.notes.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.notes,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate)),
                          const SizedBox(height: 6),
                          Text(invoice.notes),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _printPdf(
                        context,
                        invoice: invoice,
                        client: client,
                        brickTypes: provider.brickTypes,
                        settings: provider.settings,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(s.print),
                    ),
                    if (!isPaid)
                      OutlinedButton.icon(
                        onPressed: () => _markPaid(context, provider),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(s.markPaid),
                      ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/invoices/$id/edit'),
                      icon: const Icon(Icons.edit),
                      label: Text(s.edit),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      onPressed: () => _delete(context, provider),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(s.delete),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader(dynamic s) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Expanded(
            flex: 3,
            child: Text('Brick Type',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted))),
        SizedBox(
            width: 60,
            child: Text(s.quantity,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted))),
        SizedBox(
            width: 55,
            child: Text(s.unitPrice,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted))),
        SizedBox(
            width: 65,
            child: Text(s.total,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted))),
      ],
    );
  }

  Widget _tableRow(int idx, InvoiceItem item, String sym,
      NumberFormat fmt, NumberFormat intFmt, BrickType? brickType) {
    return Container(
      color: idx.isEven ? AppColors.mint : AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${idx + 1}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              brickType?.name ?? 'Brick',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              intFmt.format(item.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              '$sym${fmt.format(item.unitPrice)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(
              '$sym${fmt.format(item.total)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(
    BuildContext context, {
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
  }) async {
    final bytes = await PdfService.generateInvoice(
      invoice: invoice,
      client: client,
      brickTypes: brickTypes,
      settings: settings,
    );
    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  Future<void> _markPaid(
      BuildContext context, AppProvider provider) async {
    await provider.markInvoicePaid(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice marked as paid')),
      );
    }
  }

  Future<void> _delete(
      BuildContext context, AppProvider provider) async {
    final ok = await showDeleteDialog(context, itemName: 'Invoice');
    if (!ok) return;
    await provider.deleteInvoice(id);
    if (context.mounted) context.go('/invoices');
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Invoice invoice;
  final String dateStr;
  final String sym;
  final NumberFormat fmt;

  const _HeaderCard({
    required this.invoice,
    required this.dateStr,
    required this.sym,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.forestDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                    color: Colors.white.withAlpha(210), fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sym${fmt.format(invoice.total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(
                status: invoice.status.name,
                label: invoice.status.label,
              ),
              const SizedBox(height: 2),
              StatusBadge(
                status: invoice.paymentStatus.name,
                label: invoice.paymentStatus.label,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

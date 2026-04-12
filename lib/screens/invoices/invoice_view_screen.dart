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

        final client = provider.store.findClient(invoice.clientId);
        final car = provider.store.findCar(invoice.carId);
        final workers = invoice.workerIds
            .map((wid) => provider.store.findWorker(wid))
            .whereType<Worker>()
            .toList();
        final borrow = provider.store.findBorrow(invoice.borrowId);
        final borrowVendor =
            borrow != null ? provider.store.findVendor(borrow.vendorId) : null;

        final fmt = NumberFormat('#,##0.00');
        final intFmt = NumberFormat('#,###');
        final dateFmt = DateFormat('dd/MM/yyyy');
        final sym = provider.settings.currencySymbol;

        String dateStr = invoice.date;
        try {
          dateStr = dateFmt.format(DateTime.parse(invoice.date));
        } catch (_) {}

        return Scaffold(
          appBar: AppBar(
            title: Text(invoice.number),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/invoices'),
            ),
            actions: [
              if (invoice.status != InvoiceStatus.paid)
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
                  car: car,
                  workers: workers,
                  borrow: borrow,
                  borrowVendor: borrowVendor,
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
                  isKh: provider.isKh,
                ),
                const SizedBox(height: 12),

                // ── Client + Delivery ─────────────────────────────────
                LayoutBuilder(builder: (ctx, constraints) {
                  final wide = constraints.maxWidth > 500;
                  final clientCard = _InfoCard(
                    title: '${s.billTo}  •  ជូនដល់',
                    children: [
                      if (client != null) ...[
                        InfoRow(
                          label: s.name,
                          value: client.name,
                          valueStyle: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        if (client.nameKh.isNotEmpty)
                          InfoRow(label: '', value: client.nameKh),
                        if (client.address.isNotEmpty)
                          InfoRow(
                              label: s.address, value: client.address),
                        if (client.phone.isNotEmpty)
                          InfoRow(label: s.phone, value: client.phone),
                      ] else
                        const Text('—',
                            style: TextStyle(color: AppColors.muted)),
                    ],
                  );
                  final deliveryCard = _InfoCard(
                    title: '${s.delivery}  •  ការដឹក',
                    children: [
                      if (car != null) ...[
                        InfoRow(
                            label: s.plateNumber, value: car.plateNumber),
                        InfoRow(
                          label: s.capacity,
                          value:
                              '${intFmt.format(car.capacity)} bricks',
                        ),
                      ],
                      if (workers.isNotEmpty)
                        InfoRow(
                          label: s.workers,
                          value: workers.map((w) => w.name).join(', '),
                        ),
                      InfoRow(label: s.date, value: dateStr),
                    ],
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: clientCard),
                        const SizedBox(width: 12),
                        Expanded(child: deliveryCard),
                      ],
                    );
                  }
                  return Column(children: [
                    clientCard,
                    const SizedBox(height: 12),
                    deliveryCard,
                  ]);
                }),
                const SizedBox(height: 12),

                // ── Car capacity bar ──────────────────────────────────
                if (car != null) _CarCapacityBar(invoice: invoice, car: car),
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
                            _tableRow(e.key, e.value, sym, fmt, intFmt)),
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

                // ── Borrowed bricks ───────────────────────────────────
                if (borrow != null && borrowVendor != null)
                  _BorrowCard(
                      borrow: borrow, vendor: borrowVendor, sym: sym, fmt: fmt, s: s),
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
                        car: car,
                        workers: workers,
                        borrow: borrow,
                        borrowVendor: borrowVendor,
                        settings: provider.settings,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(s.print),
                    ),
                    if (invoice.status != InvoiceStatus.paid)
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
            child: Text(s.description,
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
      NumberFormat fmt, NumberFormat intFmt) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style: const TextStyle(fontSize: 12)),
                if (item.descriptionKh.isNotEmpty)
                  Text(item.descriptionKh,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                Text(item.unit,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.muted)),
              ],
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
    required Car? car,
    required List<Worker> workers,
    required Borrow? borrow,
    required Vendor? borrowVendor,
    required AppSettings settings,
  }) async {
    final bytes = await PdfService.generateInvoice(
      invoice: invoice,
      client: client,
      car: car,
      workers: workers,
      borrowVendor: borrowVendor,
      borrow: borrow,
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
    if (ok && context.mounted) {
      await provider.deleteInvoice(id);
      context.go('/invoices');
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Invoice invoice;
  final String dateStr;
  final String sym;
  final NumberFormat fmt;
  final bool isKh;

  const _HeaderCard({
    required this.invoice,
    required this.dateStr,
    required this.sym,
    required this.fmt,
    required this.isKh,
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
              StatusBadge(
                status: invoice.status.name,
                label: isKh
                    ? invoice.status.labelKh
                    : invoice.status.label,
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

class _CarCapacityBar extends StatelessWidget {
  final Invoice invoice;
  final Car car;

  const _CarCapacityBar({required this.invoice, required this.car});

  @override
  Widget build(BuildContext context) {
    final used = invoice.totalBricks;
    final ratio = (used / car.capacity).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final fmt = NumberFormat('#,###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping,
                    color: AppColors.forest, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Car Load  •  ការផ្ទុករថយន្ត',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${fmt.format(used)} / ${fmt.format(car.capacity)} bricks ($pct%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: ratio > 0.9 ? AppColors.warning : AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.border,
                color: ratio > 0.9 ? AppColors.warning : AppColors.forest,
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorrowCard extends StatelessWidget {
  final Borrow borrow;
  final Vendor vendor;
  final String sym;
  final NumberFormat fmt;
  final dynamic s;

  const _BorrowCard({
    required this.borrow,
    required this.vendor,
    required this.sym,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFCD34D)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text(
                '${s.borrowedBricks}  •  ឥដ្ឋខ្ចី',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InfoRow(label: s.vendor, value: vendor.name),
          InfoRow(
            label: s.quantity,
            value: '${NumberFormat('#,###').format(borrow.quantity)} bricks',
          ),
          InfoRow(
            label: s.amountOwed,
            value: '$sym${fmt.format(borrow.totalAmount)}',
            valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.warning),
          ),
          InfoRow(
            label: s.status,
            value: borrow.status == BorrowStatus.paid ? 'Paid' : 'Owed',
          ),
        ],
      ),
    );
  }
}

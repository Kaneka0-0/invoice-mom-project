import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../services/invoice_html_service.dart';
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
        final fmt = NumberFormat('#,##0.00');
        final intFmt = NumberFormat('#,###');
        final dateFmt = DateFormat('dd MMM yyyy');
        final sym = provider.settings.currencySymbol;
        final invoiceTotal = invoice.items.fold(0.0, (s, i) => s + i.quantity * i.unitPrice);

        String dateStr = invoice.date;
        try {
          dateStr = dateFmt.format(DateTime.parse(invoice.date));
        } catch (_) {}

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: CustomScrollView(
            slivers: [
              // ── Page header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back + actions row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 18, color: Color(0xFF0B2218)),
                                onPressed: () => context.go('/invoices'),
                              ),
                              const Spacer(),
                              _ActionBtn(
                                icon: Icons.edit_outlined,
                                onTap: () => context.push('/invoices/$id/edit'),
                              ),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                icon: Icons.picture_as_pdf_outlined,
                                onTap: () => _printPdf(
                                  context,
                                  invoice: invoice,
                                  client: client,

                                  settings: provider.settings,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Title block
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: Text(
                            invoice.number,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D1F17),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (client != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 3, 20, 0),
                            child: Text(client.name,
                                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                          ),
                        // Amount + date strip
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Amount',
                                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$sym${fmt.format(invoiceTotal)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0B2218),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _StatusPill(invoice.status.name),
                                  const SizedBox(height: 6),
                                  Text(dateStr,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Client info
                    if (client != null) ...[
                      _SectionCard(
                        icon: Icons.person_outline_rounded,
                        label: s.billTo,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B2218).withAlpha(12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0B2218),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0D1F17))),
                                  if (client.phone.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 12, color: AppColors.muted),
                                      const SizedBox(width: 4),
                                      Text(client.phone,
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.muted)),
                                    ]),
                                  ],
                                  if (client.address.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 12, color: AppColors.muted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(client.address,
                                            style: const TextStyle(
                                                fontSize: 12, color: AppColors.muted)),
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Date',
                                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                const SizedBox(height: 3),
                                Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D1F17))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Items
                    _SectionCard(
                      icon: Icons.inventory_2_outlined,
                      label: s.items,
                      child: Column(
                        children: [
                          _ItemsTable(
                            invoice: invoice,
                            sym: sym,
                            fmt: fmt,
                            intFmt: intFmt,
                            provider: provider,
                          ),
                        ],
                      ),
                    ),

                    // Notes
                    if (invoice.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        icon: Icons.notes_rounded,
                        label: s.notes,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(10),
                            border: const Border(
                              left: BorderSide(color: Color(0xFF0B2218), width: 3),
                            ),
                          ),
                          child: Text(
                            invoice.notes,
                            style: const TextStyle(
                                fontSize: 13.5, color: AppColors.slate, height: 1.5),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    _ActionButtons(
                      s: s,
                      onPrint: () => _printPdf(
                        context,
                        invoice: invoice,
                        client: client,
                        settings: provider.settings,
                      ),
                      onEdit: () => context.push('/invoices/$id/edit'),
                      onDelete: () => _delete(context, provider),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printPdf(
    BuildContext context, {
    required Invoice invoice,
    required Client? client,
    required AppSettings settings,
  }) async {
    if (kIsWeb) {
      await InvoiceHtmlService.download(
        invoice: invoice,
        client: client,
        settings: settings,
      );
    } else {
      final bytes = await PdfService.generateInvoice(
        invoice: invoice,
        client: client,
        brickTypes: const [],
        settings: settings,
      );
      if (context.mounted) {
        await Printing.layoutPdf(onLayout: (_) => bytes);
      }
    }
  }

  Future<void> _delete(BuildContext context, AppProvider provider) async {
    final ok = await showDeleteDialog(context, itemName: 'Invoice');
    if (!ok) return;
    await provider.deleteInvoice(id);
    if (context.mounted) context.go('/invoices');
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0B2218),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final label = status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor(status))),
    );
  }
}

// ── (removed _HeroHeader placeholder) ────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final Invoice invoice;
  final String dateStr;
  final String sym;
  final NumberFormat fmt;

  const _HeroHeader({
    required this.invoice,
    required this.dateStr,
    required this.sym,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = invoice.status.name[0].toUpperCase() +
        invoice.status.name.substring(1).replaceAll('_', ' ');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2218), Color(0xFF1A4030)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF86EFAC), size: 12),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: Color(0xFF86EFAC), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: statusLabel),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                      color: Color(0xFFBBF7D0), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$sym${fmt.format(invoice.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2218).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: const Color(0xFF0B2218)),
                ),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B2218),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF0D1F17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Items table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final Invoice invoice;
  final String sym;
  final NumberFormat fmt;
  final NumberFormat intFmt;
  final AppProvider provider;

  const _ItemsTable({
    required this.invoice,
    required this.sym,
    required this.fmt,
    required this.intFmt,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final computedTotal = invoice.items.fold(0.0, (s, i) => s + i.quantity * i.unitPrice);
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B2218),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 22),
              Expanded(
                flex: 3,
                child: Text('Brick Type',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const _HeaderCell('ចំនួន'),
              _HeaderCell('Price'),
              _HeaderCell('Total', last: true),
            ],
          ),
        ),
        const SizedBox(height: 2),
        ...invoice.items.asMap().entries.map((e) {
          return _ItemRow(
            idx: e.key,
            item: e.value,
            sym: sym,
            fmt: fmt,
            intFmt: intFmt,
            isKh: provider.isKh,
            isLast: e.key == invoice.items.length - 1,
          );
        }),
        const SizedBox(height: 12),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2218).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('TOTAL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B2218),
                      letterSpacing: 0.6)),
            ),
            Text(
              '$sym${fmt.format(computedTotal)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B2218),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (invoice.deposit > 0) ...[
          const SizedBox(height: 8),
          _TotalRow(
            label: 'Deposit',
            value: '$sym${fmt.format(invoice.deposit)}',
          ),
          _TotalRow(
            label: 'Balance',
            value: '$sym${fmt.format(computedTotal - invoice.deposit)}',
            bold: true,
          ),
        ],
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool last;
  const _HeaderCell(this.text, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: last ? 70 : 60,
      child: Text(text,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

String _brickName(String priceType, String category, bool isKh) {
  if (isKh) {
    final t = priceType == 'burned' ? 'ឥដ្ឋខ្លោច' : 'ឥដ្ឋធម្មតា';
    final c = category == 'sol' ? 'ចំនួន' : 'ប្រហោង';
    return '$t $c';
  }
  final t = priceType == 'burned' ? 'Burnt' : 'Normal';
  final c = category == 'sol' ? 'Sol' : 'Hol';
  return '$t $c';
}

class _ItemRow extends StatelessWidget {
  final int idx;
  final InvoiceItem item;
  final String sym;
  final NumberFormat fmt;
  final NumberFormat intFmt;
  final bool isKh;
  final bool isLast;

  const _ItemRow({
    required this.idx,
    required this.item,
    required this.sym,
    required this.fmt,
    required this.intFmt,
    required this.isKh,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat('#,##0.000');
    final typeColor =
        item.priceType == 'normal' ? const Color(0xFF059669) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF0B2218).withAlpha(20),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF0B2218), fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _brickName(item.priceType, item.brickCategory, isKh),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF0D1F17), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              intFmt.format(item.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '$sym${priceFmt.format(item.unitPrice)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '$sym${fmt.format(item.quantity * item.unitPrice)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B2218),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: bold ? const Color(0xFF0D1F17) : AppColors.muted)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  color: const Color(0xFF0D1F17))),
        ],
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final dynamic s;
  final VoidCallback onPrint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionButtons({
    required this.s,
    required this.onPrint,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: onPrint,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
            label: Text(s.print, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B2218),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _SecondaryBtn(
            icon: Icons.edit_outlined,
            label: s.edit,
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _SecondaryBtn(
            icon: Icons.delete_outline_rounded,
            label: s.delete,
            onTap: onDelete,
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : const Color(0xFF0B2218);
    final bg = danger ? AppColors.danger.withAlpha(12) : const Color(0xFF0B2218).withAlpha(10);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AppBar button ─────────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

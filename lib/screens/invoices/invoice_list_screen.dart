import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';
import 'package:printing/printing.dart';
import '../../../services/pdf_service.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _search = '';
  String _statusFilter = 'all';
  String? _monthFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final sym = provider.settings.currencySymbol;

        var filtered = provider.invoices.where((inv) {
          final client = provider.store.findClient(inv.clientId);
          final matchSearch = _search.isEmpty ||
              inv.number.toLowerCase().contains(_search.toLowerCase()) ||
              (client?.name.toLowerCase().contains(_search.toLowerCase()) ??
                  false);
          final matchStatus =
              _statusFilter == 'all' || inv.status.name == _statusFilter;
          final matchMonth =
              _monthFilter == null || inv.date.startsWith(_monthFilter!);
          return matchSearch && matchStatus && matchMonth;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(s.invoices),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: s.monthlyExport,
                onPressed: _monthFilter == null
                    ? null
                    : () => _exportMonthly(context, provider, filtered),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: s.newInvoice,
                onPressed: () => context.push('/invoices/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // ── Filters ──────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: s.search,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _statusFilter == 'all',
                            onTap: () =>
                                setState(() => _statusFilter = 'all'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.draft,
                            selected: _statusFilter == 'draft',
                            onTap: () =>
                                setState(() => _statusFilter = 'draft'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.pending,
                            selected: _statusFilter == 'pending',
                            onTap: () =>
                                setState(() => _statusFilter = 'pending'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.paid,
                            selected: _statusFilter == 'paid',
                            onTap: () =>
                                setState(() => _statusFilter = 'paid'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: Text(_monthFilter ?? s.monthlyExport,
                                style: const TextStyle(fontSize: 12)),
                            onPressed: () => _pickMonth(context),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6)),
                          ),
                          if (_monthFilter != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setState(() => _monthFilter = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: s.noInvoices,
                        actionLabel: s.newInvoice,
                        onAction: () => context.push('/invoices/new'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (ctx, i) {
                          final inv = filtered[i];
                          final client =
                              provider.store.findClient(inv.clientId);
                          return _InvoiceCard(
                            invoice: inv,
                            clientName: client?.name ?? '—',
                            sym: sym,
                            isKh: provider.isKh,
                            onTap: () =>
                                context.push('/invoices/${inv.id}'),
                            onDelete: () async {
                              final ok = await showDeleteDialog(
                                  context,
                                  itemName: 'Invoice');
                              if (ok && context.mounted) {
                                await provider.deleteInvoice(inv.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/invoices/new'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _monthFilter =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _exportMonthly(
    BuildContext context,
    AppProvider provider,
    List<Invoice> invoices,
  ) async {
    if (invoices.isEmpty) return;
    final bytes = await PdfService.generateMonthlyReport(
      invoices: invoices,
      allClients: provider.store.clients,
      settings: provider.settings,
      month: _monthFilter!,
    );
    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.pale,
      checkmarkColor: AppColors.forest,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String clientName;
  final String sym;
  final bool isKh;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.clientName,
    required this.sym,
    required this.isKh,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd/MM/yyyy');
    String dateStr = invoice.date;
    try {
      dateStr = dateFmt.format(DateTime.parse(invoice.date));
    } catch (_) {}

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long,
                      color: AppColors.forest, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.number,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$clientName  •  $dateStr',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.items.length} items',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Amount + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sym${fmt.format(invoice.total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(
                    status: invoice.status.name,
                    label: isKh
                        ? invoice.status.labelKh
                        : invoice.status.label,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.danger,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

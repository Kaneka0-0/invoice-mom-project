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
  String? _clientFilter; // null = all clients

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s   = provider.s;
        final sym = provider.settings.currencySymbol;

        final filtered = provider.invoices.where((inv) {
          final client = provider.store.findClient(inv.clientId);
          final matchSearch = _search.isEmpty ||
              inv.number.toLowerCase().contains(_search.toLowerCase()) ||
              (client?.name.toLowerCase().contains(_search.toLowerCase()) ?? false);
          final matchStatus = _statusFilter == 'all' || inv.status.name == _statusFilter;
          final matchMonth  = _monthFilter == null || inv.date.startsWith(_monthFilter!);
          final matchClient = _clientFilter == null || inv.clientId == _clientFilter;
          return matchSearch && matchStatus && matchMonth && matchClient;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(s.invoices),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF',
                onPressed: filtered.isEmpty
                    ? null
                    : () => _showExportSheet(context, provider, filtered),
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
              // ── Filters ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: s.search,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 10),

                    // Status + Month row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _statusFilter == 'all',
                            onTap: () => setState(() => _statusFilter = 'all'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.draft,
                            selected: _statusFilter == 'draft',
                            onTap: () => setState(() => _statusFilter = 'draft'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.pending,
                            selected: _statusFilter == 'pending',
                            onTap: () => setState(() => _statusFilter = 'pending'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: s.paid,
                            selected: _statusFilter == 'paid',
                            onTap: () => setState(() => _statusFilter = 'paid'),
                          ),
                          const SizedBox(width: 12),
                          // Month picker
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: Text(
                              _monthFilter == null
                                  ? 'Month'
                                  : _monthLabel(_monthFilter!),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickMonth(context),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6)),
                          ),
                          if (_monthFilter != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _monthFilter = null),
                              child: const Icon(Icons.close, size: 16,
                                  color: AppColors.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Client filter row
                    if (provider.clients.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Client:',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'All',
                              selected: _clientFilter == null,
                              onTap: () => setState(() => _clientFilter = null),
                            ),
                            ...provider.clients.map((c) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _FilterChip(
                                  label: c.name,
                                  selected: _clientFilter == c.id,
                                  onTap: () =>
                                      setState(() => _clientFilter = c.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Active filter summary badge
              if (_hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt,
                          size: 14, color: AppColors.forest),
                      const SizedBox(width: 4),
                      Text(
                        '${filtered.length} invoice${filtered.length == 1 ? '' : 's'} shown',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: const Text('Clear all',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.forest,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // ── Invoice list ────────────────────────────────────────────────
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
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) {
                          final inv    = filtered[i];
                          final client = provider.store.findClient(inv.clientId);
                          return _InvoiceCard(
                            invoice: inv,
                            clientName: client?.name ?? '—',
                            sym: sym,
                            isKh: provider.isKh,
                            onTap: () => context.push('/invoices/${inv.id}'),
                            onDelete: () async {
                              final ok = await showDeleteDialog(context,
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

  bool get _hasActiveFilter =>
      _statusFilter != 'all' ||
      _monthFilter != null ||
      _clientFilter != null ||
      _search.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _search       = '';
      _statusFilter = 'all';
      _monthFilter  = null;
      _clientFilter = null;
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now    = DateTime.now();
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

  // ── Export bottom sheet ────────────────────────────────────────────────────
  void _showExportSheet(
      BuildContext context, AppProvider provider, List<Invoice> filtered) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ExportSheet(
        provider: provider,
        filtered: filtered,
        statusFilter: _statusFilter,
        monthFilter: _monthFilter,
        clientFilter: _clientFilter,
      ),
    );
  }

  String _monthLabel(String month) {
    try {
      return DateFormat('MMM yyyy').format(DateTime.parse('$month-01'));
    } catch (_) {
      return month;
    }
  }
}

// ── Export bottom sheet ────────────────────────────────────────────────────────
class _ExportSheet extends StatelessWidget {
  final AppProvider provider;
  final List<Invoice> filtered;
  final String statusFilter;
  final String? monthFilter;
  final String? clientFilter;

  const _ExportSheet({
    required this.provider,
    required this.filtered,
    required this.statusFilter,
    required this.monthFilter,
    required this.clientFilter,
  });

  String get _exportTitle {
    final parts = <String>[];
    if (monthFilter != null) {
      try {
        parts.add(DateFormat('MMMM yyyy')
            .format(DateTime.parse('$monthFilter-01')));
      } catch (_) {
        parts.add(monthFilter!);
      }
    }
    if (clientFilter != null) {
      final c = provider.store.findClient(clientFilter!);
      if (c != null) parts.add(c.name);
    }
    if (statusFilter != 'all') {
      parts.add('${statusFilter[0].toUpperCase()}${statusFilter.substring(1)}');
    }
    return parts.isEmpty ? 'All Invoices' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final sym = provider.settings.currencySymbol;
    final fmt = NumberFormat('#,##0.00');
    final totalRevenue = filtered.fold<double>(0, (s, i) => s + i.total);
    final paidCount = filtered.where((i) => i.status == InvoiceStatus.paid).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.forest, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export Invoices',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_exportTitle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary stats
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.pale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Invoices', value: '${filtered.length}'),
                _StatItem(
                    label: 'Revenue',
                    value: '$sym${fmt.format(totalRevenue)}'),
                _StatItem(label: 'Paid', value: '$paidCount'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Export button
          ElevatedButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.download),
            label: Text('Export ${filtered.length} Invoice${filtered.length == 1 ? '' : 's'} as PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    Navigator.pop(context);
    final bytes = await PdfService.generateBatchReport(
      invoices: filtered,
      allClients: provider.store.clients,
      settings: provider.settings,
      title: _exportTitle,
    );
    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.forest)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────
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

// ── Invoice card ────────────────────────────────────────────────────────────────
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
    final fmt     = NumberFormat('#,##0.00');
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
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.items.length} item${invoice.items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
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

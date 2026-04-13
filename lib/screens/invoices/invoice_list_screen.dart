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
                onPressed: () => _showExportSheet(context, provider),
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
                            label: 'Draft',
                            selected: _statusFilter == 'draft',
                            onTap: () => setState(() => _statusFilter = 'draft'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Confirmed',
                            selected: _statusFilter == 'confirmed',
                            onTap: () => setState(() => _statusFilter = 'confirmed'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Delivered',
                            selected: _statusFilter == 'delivered',
                            onTap: () => setState(() => _statusFilter = 'delivered'),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Cancelled',
                            selected: _statusFilter == 'cancelled',
                            onTap: () => setState(() => _statusFilter = 'cancelled'),
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

                    // Client filter dropdown (searchable)
                    if (provider.clients.isNotEmpty)
                      _ClientFilterDropdown(
                        clients: provider.clients,
                        selectedId: _clientFilter,
                        onChanged: (id) =>
                            setState(() => _clientFilter = id),
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
  void _showExportSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ExportSheet(provider: provider),
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
class _ExportSheet extends StatefulWidget {
  final AppProvider provider;

  const _ExportSheet({required this.provider});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  String? _month;    // 'yyyy-MM' or null = all
  String? _clientId; // null = all clients

  AppProvider get p => widget.provider;

  List<Invoice> get _matched {
    return p.invoices.where((inv) {
      final matchMonth  = _month == null || inv.date.startsWith(_month!);
      final matchClient = _clientId == null || inv.clientId == _clientId;
      return matchMonth && matchClient;
    }).toList();
  }

  String get _title {
    final parts = <String>[];
    if (_month != null) {
      try {
        parts.add(DateFormat('MMMM yyyy').format(DateTime.parse('$_month-01')));
      } catch (_) { parts.add(_month!); }
    }
    if (_clientId != null) {
      final c = p.store.findClient(_clientId);
      if (c != null) parts.add(c.name);
    }
    return parts.isEmpty ? 'All Invoices' : parts.join(' · ');
  }

  String _monthLabel(String m) {
    try { return DateFormat('MMM yyyy').format(DateTime.parse('$m-01')); }
    catch (_) { return m; }
  }

  /// Distinct months that appear in the invoice list, newest first.
  List<String> get _availableMonths {
    final months = p.invoices
        .map((inv) => inv.date.length >= 7 ? inv.date.substring(0, 7) : null)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  void _openSpreadsheet() {
    final invoices = _matched;
    if (invoices.isEmpty) return;
    final title = _title;
    final nav = Navigator.of(context);
    nav.pop(); // close sheet
    nav.push(MaterialPageRoute(
      builder: (_) => _SpreadsheetPage(
        invoices: invoices,
        provider: p,
        title: title,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sym     = p.settings.currencySymbol;
    final fmt     = NumberFormat('#,##0.00');
    final matched = _matched;
    final total   = matched.fold<double>(0, (s, i) => s + i.total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          const Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.forest, size: 22),
              SizedBox(width: 10),
              Text('Export Invoices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Month filter ────────────────────────────────────────────
          const Text('Month',
              style: TextStyle(fontSize: 12, color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            value: _month,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_month_outlined, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All months')),
              ..._availableMonths.map((m) => DropdownMenuItem<String?>(
                  value: m, child: Text(_monthLabel(m)))),
            ],
            onChanged: (v) => setState(() => _month = v),
          ),
          const SizedBox(height: 16),

          // ── Client filter ───────────────────────────────────────────
          const Text('Client',
              style: TextStyle(fontSize: 12, color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            value: _clientId,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All clients')),
              ...p.clients.map((c) => DropdownMenuItem<String?>(
                  value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 20),

          // ── Preview count ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: matched.isEmpty ? AppColors.canvas : AppColors.pale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  matched.isEmpty
                      ? Icons.inbox_outlined
                      : Icons.receipt_long_outlined,
                  size: 16,
                  color: matched.isEmpty ? AppColors.muted : AppColors.forest,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    matched.isEmpty
                        ? 'No invoices match this filter'
                        : '${matched.length} invoice${matched.length == 1 ? '' : 's'}  •  $sym${fmt.format(total)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: matched.isEmpty ? AppColors.muted : AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Open spreadsheet button ─────────────────────────────────
          ElevatedButton.icon(
            onPressed: matched.isEmpty ? null : _openSpreadsheet,
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: Text(matched.isEmpty
                ? 'No invoices match'
                : 'Open ${matched.length} Invoice${matched.length == 1 ? '' : 's'} in Spreadsheet'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Editable row ──────────────────────────────────────────────────────────────
class _EditRow {
  final TextEditingController number;
  final TextEditingController date;
  final TextEditingController client;
  final TextEditingController brickType;
  final TextEditingController qty;
  final TextEditingController price;

  _EditRow({
    required String number,
    required String date,
    required String client,
    required String brickType,
    required int qty,
    required double price,
  })  : number    = TextEditingController(text: number),
        date      = TextEditingController(text: date),
        client    = TextEditingController(text: client),
        brickType = TextEditingController(text: brickType),
        qty       = TextEditingController(text: '$qty'),
        price     = TextEditingController(text: price.toStringAsFixed(2));

  double get total {
    final q = double.tryParse(qty.text.replaceAll(',', '')) ?? 0;
    final p = double.tryParse(price.text.replaceAll(',', '')) ?? 0;
    return q * p;
  }

  void dispose() {
    number.dispose(); date.dispose(); client.dispose();
    brickType.dispose(); qty.dispose(); price.dispose();
  }
}

// ── Spreadsheet page ──────────────────────────────────────────────────────────
class _SpreadsheetPage extends StatefulWidget {
  final List<Invoice> invoices;
  final AppProvider provider;
  final String title;

  const _SpreadsheetPage({
    required this.invoices,
    required this.provider,
    required this.title,
  });

  @override
  State<_SpreadsheetPage> createState() => _SpreadsheetPageState();
}

class _SpreadsheetPageState extends State<_SpreadsheetPage> {
  late List<_EditRow> _rows;
  bool _exporting = false;

  static const _colW    = [90.0, 80.0, 110.0, 110.0, 65.0, 85.0, 85.0];
  static const _headers = ['Invoice #', 'Date', 'Client', 'Brick Type', 'Qty', 'Unit Price', 'Total'];
  static const _tableW  = 90.0 + 80.0 + 110.0 + 110.0 + 65.0 + 85.0 + 85.0 + 6.0; // 631 (625 cols + 6 dividers)

  final _fmt = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _rows = _buildRows();
    for (final r in _rows) {
      r.qty.addListener(_onAmountChanged);
      r.price.addListener(_onAmountChanged);
    }
  }

  void _onAmountChanged() => setState(() {});

  @override
  void dispose() {
    for (final r in _rows) {
      r.qty.removeListener(_onAmountChanged);
      r.price.removeListener(_onAmountChanged);
      r.dispose();
    }
    super.dispose();
  }

  List<_EditRow> _buildRows() {
    final result  = <_EditRow>[];
    final dateFmt = DateFormat('dd/MM/yyyy');
    for (final inv in widget.invoices) {
      final client = widget.provider.store.findClient(inv.clientId);
      String dateStr = inv.date;
      try { dateStr = dateFmt.format(DateTime.parse(inv.date)); } catch (_) {}
      for (final item in inv.items) {
        final bt = widget.provider.store.brickTypes
            .where((b) => b.id == item.brickTypeId)
            .firstOrNull;
        result.add(_EditRow(
          number:    inv.number,
          date:      dateStr,
          client:    client?.name ?? '—',
          brickType: bt?.name ?? 'Brick',
          qty:       item.quantity,
          price:     item.unitPrice,
        ));
      }
    }
    return result;
  }

  double get _grandTotal => _rows.fold(0, (s, r) => s + r.total);

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final sym = widget.provider.settings.currencySymbol;
      final rowMaps = _rows.map((r) => {
        'number':    r.number.text,
        'date':      r.date.text,
        'client':    r.client.text,
        'brickType': r.brickType.text,
        'qty':       r.qty.text,
        'unitPrice': r.price.text,
        'total':     _fmt.format(r.total),
      }).toList();
      final bytes = await PdfService.generateSpreadsheetExport(
        rows: rowMaps, settings: widget.provider.settings,
        title: widget.title, sym: sym,
      );
      if (mounted) await Printing.layoutPdf(onLayout: (_) => bytes);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym   = widget.provider.settings.currencySymbol;
    final total = _grandTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton.icon(
            icon: _exporting
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_exporting ? 'Generating…' : 'Export PDF'),
            onPressed: (_rows.isEmpty || _exporting) ? null : _export,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: AppColors.pale,
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, size: 14, color: AppColors.forest),
                const SizedBox(width: 6),
                Text('${_rows.length} row${_rows.length == 1 ? '' : 's'}  •  tap any cell to edit',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                const Spacer(),
                Text('$sym${_fmt.format(total)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.forest)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _tableW,
                child: Column(
                  children: [
                    _buildHeader(),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (_, i) => _SpreadsheetRow(
                          row: _rows[i], index: i,
                          colW: _colW, fmt: _fmt, sym: sym,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            icon: _exporting
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_exporting
                ? 'Generating…'
                : 'Export ${_rows.length} Row${_rows.length == 1 ? '' : 's'} as PDF'),
            onPressed: (_rows.isEmpty || _exporting) ? null : _export,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.forest,
      child: Row(
        children: List.generate(_headers.length, (i) {
          return SizedBox(
            width: _colW[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Text(_headers[i],
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: i >= 4 ? TextAlign.right : TextAlign.left),
            ),
          );
        }),
      ),
    );
  }
}

// ── Spreadsheet row ───────────────────────────────────────────────────────────
class _SpreadsheetRow extends StatefulWidget {
  final _EditRow row;
  final int index;
  final List<double> colW;
  final NumberFormat fmt;
  final String sym;

  const _SpreadsheetRow({
    required this.row, required this.index,
    required this.colW, required this.fmt, required this.sym,
  });

  @override
  State<_SpreadsheetRow> createState() => _SpreadsheetRowState();
}

class _SpreadsheetRowState extends State<_SpreadsheetRow> {
  @override
  void initState() {
    super.initState();
    widget.row.qty.addListener(_rebuild);
    widget.row.price.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.row.qty.removeListener(_rebuild);
    widget.row.price.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index.isEven;
    final r      = widget.row;
    final total  = r.total;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? AppColors.surface : AppColors.pale,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          _cell(r.number,    widget.colW[0], readOnly: true),
          _vline(),
          _cell(r.date,      widget.colW[1]),
          _vline(),
          _cell(r.client,    widget.colW[2]),
          _vline(),
          _cell(r.brickType, widget.colW[3]),
          _vline(),
          _cell(r.qty,   widget.colW[4], align: TextAlign.right,
              keyboard: TextInputType.number),
          _vline(),
          _cell(r.price, widget.colW[5], align: TextAlign.right,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          _vline(),
          // Total (computed, read-only)
          SizedBox(
            width: widget.colW[6],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              child: Text(
                '${widget.sym}${widget.fmt.format(total)}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vline() => Container(width: 1, height: 40, color: AppColors.border);

  Widget _cell(
    TextEditingController ctrl,
    double width, {
    bool readOnly = false,
    TextAlign align = TextAlign.left,
    TextInputType keyboard = TextInputType.text,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        textAlign: align,
        keyboardType: keyboard,
        style: TextStyle(
            fontSize: 11,
            color: readOnly ? AppColors.muted : AppColors.ink),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.forest, width: 1.5),
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
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
                    label: invoice.status.label,
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

// ── Searchable client filter dropdown ─────────────────────────────────────────
class _ClientFilterDropdown extends StatefulWidget {
  final List<Client> clients;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ClientFilterDropdown({
    required this.clients,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<_ClientFilterDropdown> createState() => _ClientFilterDropdownState();
}

class _ClientFilterDropdownState extends State<_ClientFilterDropdown> {
  final _searchCtrl = TextEditingController();
  final _layerLink  = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  String get _selectedName {
    if (widget.selectedId == null) return 'All Clients';
    return widget.clients
        .firstWhere((c) => c.id == widget.selectedId,
            orElse: () => Client(id: '', name: 'All Clients', createdAt: ''))
        .name;
  }

  void _openDropdown(BuildContext context) {
    if (_open) {
      _closeDropdown();
      return;
    }
    _open = true;
    _searchCtrl.clear();
    _overlay = _buildOverlay(context);
    Overlay.of(context).insert(_overlay!);
  }

  void _closeDropdown() {
    _overlay?.remove();
    _overlay = null;
    _open = false;
    _searchCtrl.clear();
  }

  OverlayEntry _buildOverlay(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
                child: SizedBox(
                  width: size.width,
                  child: _DropdownContent(
                    clients: widget.clients,
                    searchCtrl: _searchCtrl,
                    selectedId: widget.selectedId,
                    onSelect: (id) {
                      widget.onChanged(id);
                      _closeDropdown();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = widget.selectedId != null;
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => _openDropdown(context),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasFilter ? AppColors.pale : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasFilter ? AppColors.forest : AppColors.border,
              width: hasFilter ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline,
                  size: 15,
                  color: hasFilter ? AppColors.forest : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                _selectedName,
                style: TextStyle(
                  fontSize: 12,
                  color: hasFilter ? AppColors.forest : AppColors.slate,
                  fontWeight:
                      hasFilter ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              if (hasFilter)
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                    _closeDropdown();
                  },
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.forest),
                )
              else
                const Icon(Icons.expand_more,
                    size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownContent extends StatefulWidget {
  final List<Client> clients;
  final TextEditingController searchCtrl;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _DropdownContent({
    required this.clients,
    required this.searchCtrl,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_DropdownContent> createState() => _DropdownContentState();
}

class _DropdownContentState extends State<_DropdownContent> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty
        ? widget.clients
        : widget.clients
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: widget.searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          // "All" option
          _DropdownOption(
            label: 'All Clients',
            selected: widget.selectedId == null,
            onTap: () => widget.onSelect(null),
          ),
          // Client list
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                return _DropdownOption(
                  label: c.name,
                  selected: widget.selectedId == c.id,
                  onTap: () => widget.onSelect(c.id),
                );
              },
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No clients found',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: selected ? AppColors.pale : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? AppColors.forest : AppColors.ink,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 16, color: AppColors.forest),
          ],
        ),
      ),
    );
  }
}

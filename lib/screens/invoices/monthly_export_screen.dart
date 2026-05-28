import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/invoice_html_service.dart';
import '../../../services/monthly_pdf_service.dart';
import '../../../services/pdf_service.dart';
import '../../../theme.dart';

const _kDark = Color(0xFF0B2218);

class MonthlyExportScreen extends StatefulWidget {
  const MonthlyExportScreen({super.key});

  @override
  State<MonthlyExportScreen> createState() => _MonthlyExportScreenState();
}

class _MonthlyExportScreenState extends State<MonthlyExportScreen> {
  String? _month;
  String? _clientId;
  bool _generating = false;

  List<Invoice> _matched(AppProvider p) => p.invoices.where((inv) {
        final okMonth  = _month == null || inv.date.startsWith(_month!);
        final okClient = _clientId == null || inv.clientId == _clientId;
        return okMonth && okClient;
      }).toList();

  String _exportTitle(AppProvider p) {
    final parts = <String>[];
    if (_month != null) {
      try {
        parts.add(DateFormat('MMMM yyyy').format(DateTime.parse('$_month-01')));
      } catch (_) {
        parts.add(_month!);
      }
    }
    if (_clientId != null) {
      final c = p.store.findClient(_clientId!);
      if (c != null) parts.add(c.name);
    }
    return parts.isEmpty ? 'All Invoices' : parts.join(' · ');
  }

  String _monthLabel(String m) {
    try {
      return DateFormat('MMM yyyy').format(DateTime.parse('$m-01'));
    } catch (_) {
      return m;
    }
  }

  List<String> _availableMonths(AppProvider p) {
    return p.invoices
        .map((inv) => inv.date.length >= 7 ? inv.date.substring(0, 7) : null)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  void _openSpreadsheet(BuildContext context, AppProvider p) {
    final invoices = _matched(p);
    if (invoices.isEmpty) return;

    Client? client;
    if (_clientId != null) {
      client = p.store.findClient(_clientId!);
    } else {
      final clientIds = invoices.map((inv) => inv.clientId).toSet();
      if (clientIds.length == 1 && clientIds.first != null) {
        client = p.store.findClient(clientIds.first!);
      }
    }

    String monthLabel = _month ?? DateFormat('yyyy-MM').format(DateTime.now());
    if (_month != null) {
      try {
        monthLabel = DateFormat('MMM-yyyy').format(DateTime.parse('$_month-01'));
      } catch (_) {}
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _SpreadsheetPage(
        invoices:   invoices,
        provider:   p,
        title:      _exportTitle(p),
        client:     client,
        monthLabel: monthLabel,
      ),
    ));
  }

  Future<void> _generate(BuildContext context, AppProvider p) async {
    final invoices = _matched(p);
    if (invoices.isEmpty) return;
    setState(() => _generating = true);
    try {
      if (kIsWeb) {
        Client? client;
        if (_clientId != null) {
          client = p.store.findClient(_clientId!);
        } else {
          final ids = invoices.map((i) => i.clientId).toSet();
          if (ids.length == 1 && ids.first != null) client = p.store.findClient(ids.first!);
        }
        String monthLabel = _month ?? DateFormat('yyyy-MM').format(DateTime.now());
        if (_month != null) {
          try { monthLabel = DateFormat('MMM-yyyy').format(DateTime.parse('$_month-01')); } catch (_) {}
        }
        await InvoiceHtmlService.downloadMonthly(
          invoices:   invoices,
          client:     client,
          settings:   p.settings,
          brickTypes: p.store.brickTypes,
          monthLabel: monthLabel,
        );
      } else {
        final month = _month ?? DateFormat('yyyy-MM').format(DateTime.now());
        await showMonthlyPdfPreview(
          context:    context,
          invoices:   invoices,
          allClients: p.clients,
          settings:   p.settings,
          month:      month,
          brickTypes: p.store.brickTypes,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final sym    = provider.settings.currencySymbol;
        final fmt    = NumberFormat('#,##0.00');
        final months = _availableMonths(provider);
        final matched = _matched(provider);
        final total  = matched.fold<double>(0, (s, i) => s + i.total);

        // per-client breakdown
        final byClient = <String, ({List<Invoice> invoices, double total})>{};
        for (final inv in matched) {
          final key = inv.clientId ?? '';
          final e = byClient[key];
          byClient[key] = (
            invoices: [...(e?.invoices ?? []), inv],
            total: (e?.total ?? 0) + inv.total,
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.s.monthlyExport,
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0D1F17),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Export invoices to spreadsheet or PDF',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (matched.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.pale,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.forest.withAlpha(60)),
                            ),
                            child: Text(
                              '$sym${fmt.format(total)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Filter card ────────────────────────────────────────
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionChip(label: 'FILTER BY'),
                            const SizedBox(height: 14),

                            Text('Month',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate)),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _Chip(
                                    label: 'All',
                                    selected: _month == null,
                                    onTap: () => setState(() => _month = null),
                                  ),
                                  ...months.map((m) => _Chip(
                                        label: _monthLabel(m),
                                        selected: _month == m,
                                        onTap: () =>
                                            setState(() => _month = m),
                                      )),
                                ],
                              ),
                            ),

                            if (provider.clients.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              Text('Client',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                initialValue: _clientId,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: AppColors.muted),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 12),
                                  filled: true,
                                  fillColor: const Color(0xFFF4F4F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: _kDark, width: 1.5),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All clients')),
                                  ...provider.clients.map((c) =>
                                      DropdownMenuItem<String?>(
                                          value: c.id,
                                          child: Text(c.name))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _clientId = v),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Summary card ───────────────────────────────────────
                      if (matched.isEmpty)
                        _Card(
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  size: 40, color: AppColors.muted),
                              const SizedBox(height: 10),
                              Text('No invoices match this filter',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.muted)),
                            ],
                          ),
                        )
                      else
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _SectionChip(
                                      label:
                                          '${matched.length} INVOICE${matched.length == 1 ? '' : 'S'}'),
                                  const Spacer(),
                                  Text(
                                    '$sym${fmt.format(total)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              if (byClient.length > 1) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                ...byClient.entries.map((e) {
                                  final client =
                                      provider.store.findClient(e.key);
                                  final name =
                                      client?.name ?? 'Unknown Client';
                                  final count = e.value.invoices.length;
                                  final sub = e.value.total;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: _kDark,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '$count inv.',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.muted),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '$sym${fmt.format(sub)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Pinned bottom actions ──────────────────────────────────────
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (matched.isEmpty || _generating)
                          ? null
                          : () => _generate(context, provider),
                      icon: _generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        matched.isEmpty
                            ? 'No invoices match'
                            : _generating
                                ? 'Generating…'
                                : 'Generate Monthly Invoice PDF',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: matched.isEmpty
                          ? null
                          : () => _openSpreadsheet(context, provider),
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: Text(
                        matched.isEmpty
                            ? 'No invoices match'
                            : 'Open ${matched.length} Invoice${matched.length == 1 ? '' : 's'} in Spreadsheet',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: _kDark, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  const _SectionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kDark : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.slate,
          ),
        ),
      ),
    );
  }
}

// ── Editable row ──────────────────────────────────────────────────────────────
class _EditRow {
  final TextEditingController date;
  final TextEditingController invoiceNo;
  final TextEditingController brickType;
  final TextEditingController qty;
  final TextEditingController price;

  _EditRow({
    required String date,
    required String invoiceNo,
    required String brickType,
    required int qty,
    required double price,
  })  : date      = TextEditingController(text: date),
        invoiceNo = TextEditingController(text: invoiceNo),
        brickType = TextEditingController(text: brickType),
        qty       = TextEditingController(text: '$qty'),
        price     = TextEditingController(text: price.toStringAsFixed(4));

  _EditRow.empty()
      : date      = TextEditingController(),
        invoiceNo = TextEditingController(),
        brickType = TextEditingController(),
        qty       = TextEditingController(),
        price     = TextEditingController();

  bool get isEmpty => qty.text.isEmpty && price.text.isEmpty;

  double get total {
    final q = double.tryParse(qty.text.replaceAll(',', '')) ?? 0;
    final p = double.tryParse(price.text.replaceAll(',', '')) ?? 0;
    return q * p;
  }

  void dispose() {
    date.dispose(); invoiceNo.dispose();
    brickType.dispose(); qty.dispose(); price.dispose();
  }
}

// ── Spreadsheet page ──────────────────────────────────────────────────────────
class _SpreadsheetPage extends StatefulWidget {
  final List<Invoice> invoices;
  final AppProvider provider;
  final String title;
  final Client? client;
  final String monthLabel;

  const _SpreadsheetPage({
    required this.invoices,
    required this.provider,
    required this.title,
    required this.client,
    required this.monthLabel,
  });

  @override
  State<_SpreadsheetPage> createState() => _SpreadsheetPageState();
}

class _SpreadsheetPageState extends State<_SpreadsheetPage> {
  late List<_EditRow> _rows;
  bool _exportingMonthly = false;

  void _resetRows() {
    setState(() {
      for (final r in _rows) {
        r.qty.removeListener(_onAmountChanged);
        r.price.removeListener(_onAmountChanged);
        r.dispose();
      }
      _rows = _buildRows();
      for (final r in _rows) {
        r.qty.addListener(_onAmountChanged);
        r.price.addListener(_onAmountChanged);
      }
    });
  }

  static const _colFlex = [35, 75, 110, 200, 75, 110, 145];
  static const _headers = ['No', 'Date', 'Invoice NO', 'Description', 'Qty', 'Unit Price', 'Total'];

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

  static String _brickDesc(InvoiceItem item, BrickType? bt) {
    if (bt != null) return bt.name;
    final burned = item.priceType == 'burned';
    final hol    = item.brickCategory == 'hol';
    if (!burned && hol)  return 'ឥដ្ឋប្រហោង (Hol)';
    if (!burned && !hol) return 'ឥដ្ឋតាន់ (Sol)';
    if (burned  && hol)  return 'ឥដ្ឋប្រហោង (ខ្លោច)';
    return 'ឥដ្ឋតាន់ (ខ្លោច)';
  }

  List<_EditRow> _buildRows() {
    final result  = <_EditRow>[];
    final dateFmt = DateFormat('dd/MM/yyyy');
    for (final inv in widget.invoices) {
      String dateStr = inv.date;
      try {
        dateStr = dateFmt.format(DateTime.parse(inv.date));
      } catch (_) {}
      for (final item in inv.items) {
        final bt = widget.provider.store.brickTypes
            .where((b) => b.id == item.brickTypeId)
            .firstOrNull;
        result.add(_EditRow(
          date:      dateStr,
          invoiceNo: inv.number,
          brickType: _brickDesc(item, bt),
          qty:       item.quantity,
          price:     item.unitPrice,
        ));
      }
    }
    while (result.length < 10) { result.add(_EditRow.empty()); }
    return result;
  }

  double get _grandTotal => _rows.fold(0, (s, r) => s + r.total);

  List<Map<String, String>> _rowMaps() => _rows.map((r) => {
    'date':      r.date.text,
    'number':    r.invoiceNo.text,
    'brickType': r.brickType.text,
    'qty':       r.qty.text,
    'unitPrice': r.price.text,
    'total':     r.isEmpty ? '' : _fmt.format(r.total),
  }).toList();

  Future<void> _exportMonthlyInvoice() async {
    setState(() => _exportingMonthly = true);
    if (!kIsWeb && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Generating PDF…'),
            ],
          ),
        ),
      );
    }
    try {
      if (kIsWeb) {
        await InvoiceHtmlService.downloadMonthlyFromRows(
          rows:       _rowMaps(),
          client:     widget.client,
          settings:   widget.provider.settings,
          monthLabel: widget.monthLabel,
        );
      } else {
        final sym   = widget.provider.settings.currencySymbol;
        final bytes = await PdfService.generateSpreadsheetExport(
          rows:     _rowMaps(),
          settings: widget.provider.settings,
          title:    widget.title,
          sym:      sym,
        );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          await Printing.layoutPdf(onLayout: (_) => bytes);
        }
      }
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      rethrow;
    } finally {
      if (mounted) setState(() => _exportingMonthly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym   = widget.provider.settings.currencySymbol;
    final total = _grandTotal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title,
            style: const TextStyle(fontSize: 14, color: Colors.white)),
        actions: [
          TextButton.icon(
            icon: _exportingMonthly
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_exportingMonthly ? 'Generating…' : 'Monthly Invoice'),
            onPressed: (_rows.isEmpty || _exportingMonthly) ? null : _exportMonthlyInvoice,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.pale,
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 14, color: AppColors.forest),
                const SizedBox(width: 6),
                Text(
                  '${_rows.length} row${_rows.length == 1 ? '' : 's'}  •  tap any cell to edit',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
                const Spacer(),
                Text('$sym${_fmt.format(total)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest)),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Reset to original data',
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.forest),
                    onPressed: _resetRows,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  const minW      = 750.0;
                  final totalFlex = _colFlex.fold(0, (a, b) => a + b);
                  final isNarrow  = constraints.maxWidth < minW;
                  final tableW    = isNarrow ? minW : constraints.maxWidth;
                  final firstN    = _colFlex.sublist(0, _colFlex.length - 1)
                      .map((f) => f / totalFlex * tableW)
                      .toList();
                  final lastColW  = tableW - firstN.fold(0.0, (a, b) => a + b);
                  final colW      = [...firstN, lastColW];

                  if (isNarrow) {
                    return SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableW,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(colW),
                              const Divider(height: 1, color: AppColors.border),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _rows.length,
                                itemBuilder: (_, i) => _SpreadsheetRow(
                                  row: _rows[i],
                                  index: i,
                                  colW: colW,
                                  fmt: _fmt,
                                  sym: sym,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(colW),
                      const Divider(height: 1, color: AppColors.border),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (_, i) => _SpreadsheetRow(
                            row: _rows[i],
                            index: i,
                            colW: colW,
                            fmt: _fmt,
                            sym: sym,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 12, 50, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: _exportingMonthly
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_exportingMonthly
                    ? 'Generating…'
                    : 'Generate Monthly Invoice PDF'),
                onPressed: (_rows.isEmpty || _exportingMonthly)
                    ? null
                    : _exportMonthlyInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<double> colW) {
    return Container(
      color: _kDark,
      child: Row(
        children: List.generate(_headers.length, (i) {
          final isLast = i == _headers.length - 1;
          return Container(
            width: colW[i],
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white24, width: 0.5),
                    ),
                  ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(_headers[i],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2),
                textAlign: i >= 4 ? TextAlign.right : TextAlign.left,
                softWrap: false,
                overflow: i >= 4 ? TextOverflow.visible : TextOverflow.ellipsis),
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
    required this.row,
    required this.index,
    required this.colW,
    required this.fmt,
    required this.sym,
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
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: widget.colW[0],
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
          _cell(r.date,      widget.colW[1]),
          _cell(r.invoiceNo, widget.colW[2]),
          _cell(r.brickType, widget.colW[3]),
          _cell(r.qty,   widget.colW[4],
              align: TextAlign.right,
              keyboard: TextInputType.number),
          _cell(r.price, widget.colW[5],
              align: TextAlign.right,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          Container(
            width: widget.colW[6],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              widget.row.isEmpty ? '' : '${widget.sym}${widget.fmt.format(total)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest),
              textAlign: TextAlign.right,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    TextEditingController ctrl,
    double width, {
    bool readOnly = false,
    TextAlign align = TextAlign.left,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        textAlign: align,
        keyboardType: keyboard,
        style: TextStyle(
            fontSize: 12,
            color: readOnly ? AppColors.muted : AppColors.ink),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.forest, width: 1.5),
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

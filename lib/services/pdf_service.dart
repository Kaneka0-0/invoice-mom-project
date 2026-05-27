import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

// ─── Colors: individual invoice ───────────────────────────────────────────────
const _ink    = PdfColor.fromInt(0xFF0A0A0A);
const _invRed = PdfColor.fromInt(0xFFBC0000);
const _muted  = PdfColor.fromInt(0xFF616D68);

// ─── Colors: batch / spreadsheet ─────────────────────────────────────────────
const _forest = PdfColor.fromInt(0xFF1B4D3E);
const _border = PdfColor.fromInt(0xFFD6EAE0);
const _pale   = PdfColor.fromInt(0xFFD8F3DC);
const _slate  = PdfColor.fromInt(0xFF4A6A58);

const _grey   = PdfColor.fromInt(0xFF8CA89A);

class PdfService {
  static final _fmt      = NumberFormat('#,##0.00');
  static final _priceFmt = NumberFormat('#,##0.####');
  static final _intFmt   = NumberFormat('#,###');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  // ── Individual invoice (pw.Stack + pw.SvgImage template) ────────────────
  //
  // SVG coordinate space : 420 × 595
  // A4 PDF (no margin)   : 595.28 × 841.89 pt
  // Scale: x * (595.28/420) ≈ x * 1.4173
  //        y * (841.89/595) ≈ y * 1.4150
  //
  // Column x-positions (from SVG path analysis):
  //   Nº 24–54 (w30)  Product 54–176 (w122)  QTY 176–252 (w76)
  //   U.P 252–319 (w67)  Amount 319–396 (w77)
  //
  // Table row y-starts (height 28 each): 237 265 293 321 349
  static Future<Uint8List> generateInvoice({
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
  }) async {
    final doc = pw.Document(title: invoice.number, author: settings.companyName);

    // Fonts (Khmer primary, Inter fallback)
    final khmer     = await PdfGoogleFonts.notoSansKhmerRegular();
    final khmerBold = await PdfGoogleFonts.notoSansKhmerBold();
    final latin     = await PdfGoogleFonts.interRegular();
    final latinBold = await PdfGoogleFonts.interBold();

    // SVG template
    String? svgStr;
    try {
      svgStr = await rootBundle.loadString(
          'assets/invoice-image/individual-invoice.svg');
    } catch (_) {}

    // Logo PNG
    pw.ImageProvider? logo;
    try {
      final data = await rootBundle.load('assets/invoice-image/logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final theme = pw.ThemeData.withFont(
      base: khmer,
      bold: khmerBold,
      fontFallback: [latin, latinBold],
    );

    doc.addPage(pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => _buildInvoicePage(
        invoice: invoice,
        client: client,
        brickTypes: brickTypes,
        settings: settings,
        logo: logo,
        svgStr: svgStr,
        pageW: ctx.page.pageFormat.width,
        pageH: ctx.page.pageFormat.height,
      ),
    ));

    return doc.save();
  }

  static pw.Widget _buildInvoicePage({
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
    required pw.ImageProvider? logo,
    required String? svgStr,
    required double pageW,
    required double pageH,
  }) {
    const svgW = 420.0;
    const svgH = 595.0;
    final sym  = settings.currencySymbol;

    // Convert SVG coordinates → PDF points
    double px(double x) => x * pageW / svgW;
    double py(double y) => y * pageH / svgH;

    // Parse date
    DateTime? dt;
    try { dt = DateTime.parse(invoice.date); } catch (_) {}
    final day   = dt != null ? '${dt.day}'.padLeft(2, '0') : '__';
    final month = dt != null ? '${dt.month}'.padLeft(2, '0') : '__';
    final year  = dt != null ? '${dt.year}' : '____';

    // pw.Positioned has no width/height — size via pw.SizedBox child
    pw.Widget whiteBox(double x, double y, double w, double h) =>
        pw.Positioned(
          left: px(x), top: py(y),
          child: pw.SizedBox(
            width: px(w), height: py(h),
            child: pw.Container(color: PdfColors.white),
          ),
        );

    pw.Widget positioned(double x, double y, double w, pw.Widget child) =>
        pw.Positioned(
          left: px(x), top: py(y),
          child: pw.SizedBox(width: px(w), child: child),
        );

    // Table row data widgets
    const rowYs = [237.0, 265.0, 293.0, 321.0, 349.0];
    final rowWidgets = <pw.Widget>[];
    for (int i = 0; i < invoice.items.length && i < rowYs.length; i++) {
      final item = invoice.items[i];
      final bt   = brickTypes.where((b) => b.id == item.brickTypeId).firstOrNull;
      rowWidgets.add(pw.Positioned(
        left: px(24), top: py(rowYs[i]),
        child: pw.SizedBox(
          width: px(372), height: py(28),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Nº (w=30)
              pw.SizedBox(
                width: px(30),
                child: pw.Center(
                  child: pw.Text('${i + 1}',
                      style: pw.TextStyle(fontSize: 9, color: _ink)),
                ),
              ),
              // Product (w=122)
              pw.SizedBox(
                width: px(122),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4),
                  child: pw.Text(bt?.name ?? '—',
                      style: pw.TextStyle(fontSize: 9, color: _ink)),
                ),
              ),
              // QTY (w=76)
              pw.SizedBox(
                width: px(76),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4),
                  child: pw.Text(_intFmt.format(item.quantity),
                      style: pw.TextStyle(fontSize: 9, color: _ink),
                      textAlign: pw.TextAlign.right),
                ),
              ),
              // U.P (w=67)
              pw.SizedBox(
                width: px(67),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4),
                  child: pw.Text('$sym${_priceFmt.format(item.unitPrice)}',
                      style: pw.TextStyle(fontSize: 9, color: _ink),
                      textAlign: pw.TextAlign.right),
                ),
              ),
              // Amount (w=77)
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4),
                  child: pw.Text('$sym${_fmt.format(item.quantity * item.unitPrice)}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink),
                      textAlign: pw.TextAlign.right),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return pw.Stack(
      children: [
        // ── SVG template (full-page background) ──────────────────────────
        if (svgStr != null)
          pw.Positioned.fill(
            child: pw.SvgImage(svg: svgStr),
          ),

        // ── Logo PNG (replaces the SVG logo) ────────────────────────────
        if (logo != null)
          pw.Positioned(
            left: px(24.4), top: py(14.6),
            child: pw.SizedBox(
              width: px(69.3), height: py(46.2),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          ),

        // ── Company name ─────────────────────────────────────────────────
        whiteBox(100, 3, 215, 68),
        positioned(100, 10, 215,
          pw.Text(settings.companyName,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink),
              textAlign: pw.TextAlign.center),
        ),
        positioned(100, 42, 215,
          pw.Text('Produce, Selling, Transportation',
              style: pw.TextStyle(fontSize: 7, color: _muted),
              textAlign: pw.TextAlign.center),
        ),

        // ── Phone ────────────────────────────────────────────────────────
        whiteBox(25, 76, 152, 34),
        if (settings.phone.isNotEmpty)
          pw.Positioned(
            left: px(45), top: py(82),
            child: pw.Text(settings.phone,
                style: pw.TextStyle(fontSize: 9, color: _ink)),
          ),

        // ── Invoice No ───────────────────────────────────────────────────
        whiteBox(288, 78, 108, 16),
        pw.Positioned(
          left: px(290), top: py(81),
          child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text('No  ', style: pw.TextStyle(fontSize: 9, color: _ink)),
            pw.Text(invoice.number,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _invRed)),
          ]),
        ),

        // ── Date ─────────────────────────────────────────────────────────
        whiteBox(243, 96, 153, 16),
        pw.Positioned(
          left: px(244), top: py(98),
          child: pw.Text('ថ្ងៃទី $day  ខែ $month  ឆ្នាំ $year',
              style: pw.TextStyle(fontSize: 8, color: _ink)),
        ),

        // ── Seller box content ───────────────────────────────────────────
        whiteBox(27, 126, 177, 52),
        positioned(30, 128, 172,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(settings.companyName,
                  style: pw.TextStyle(fontSize: 8, color: _ink)),
              if (settings.address.isNotEmpty)
                pw.Text(settings.address,
                    style: pw.TextStyle(fontSize: 7, color: _muted)),
              if (settings.phone.isNotEmpty)
                pw.Text(settings.phone,
                    style: pw.TextStyle(fontSize: 7, color: _muted)),
            ],
          ),
        ),

        // ── Buyer box content ────────────────────────────────────────────
        whiteBox(230, 126, 164, 52),
        positioned(233, 128, 159,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (client != null) ...[
                pw.Text(client.name,
                    style: pw.TextStyle(fontSize: 8, color: _ink)),
                if (client.phone.isNotEmpty)
                  pw.Text(client.phone,
                      style: pw.TextStyle(fontSize: 7, color: _muted)),
                if (client.address.isNotEmpty)
                  pw.Text(client.address,
                      style: pw.TextStyle(fontSize: 7, color: _muted)),
              ] else
                pw.Text('—', style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ),

        // ── White cover over all table data rows ─────────────────────────
        whiteBox(24, 237, 372, 140),

        // ── Table row data ───────────────────────────────────────────────
        ...rowWidgets,

        // ── Total amount value ───────────────────────────────────────────
        whiteBox(319, 377, 77, 32),
        positioned(319, 381, 74,
          pw.Text('$sym${_fmt.format(invoice.items.fold(0.0, (s, i) => s + i.quantity * i.unitPrice))}',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink),
              textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  // ── Batch / filtered export ────────────────────────────────────────────────
  static Future<Uint8List> generateBatchReport({
    required List<Invoice> invoices,
    required List<Client> allClients,
    required AppSettings settings,
    required String title,
    List<BrickType> brickTypes = const [],
  }) async {
    final doc     = pw.Document(title: title);
    final regular = await PdfGoogleFonts.interRegular();
    final bold    = await PdfGoogleFonts.interBold();
    final theme   = pw.ThemeData.withFont(base: regular, bold: bold);

    doc.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 16, 28, 16),
      header: (ctx) => _batchHeader(settings, title, ctx),
      footer: (ctx) => _batchFooter(settings, ctx),
      build: (ctx) => _buildBatchContent(
        invoices: invoices,
        allClients: allClients,
        brickTypes: brickTypes,
        settings: settings,
        title: title,
      ),
    ));

    return doc.save();
  }

  // Backward-compat wrapper used by existing monthly export button
  static Future<Uint8List> generateMonthlyReport({
    required List<Invoice> invoices,
    required List<Client> allClients,
    required AppSettings settings,
    required String month,
    List<BrickType> brickTypes = const [],
  }) {
    final title = _monthLabel(month);
    return generateBatchReport(
      invoices: invoices,
      allClients: allClients,
      brickTypes: brickTypes,
      settings: settings,
      title: title,
    );
  }

  // ── Spreadsheet export (editable table → PDF) ────────────────────────────
  static Future<Uint8List> generateSpreadsheetExport({
    required List<Map<String, String>> rows,
    required AppSettings settings,
    required String title,
    required String sym,
  }) async {
    final doc     = pw.Document(title: title);
    final regular = await PdfGoogleFonts.interRegular();
    final bold    = await PdfGoogleFonts.interBold();
    final theme   = pw.ThemeData.withFont(base: regular, bold: bold);

    doc.addPage(pw.MultiPage(
      theme:      theme,
      pageFormat: PdfPageFormat.a4,
      margin:     const pw.EdgeInsets.fromLTRB(28, 16, 28, 16),
      header: (ctx) => _batchHeader(settings, title, ctx),
      footer: (ctx) => _batchFooter(settings, ctx),
      build: (ctx) => _buildSpreadsheetContent(rows: rows, sym: sym),
    ));

    return doc.save();
  }

  static List<pw.Widget> _buildSpreadsheetContent({
    required List<Map<String, String>> rows,
    required String sym,
  }) {
    final fmt   = NumberFormat('#,##0.00');
    double total = 0;
    for (final r in rows) {
      total += double.tryParse(r['total']?.replaceAll(',', '') ?? '0') ?? 0;
    }

    return [
      pw.Row(children: [
        pw.Expanded(child: _statBox('Rows', '${rows.length}')),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _statBox('Total', '$sym${fmt.format(total)}')),
      ]),
      pw.SizedBox(height: 14),
      pw.Table(
        border: const pw.TableBorder(
          top: pw.BorderSide(color: _forest, width: 1.5),
          bottom: pw.BorderSide(color: _border),
          horizontalInside: pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FixedColumnWidth(38),
          1: pw.FixedColumnWidth(52),
          2: pw.FixedColumnWidth(72),
          3: pw.FlexColumnWidth(2.5),
          4: pw.FixedColumnWidth(50),
          5: pw.FixedColumnWidth(60),
          6: pw.FixedColumnWidth(62),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _forest),
            children: ['No', 'Date', 'Invoice NO', 'Description', 'Qty', 'Unit Price', 'Total']
                .map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ))
                .toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key.isEven;
            final r      = entry.value;
            final cells  = [
              '${entry.key + 1}', r['date'] ?? '', r['number'] ?? '',
              r['brickType'] ?? '', r['qty'] ?? '',
              '$sym${r['unitPrice'] ?? ''}', '$sym${r['total'] ?? ''}',
            ];
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _pale),
              children: cells.asMap().entries.map((cell) {
                final isTotal    = cell.key == 6;
                final alignRight = cell.key >= 4;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(cell.value,
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: isTotal ? _forest : _slate,
                          fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal),
                      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ];
  }

  // ── Batch: per-page header ─────────────────────────────────────────────────
  static pw.Widget _batchHeader(AppSettings s, String title, pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(color: _forest),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(s.companyName,
              style: pw.TextStyle(
                  color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(title,
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
        ],
      ),
    );
  }

  // ── Batch: per-page footer ─────────────────────────────────────────────────
  static pw.Widget _batchFooter(AppSettings s, pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by ${s.companyName}  •  '
            '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: _grey),
          ),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _grey)),
        ],
      ),
    );
  }

  // ── Batch: content (summary stats + paginated table) ──────────────────────
  static List<pw.Widget> _buildBatchContent({
    required List<Invoice> invoices,
    required List<Client> allClients,
    required List<BrickType> brickTypes,
    required AppSettings settings,
    required String title,
  }) {
    final sym          = settings.currencySymbol;
    final totalRevenue = invoices.fold<double>(0, (s, i) => s + i.total);
    final paidCount    = invoices.where((i) => i.paymentStatus == PaymentStatus.paid).length;
    final pendingCount = invoices.where((i) => i.paymentStatus == PaymentStatus.unpaid).length;

    return [
      // ── Summary stats row ─────────────────────────────────────────────────
      pw.Row(
        children: [
          pw.Expanded(child: _statBox('Total Invoices', '${invoices.length}')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statBox('Total Revenue', '$sym${_fmt.format(totalRevenue)}')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statBox('Paid', '$paidCount')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _statBox('Pending', '$pendingCount')),
        ],
      ),
      pw.SizedBox(height: 14),

      // ── Invoice table (MultiPage auto-paginates) ──────────────────────────
      pw.Table(
        border: const pw.TableBorder(
          top: pw.BorderSide(color: _forest, width: 1.5),
          bottom: pw.BorderSide(color: _border),
          horizontalInside: pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FixedColumnWidth(68),   // Invoice #
          1: pw.FixedColumnWidth(54),   // Date
          2: pw.FlexColumnWidth(2),     // Client
          3: pw.FlexColumnWidth(2.5),   // Brick Type
          4: pw.FixedColumnWidth(52),   // Qty
          5: pw.FixedColumnWidth(62),   // Unit Price
          6: pw.FixedColumnWidth(62),   // Total
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _forest),
            children:
                ['Invoice #', 'Date', 'Client', 'Brick Type', 'Qty', 'Unit Price', 'Total']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5, vertical: 7),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
          ),
          // Data rows — each invoice is one row
          ...invoices.asMap().entries.map((entry) {
            final isEven    = entry.key.isEven;
            final inv       = entry.value;
            final client    = allClients.where((c) => c.id == inv.clientId).firstOrNull;
            final firstItem = inv.items.isNotEmpty ? inv.items.first : null;
            final bt = firstItem != null
                ? brickTypes.where((b) => b.id == firstItem.brickTypeId).firstOrNull
                : null;
            final brickType  = bt?.name ?? (firstItem != null ? 'Brick' : '—');
            final qty        = firstItem != null ? _intFmt.format(firstItem.quantity) : '—';
            final unitPrice  = firstItem != null ? '$sym${_priceFmt.format(firstItem.unitPrice)}' : '—';

            final cells = [
              inv.number,
              _formatDate(inv.date),
              client?.name ?? '—',
              brickType,
              qty,
              unitPrice,
              '$sym${_fmt.format(inv.items.fold(0.0, (s, i) => s + i.quantity * i.unitPrice))}',
            ];

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _pale),
              children: cells.asMap().entries.map((cell) {
                final isTotal    = cell.key == 6;
                final alignRight = cell.key >= 4;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    cell.value,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: isTotal ? _forest : _slate,
                      fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                    textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ];
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _pale,
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: _forest)),
        ],
      ),
    );
  }



  static String _formatDate(String iso) {
    try {
      return _dateFmt.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String _monthLabel(String month) {
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse('$month-01'));
    } catch (_) {
      return month;
    }
  }
}

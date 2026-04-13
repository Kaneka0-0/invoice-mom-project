import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
const _forest = PdfColor.fromInt(0xFF1B4D3E);
const _border = PdfColor.fromInt(0xFFD6EAE0);
const _pale   = PdfColor.fromInt(0xFFD8F3DC);
const _slate  = PdfColor.fromInt(0xFF4A6A58);
const _green  = PdfColor.fromInt(0xFF22A854);
const _amber  = PdfColor.fromInt(0xFFF59E0B);
const _grey   = PdfColor.fromInt(0xFF8CA89A);

class PdfService {
  static final _fmt     = NumberFormat('#,##0.00');
  static final _intFmt  = NumberFormat('#,###');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  // ── Individual invoice ────────────────────────────────────────────────────
  static Future<Uint8List> generateInvoice({
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
  }) async {
    final doc      = pw.Document(title: invoice.number, author: settings.companyName);
    final regular  = await PdfGoogleFonts.interRegular();
    final bold     = await PdfGoogleFonts.interBold();
    final theme    = pw.ThemeData.withFont(base: regular, bold: bold);

    doc.addPage(pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      build: (ctx) => _buildInvoicePage(
          invoice: invoice, client: client, brickTypes: brickTypes, settings: settings),
    ));

    return doc.save();
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

  // ── Spreadsheet export (editable table → PDF) ─────────────────────────────
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
      // Stats
      pw.Row(children: [
        pw.Expanded(child: _statBox('Rows', '${rows.length}')),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _statBox('Total', '$sym${fmt.format(total)}')),
      ]),
      pw.SizedBox(height: 14),

      // Table
      pw.Table(
        border: const pw.TableBorder(
          top: pw.BorderSide(color: _forest, width: 1.5),
          bottom: pw.BorderSide(color: _border),
          horizontalInside: pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: const {
          0: pw.FixedColumnWidth(65),
          1: pw.FixedColumnWidth(52),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2.5),
          4: pw.FixedColumnWidth(50),
          5: pw.FixedColumnWidth(60),
          6: pw.FixedColumnWidth(62),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _forest),
            children: ['Invoice #', 'Date', 'Client', 'Brick Type', 'Qty', 'Unit Price', 'Total']
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
            final r = entry.value;
            final cells = [
              r['number'] ?? '',
              r['date'] ?? '',
              r['client'] ?? '',
              r['brickType'] ?? '',
              r['qty'] ?? '',
              '$sym${r['unitPrice'] ?? ''}',
              '$sym${r['total'] ?? ''}',
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

  // ── Individual invoice page layout ────────────────────────────────────────
  static pw.Widget _buildInvoicePage({
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
  }) {
    final sym = settings.currencySymbol;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Header bar ──────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const pw.BoxDecoration(
            color: _forest,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(settings.companyName,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2)),
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.number,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatDate(invoice.date),
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // ── Client + Invoice meta ─────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Client
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _pale,
                  border: pw.Border.all(color: _border),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CLIENT',
                        style: pw.TextStyle(
                            fontSize: 7,
                            color: _grey,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(client?.name ?? '—',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (client?.phone.isNotEmpty ?? false)
                      pw.Text(client!.phone,
                          style: const pw.TextStyle(fontSize: 9, color: _grey)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            // Invoice meta
            pw.Container(
              width: 160,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _pale,
                border: pw.Border.all(color: _border),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INVOICE DETAILS',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: _grey,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 4),
                  _infoRow('Invoice #:', invoice.number),
                  _infoRow('Date:', _formatDate(invoice.date)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── Items table ───────────────────────────────────────────────
        _brickTable(invoice, brickTypes, settings),
        pw.SizedBox(height: 10),

        // ── Total ─────────────────────────────────────────────────────
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 180,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: _forest,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('$sym${_fmt.format(invoice.total)}',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Items table (shared by individual invoice) ────────────────────────────
  static pw.Widget _brickTable(Invoice invoice, List<BrickType> brickTypes, AppSettings s) {
    final sym = s.currencySymbol;

    final rows = invoice.items.map((item) {
      final bt = brickTypes.where((b) => b.id == item.brickTypeId).firstOrNull;
      return [
        bt?.name ?? 'Brick',
        _intFmt.format(item.quantity),
        '$sym${_fmt.format(item.unitPrice)}',
        '$sym${_fmt.format(item.total)}',
      ];
    }).toList();

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _forest, width: 2),
        bottom: pw.BorderSide(color: _border),
        horizontalInside: pw.BorderSide(color: _border, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FixedColumnWidth(70),
        2: pw.FixedColumnWidth(70),
        3: pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _forest),
          children: ['Brick Type', 'Qty', 'Unit Price', 'Total']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
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
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _pale),
            children: entry.value.asMap().entries.map((cell) {
              final alignRight = cell.key >= 1;
              final isTotalCol = cell.key == 3;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: pw.Text(
                  cell.value,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: isTotalCol ? _forest : _slate,
                    fontWeight: isTotalCol
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                  textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
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
            final unitPrice  = firstItem != null ? '$sym${_fmt.format(firstItem.unitPrice)}' : '—';

            final cells = [
              inv.number,
              _formatDate(inv.date),
              client?.name ?? '—',
              brickType,
              qty,
              unitPrice,
              '$sym${_fmt.format(inv.total)}',
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

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 58,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
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

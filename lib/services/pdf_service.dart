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

  // ── Individual invoice page layout ────────────────────────────────────────
  static pw.Widget _buildInvoicePage({
    required Invoice invoice,
    required Client? client,
    required List<BrickType> brickTypes,
    required AppSettings settings,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _invoiceHeader(settings, invoice),
        pw.SizedBox(height: 18),
        // Client info + Invoice meta side by side
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _clientBox(client)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _invoiceMetaBox(invoice)),
          ],
        ),
        pw.SizedBox(height: 18),
        // Brick items table
        _brickTable(invoice, brickTypes, settings),
        pw.SizedBox(height: 14),
        // Totals right-aligned
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _totalsBox(invoice, settings),
        ),
        pw.SizedBox(height: 28),
        _signatures(),
        pw.Spacer(),
        _footer(settings),
      ],
    );
  }

  // ── Invoice header ────────────────────────────────────────────────────────
  static pw.Widget _invoiceHeader(AppSettings s, Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _forest,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: company
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(s.companyName,
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              if (s.phone.isNotEmpty)
                pw.Text('Tel: ${s.phone}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
              if (s.address.isNotEmpty)
                pw.Text(s.address,
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
          // Right: INVOICE badge + number
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text('INVOICE',
                    style: pw.TextStyle(
                        color: _forest,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2)),
              ),
              pw.SizedBox(height: 6),
              pw.Text(invoice.number,
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(_formatDate(invoice.date),
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Client box ────────────────────────────────────────────────────────────
  static pw.Widget _clientBox(Client? client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pale,
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('CLIENT  •  អតិថិជន'),
          pw.SizedBox(height: 8),
          if (client != null) ...[
            pw.Text(client.name,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 4),
            if (client.phone.isNotEmpty)
              _infoRow('Tel:', client.phone),
            if (client.address.isNotEmpty)
              _infoRow('Location:', client.address),
          ] else
            pw.Text('—', style: const pw.TextStyle(color: _grey)),
        ],
      ),
    );
  }

  // ── Invoice meta box (number, date, status) ───────────────────────────────
  static pw.Widget _invoiceMetaBox(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pale,
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('INVOICE DETAILS'),
          pw.SizedBox(height: 8),
          _infoRow('Invoice #:', invoice.number),
          _infoRow('Date:', _formatDate(invoice.date)),
          _infoRow('Status:', invoice.status.label),
        ],
      ),
    );
  }

  // ── Simplified brick table ─────────────────────────────────────────────────
  static pw.Widget _brickTable(Invoice invoice, List<BrickType> brickTypes, AppSettings s) {
    const headers = ['Brick Type  •  ប្រភេទឥដ្ឋ', 'Qty (bricks)', 'Unit Price', 'Total'];

    final rows = invoice.items.map((item) {
      final bt = brickTypes.where((b) => b.id == item.brickTypeId).firstOrNull;
      return [
        bt?.name ?? 'Brick',
        _intFmt.format(item.quantity),
        '${s.currencySymbol}${_fmt.format(item.unitPrice)}',
        '${s.currencySymbol}${_fmt.format(item.total)}',
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder(
        top: const pw.BorderSide(color: _forest, width: 2),
        bottom: const pw.BorderSide(color: _border),
        horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(72),
        2: const pw.FixedColumnWidth(72),
        3: const pw.FixedColumnWidth(72),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _forest),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: pw.Text(h,
                style: pw.TextStyle(
                    color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key.isEven;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _pale),
            children: entry.value.asMap().entries.map((cell) {
              final isRight = cell.key >= 1;
              final isTotal = cell.key == 3;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: pw.Text(
                  cell.value,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: isTotal ? _forest : _slate,
                    fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                  textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ── Totals box ────────────────────────────────────────────────────────────
  static pw.Widget _totalsBox(Invoice invoice, AppSettings s) {
    final sym = s.currencySymbol;
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pale,
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          _totalRow('Subtotal / សរុបរង', '$sym${_fmt.format(invoice.subtotal)}', false),
          pw.Divider(color: _border, height: 10),
          _totalRow('TOTAL / សរុបរួម', '$sym${_fmt.format(invoice.total)}', true),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, bool isBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: isBold ? 13 : 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isBold ? _forest : _slate)),
      ],
    );
  }

  // ── Signatures ────────────────────────────────────────────────────────────
  static pw.Widget _signatures() {
    return pw.Row(
      children: [
        pw.Expanded(child: _sigBox('Received By  •  ទទួលដោយ')),
        pw.SizedBox(width: 32),
        pw.Expanded(child: _sigBox('Authorized Signature  •  ហត្ថលេខា')),
      ],
    );
  }

  static pw.Widget _sigBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          height: 48,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _slate, width: 0.5)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey)),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _footer(AppSettings s) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Thank you for your business!  •  អរគុណចំពោះការជឿទុកចិត្ត!',
              style: pw.TextStyle(
                  fontSize: 8, color: _forest, fontWeight: pw.FontWeight.bold)),
          pw.Text(s.companyName,
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
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

      // ── Invoice table (MultiPage auto-paginates at ~10 rows/page) ─────────
      pw.Table(
        border: pw.TableBorder(
          top: const pw.BorderSide(color: _forest, width: 1.5),
          bottom: const pw.BorderSide(color: _border),
          horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FixedColumnWidth(68),   // Invoice #
          1: const pw.FixedColumnWidth(54),   // Date
          2: const pw.FlexColumnWidth(2),     // Client
          3: const pw.FlexColumnWidth(2.5),   // Brick type (first item desc)
          4: const pw.FixedColumnWidth(58),   // Qty
          5: const pw.FixedColumnWidth(60),   // Total
          6: const pw.FixedColumnWidth(42),   // Status
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _forest),
            children:
                ['Invoice #', 'Date', 'Client', 'Brick Type', 'Qty', 'Total', 'Status']
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
            final isEven   = entry.key.isEven;
            final inv      = entry.value;
            final client   = allClients.where((c) => c.id == inv.clientId).firstOrNull;
            final firstItem = inv.items.isNotEmpty ? inv.items.first : null;
            final bt = firstItem != null
                ? brickTypes.where((b) => b.id == firstItem.brickTypeId).firstOrNull
                : null;
            final brickType = bt?.name ?? (firstItem != null ? 'Brick' : '—');
            final qty       = firstItem != null
                ? _intFmt.format(firstItem.quantity)
                : '—';
            final statusColor = inv.paymentStatus == PaymentStatus.paid
                ? _green
                : inv.paymentStatus == PaymentStatus.unpaid
                    ? _amber
                    : _grey;

            final cells = [
              inv.number,
              _formatDate(inv.date),
              client?.name ?? '—',
              brickType,
              qty,
              '$sym${_fmt.format(inv.total)}',
              inv.status.label,
            ];

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _pale),
              children: cells.asMap().entries.map((cell) {
                final isStatus = cell.key == 6;
                final isAmount = cell.key == 5;
                final alignRight = cell.key >= 4;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    cell.value,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: isStatus
                          ? statusColor
                          : isAmount
                              ? _forest
                              : _slate,
                      fontWeight: (isStatus || isAmount)
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

  static pw.Widget _sectionLabel(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(color: _forest),
      child: pw.Text(text,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5)),
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

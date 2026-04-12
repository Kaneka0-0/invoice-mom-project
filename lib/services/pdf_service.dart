import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
const _forest = PdfColor.fromInt(0xFF1B4D3E);      // primary green
const _border = PdfColor.fromInt(0xFFD6EAE0);      // soft green border
const _pale = PdfColor.fromInt(0xFFD8F3DC);         // pale green bg
const _slate = PdfColor.fromInt(0xFF4A6A58);        // secondary text
const _green = PdfColor.fromInt(0xFF22A854);        // success green
const _amber = PdfColor.fromInt(0xFFF59E0B);        // warning amber
const _grey = PdfColor.fromInt(0xFF8CA89A);         // muted text

class PdfService {
  static final _fmt = NumberFormat('#,##0.00');
  static final _intFmt = NumberFormat('#,###');
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  /// Generate a single invoice PDF.
  static Future<Uint8List> generateInvoice({
    required Invoice invoice,
    required Client? client,
    required Car? car,
    required List<Worker> workers,
    required Vendor? borrowVendor,
    required Borrow? borrow,
    required AppSettings settings,
  }) async {
    final doc = pw.Document(
      title: invoice.number,
      author: settings.companyName,
    );

    // Load fonts
    final regular = await PdfGoogleFonts.interRegular();
    final bold = await PdfGoogleFonts.interBold();
    final semiBold = await PdfGoogleFonts.interSemiBold();

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
    );

    doc.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (ctx) => _buildPage(
          ctx,
          invoice: invoice,
          client: client,
          car: car,
          workers: workers,
          borrowVendor: borrowVendor,
          borrow: borrow,
          settings: settings,
          regular: regular,
          bold: bold,
          semiBold: semiBold,
        ),
      ),
    );

    return doc.save();
  }

  /// Generate a monthly export — all invoices for a given month.
  static Future<Uint8List> generateMonthlyReport({
    required List<Invoice> invoices,
    required List<Client> allClients,
    required AppSettings settings,
    required String month, // 'YYYY-MM'
  }) async {
    final doc = pw.Document(title: 'Monthly Report $month');
    final regular = await PdfGoogleFonts.interRegular();
    final bold = await PdfGoogleFonts.interBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    // Summary page
    doc.addPage(pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => _buildMonthSummary(
        ctx,
        invoices: invoices,
        allClients: allClients,
        settings: settings,
        month: month,
        regular: regular,
        bold: bold,
      ),
    ));

    return doc.save();
  }

  // ── Invoice page ───────────────────────────────────────────────────────────
  static pw.Widget _buildPage(
    pw.Context ctx, {
    required Invoice invoice,
    required Client? client,
    required Car? car,
    required List<Worker> workers,
    required Vendor? borrowVendor,
    required Borrow? borrow,
    required AppSettings settings,
    required pw.Font regular,
    required pw.Font bold,
    required pw.Font semiBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        _header(settings, invoice),
        pw.SizedBox(height: 16),

        // ── Info row: Bill To + Delivery ──────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _billToBox(client, settings)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _deliveryBox(invoice, car, workers)),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── Items table ───────────────────────────────────────────────
        _itemsTable(invoice, settings),
        pw.SizedBox(height: 8),

        // ── Car capacity bar ─────────────────────────────────────────
        if (car != null) _carCapacityBar(invoice, car),
        pw.SizedBox(height: 8),

        // ── Borrowed bricks note ──────────────────────────────────────
        if (borrow != null && borrowVendor != null)
          _borrowNote(borrow, borrowVendor, settings),
        pw.SizedBox(height: 8),

        // ── Totals ───────────────────────────────────────────────────
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _totalsBox(invoice, settings),
        ),
        pw.SizedBox(height: 16),

        // ── Signatures ───────────────────────────────────────────────
        _signatures(),
        pw.Spacer(),

        // ── Footer ───────────────────────────────────────────────────
        _footer(settings),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  static pw.Widget _header(AppSettings s, Invoice invoice) {
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
          // Left: company info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Brick icon (text-based)
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white.shade(0.15),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '🧱 BRICK FACTORY',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                s.companyName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                s.companyNameKh,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                ),
              ),
              pw.SizedBox(height: 4),
              if (s.address.isNotEmpty)
                pw.Text(
                  s.address,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 9),
                ),
              if (s.phone.isNotEmpty)
                pw.Text(
                  'Tel: ${s.phone}',
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 9),
                ),
            ],
          ),
          // Right: invoice badge
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        color: _forest,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.Text(
                      'វិក្កយបត្រ',
                      style: const pw.TextStyle(
                          color: _forest, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white.shade(0.15),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      invoice.number,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Date: ${_formatDate(invoice.date)}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bill To ───────────────────────────────────────────────────────────────
  static pw.Widget _billToBox(Client? client, AppSettings s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: _pale,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('BILL TO  •  ជូនដល់'),
          pw.SizedBox(height: 6),
          if (client != null) ...[
            pw.Text(
              client.name,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 13),
            ),
            if (client.nameKh.isNotEmpty)
              pw.Text(client.nameKh,
                  style: const pw.TextStyle(fontSize: 11)),
            if (client.address.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(client.address,
                  style: const pw.TextStyle(fontSize: 10)),
            ],
            if (client.phone.isNotEmpty)
              pw.Text('Tel: ${client.phone}',
                  style: const pw.TextStyle(fontSize: 10)),
          ] else
            pw.Text('—', style: const pw.TextStyle(color: _grey)),
        ],
      ),
    );
  }

  // ── Delivery Box ──────────────────────────────────────────────────────────
  static pw.Widget _deliveryBox(
      Invoice invoice, Car? car, List<Worker> workers) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: _pale,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('DELIVERY  •  ការដឹក'),
          pw.SizedBox(height: 6),
          if (car != null) ...[
            _infoRow('Car / Plate:', car.plateNumber),
            _infoRow(
                'Capacity:', '${_intFmt.format(car.capacity)} bricks'),
          ],
          if (workers.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _infoRow('Crew:', workers.map((w) => w.name).join(', ')),
          ],
          if (invoice.date.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _infoRow('Date:', _formatDate(invoice.date)),
          ],
        ],
      ),
    );
  }

  // ── Items table ───────────────────────────────────────────────────────────
  static pw.Widget _itemsTable(Invoice invoice, AppSettings s) {
    final headers = [
      '#',
      'Description / ការពិពណ៌នា',
      'Qty',
      'Unit',
      'Unit Price',
      'Total',
    ];

    final rows = invoice.items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return [
        '${i + 1}',
        item.descriptionKh.isNotEmpty
            ? '${item.description}\n${item.descriptionKh}'
            : item.description,
        _intFmt.format(item.quantity),
        item.unit,
        '${s.currencySymbol}${_fmt.format(item.unitPrice)}',
        '${s.currencySymbol}${_fmt.format(item.total)}',
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
        bottom: const pw.BorderSide(color: _border),
        top: const pw.BorderSide(color: _forest, width: 1.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(65),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _forest),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 7),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key.isEven;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : _pale,
            ),
            children: entry.value.asMap().entries.map((cell) {
              final isRight = cell.key >= 2;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 6),
                child: pw.Text(
                  cell.value,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign:
                      isRight ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ── Car capacity bar ──────────────────────────────────────────────────────
  static pw.Widget _carCapacityBar(Invoice invoice, Car car) {
    final used = invoice.totalBricks;
    final capacity = car.capacity;
    final ratio = (used / capacity).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _pale,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Car Load: ',
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Stack(
              children: [
                pw.Container(
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: const PdfColor(0.9, 0.85, 0.82),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                ),
                // Progress fill — fixed 300pt wide bar container, fill by ratio
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    height: 12,
                    width: 300 * ratio,
                    decoration: pw.BoxDecoration(
                      color: ratio > 0.9 ? _amber : _forest,
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            '${_intFmt.format(used)} / ${_intFmt.format(capacity)} bricks  ($pct%)',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Borrow note ───────────────────────────────────────────────────────────
  static pw.Widget _borrowNote(
      Borrow borrow, Vendor vendor, AppSettings s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1, 0.97, 0.9),
        border: pw.Border.all(color: _amber),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 36,
            color: _amber,
          ),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '⚠ Borrowed Bricks  •  ឥដ្ឋខ្ចី',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
              pw.Text(
                'From: ${vendor.name}  |  '
                'Qty: ${_intFmt.format(borrow.quantity)} bricks  |  '
                'Amount: ${s.currencySymbol}${_fmt.format(borrow.totalAmount)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────
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
          _totalRow('Subtotal / សរុបរង',
              '$sym${_fmt.format(invoice.subtotal)}', false),
          pw.Divider(color: _border, height: 8),
          _totalRow(
            'TOTAL / សរុបរួម',
            '$sym${_fmt.format(invoice.total)}',
            true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, bool bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: bold ? 13 : 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: bold ? _forest : _slate)),
      ],
    );
  }

  // ── Signatures ────────────────────────────────────────────────────────────
  static pw.Widget _signatures() {
    return pw.Row(
      children: [
        pw.Expanded(child: _sigBox('Received By  •  ទទួលដោយ')),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _sigBox('Authorized Signature  •  ហត្ថលេខា')),
      ],
    );
  }

  static pw.Widget _sigBox(String label) {
    return pw.Column(
      children: [
        pw.Container(
          height: 48,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: const pw.BorderSide(color: _slate, width: 0.5),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: _grey)),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _footer(AppSettings s) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Thank you for your business!  •  អរគុណចំពោះការជឿទុកចិត្ត!',
            style: pw.TextStyle(
                fontSize: 8,
                color: _forest,
                fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            s.companyName,
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    );
  }

  // ── Monthly summary page ──────────────────────────────────────────────────
  static pw.Widget _buildMonthSummary(
    pw.Context ctx, {
    required List<Invoice> invoices,
    required List<Client> allClients,
    required AppSettings settings,
    required String month,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    final sym = settings.currencySymbol;
    final totalRevenue =
        invoices.fold<double>(0, (s, i) => s + i.total);
    final paid = invoices.where((i) => i.status == InvoiceStatus.paid);
    final pending =
        invoices.where((i) => i.status == InvoiceStatus.pending);

    final displayMonth = () {
      try {
        final dt = DateTime.parse('$month-01');
        return DateFormat('MMMM yyyy').format(dt);
      } catch (_) {
        return month;
      }
    }();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(color: _forest),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(settings.companyName,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(settings.companyNameKh,
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 11)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('MONTHLY REPORT',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(displayMonth,
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        // Summary stats
        pw.Row(
          children: [
            pw.Expanded(
                child: _statBox('Total Invoices', '${invoices.length}')),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _statBox(
                    'Total Revenue', '$sym${_fmt.format(totalRevenue)}')),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _statBox('Paid', '${paid.length}')),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _statBox('Pending', '${pending.length}')),
          ],
        ),
        pw.SizedBox(height: 16),
        // Table
        pw.Text('Invoices',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside:
                const pw.BorderSide(color: _border, width: 0.5),
            top: const pw.BorderSide(color: _forest, width: 1.5),
            bottom: const pw.BorderSide(color: _border),
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            1: const pw.FixedColumnWidth(70),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FixedColumnWidth(70),
            5: const pw.FixedColumnWidth(50),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _forest),
              children: [
                '#', 'Date', 'Client', 'Items', 'Total', 'Status'
              ]
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ))
                  .toList(),
            ),
            ...invoices.asMap().entries.map((entry) {
              final isEven = entry.key.isEven;
              final inv = entry.value;
              final clientName = allClients
                      .where((c) => c.id == inv.clientId)
                      .firstOrNull
                      ?.name ??
                  '—';
              final statusColor = inv.status == InvoiceStatus.paid
                  ? _green
                  : inv.status == InvoiceStatus.pending
                      ? _amber
                      : _grey;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : _pale),
                children: [
                  inv.number,
                  _formatDate(inv.date),
                  clientName,
                  '${inv.items.length} items',
                  '$sym${_fmt.format(inv.total)}',
                  inv.status.label,
                ]
                    .asMap()
                    .entries
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 5),
                          child: pw.Text(
                            cell.value,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color:
                                  cell.key == 5 ? statusColor : _slate,
                              fontWeight: cell.key == 5
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal,
                            ),
                          ),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: _border, width: 0.5))),
          child: pw.Text(
            'Generated by ${settings.companyName}  •  ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ),
      ],
    );
  }

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
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _forest)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static pw.Widget _sectionLabel(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(color: _forest),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
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
            width: 60,
            child: pw.Text(label,
                style: const pw.TextStyle(fontSize: 9, color: _grey)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 9)),
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
}

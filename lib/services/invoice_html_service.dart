// HTML → PDF invoice service (Flutter web only).
//
// The visual template lives in:
//   assets/invoice_template.html         ← single invoice HTML structure
//   assets/invoice_styles.css            ← single invoice CSS
//   assets/monthly_invoice_template.html ← monthly invoice HTML structure
//   assets/monthly_invoice_styles.css    ← monthly invoice CSS
//
// Both sets of files are loaded as assets at runtime; no Dart rebuild needed
// for CSS or template changes.
//
// JS bridge functions defined in web/index.html:
//   generateInvoicePdf(htmlString, filename)
//   previewInvoicePdf(htmlString, filename, editPath)
//   generateA4Pdf(htmlString, filename)
//   previewMonthlyInvoicePdf(htmlString, filename)

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

class InvoiceHtmlService {
  static final _fmt    = NumberFormat('#,##0.00');
  static final _intFmt = NumberFormat('#,###');

  static Future<void> download({
    required Invoice invoice,
    required Client? client,
    required AppSettings settings,
    String? editPath,
  }) async {
    final sym = settings.currencySymbol.isNotEmpty
        ? settings.currencySymbol
        : '\$';

    // ── Load assets ───────────────────────────────────────────────────────────
    final template   = await rootBundle.loadString('assets/invoice_template.html');
    final css        = await rootBundle.loadString('assets/invoice_styles.css');
    final logoB64     = await _tryB64('assets/invoice-image/logo.png');
    final abaB64      = await _tryB64('assets/invoice-image/ABA.png');
    final acledaB64   = await _tryB64('assets/invoice-image/Aceleda.png');
    final telegramB64 = await _tryB64('assets/invoice-image/telegram.jpg');

    // ── Date parsing ──────────────────────────────────────────────────────────
    DateTime? dt;
    try { dt = DateTime.parse(invoice.date); } catch (_) {}
    final day   = dt != null ? '${dt.day}'.padLeft(2, '0') : '__';
    final month = dt != null ? '${dt.month}'.padLeft(2, '0') : '__';
    final year  = dt != null ? '${dt.year}' : '____';

    // ── Fill static 4-row table: match items by priceType + brickCategory ────
    // R1 = normal/hol, R2 = normal/sol, R3 = burned/hol, R4 = burned/sol
    final itemMap = {
      for (final i in invoice.items) '${i.priceType}/${i.brickCategory}': i
    };
    const slots = ['normal/hol', 'normal/sol', 'burned/hol', 'burned/sol'];

    String rowQty(int idx) {
      final item = itemMap[slots[idx]];
      return item != null ? _intFmt.format(item.quantity) : '';
    }
    String rowUp(int idx) {
      final item = itemMap[slots[idx]];
      return item != null ? '$sym${_fmt.format(item.unitPrice)}' : '';
    }
    String rowAmt(int idx) {
      final item = itemMap[slots[idx]];
      return item != null ? '$sym${_fmt.format(item.total)}' : '';
    }

    // ── Totals ────────────────────────────────────────────────────────────────
    final total   = invoice.total;
    final deposit = invoice.deposit;
    final balance = total - deposit;

    // ── Phone lines — split by comma or newline, one <span> each ─────────────
    final phoneLines = settings.phone
        .split(RegExp(r'[,\n]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => '<span>${_e(p)}</span>')
        .join('');

    // ── Fill template placeholders ────────────────────────────────────────────
    final html = template
      .replaceAll('{{STYLES}}',          css)
      .replaceAll('{{LOGO_DATA_URI}}',   logoB64 != null
          ? 'data:image/png;base64,$logoB64' : '')
      .replaceAll('{{COMPANY_NAME}}',    _e(settings.companyName))
      .replaceAll('{{PHONE_LINES}}',     phoneLines)
      .replaceAll('{{INVOICE_NUMBER}}',  _e(invoice.number))
      .replaceAll('{{DAY}}',             day)
      .replaceAll('{{MONTH}}',           month)
      .replaceAll('{{YEAR}}',            year)
      .replaceAll('{{SELLER_NAME}}',     _e(settings.companyName))
      .replaceAll('{{SELLER_ADDRESS}}',  _e(settings.address))
      .replaceAll('{{SELLER_PHONE}}',    _e(settings.phone))
      .replaceAll('{{BUYER_NAME}}',      _e(client?.name ?? '—'))
      .replaceAll('{{BUYER_ADDRESS}}',   _e(client?.address ?? ''))
      .replaceAll('{{R1_QTY}}', rowQty(0)).replaceAll('{{R1_UP}}', rowUp(0)).replaceAll('{{R1_AMT}}', rowAmt(0))
      .replaceAll('{{R2_QTY}}', rowQty(1)).replaceAll('{{R2_UP}}', rowUp(1)).replaceAll('{{R2_AMT}}', rowAmt(1))
      .replaceAll('{{R3_QTY}}', rowQty(2)).replaceAll('{{R3_UP}}', rowUp(2)).replaceAll('{{R3_AMT}}', rowAmt(2))
      .replaceAll('{{R4_QTY}}', rowQty(3)).replaceAll('{{R4_UP}}', rowUp(3)).replaceAll('{{R4_AMT}}', rowAmt(3))
      .replaceAll('{{TOTAL}}',           '$sym${_fmt.format(total)}')
      .replaceAll('{{DEPOSIT}}',         deposit > 0
          ? '$sym${_fmt.format(deposit)}' : '—')
      .replaceAll('{{BALANCE}}',         '$sym${_fmt.format(balance)}')
      .replaceAll('{{ABA_QR}}',          abaB64 != null
          ? 'data:image/png;base64,$abaB64' : '')
      .replaceAll('{{ACLEDA_QR}}',       acledaB64 != null
          ? 'data:image/png;base64,$acledaB64' : '')
      .replaceAll('{{TELEGRAM_QR}}',     telegramB64 != null
          ? 'data:image/jpeg;base64,$telegramB64' : '');

    // ── Show preview overlay; download button inside it calls generateInvoicePdf
    js.context.callMethod(
        'previewInvoicePdf', [html, 'Invoice-${invoice.number}.pdf', editPath]);
  }

  // ── Monthly Invoice from spreadsheet rows (Invoice-03) ───────────────────────
  //
  // Called from the spreadsheet page so edits to cells are reflected in the PDF.
  // Each map in [rows] must have keys: date, brickType, qty, unitPrice, total.
  // Rows with empty qty are skipped (they are padding rows from the spreadsheet).
  static Future<void> downloadMonthlyFromRows({
    required List<Map<String, String>> rows,
    required Client? client,
    required AppSettings settings,
    required String monthLabel,
  }) async {
    final sym = settings.currencySymbol.isNotEmpty
        ? settings.currencySymbol
        : '\$';

    final template    = await rootBundle.loadString('assets/monthly_invoice_template.html');
    final css         = await rootBundle.loadString('assets/monthly_invoice_styles.css');
    final logoB64     = await _tryB64('assets/invoice-image/logo.png');
    final abaB64      = await _tryB64('assets/invoice-image/ABA.png');
    final acledaB64   = await _tryB64('assets/invoice-image/Aceleda.png');
    final telegramB64 = await _tryB64('assets/invoice-image/telegram.jpg');

    // Build allRowHtml, skipping truly empty (padding) rows.
    final allRowHtml = <String>[];
    double netTotal = 0;
    for (final r in rows) {
      final qty = r['qty'] ?? '';
      if (qty.isEmpty) continue;
      final tot      = r['total'] ?? '';
      final up       = r['unitPrice'] ?? '';
      final totalVal = double.tryParse(tot.replaceAll(',', '')) ?? 0;
      netTotal += totalVal;
      final rowNum = allRowHtml.length + 1;
      allRowHtml.add('<tr>'
          '<td class="cell-no">$rowNum</td>'
          '<td class="cell-date">${_e(r['date'] ?? '')}</td>'
          '<td class="cell-desc">${_e(r['brickType'] ?? '')}</td>'
          '<td class="cell-qty">${_e(qty)}</td>'
          '<td class="cell-up">${up.isEmpty ? '' : '$sym${_e(up)}'}</td>'
          '<td class="cell-total cell-total-val">'
          '${tot.isEmpty ? '' : '$sym${_e(tot)}'}</td>'
          '</tr>');
    }

    final now       = DateTime.now();
    final day       = '${now.day}'.padLeft(2, '0');
    final month     = '${now.month}'.padLeft(2, '0');
    final year      = '${now.year}';
    final mm        = '${now.month}'.padLeft(2, '0');
    final invoiceNo = 'M-${now.year}$mm';

    final html = _buildMonthlyHtml(
      template:    template,
      css:         css,
      logoB64:     logoB64,
      abaB64:      abaB64,
      acledaB64:   acledaB64,
      telegramB64: telegramB64,
      phone1:      settings.invoicePhone1,
      phone2:      settings.invoicePhone2,
      clientName:  client?.name  ?? 'Various Clients',
      clientPhone: client?.phone ?? '',
      invoiceNo:   invoiceNo,
      day:         day,
      month:       month,
      year:        year,
      allRowHtml:  allRowHtml,
      netTotal:    netTotal,
      sym:         sym,
    );

    js.context.callMethod(
        'previewMonthlyInvoicePdf', [html, 'Monthly-$monthLabel.pdf']);
  }

  // ── Monthly Invoice (Invoice-03) ─────────────────────────────────────────────
  //
  // Generates a formal A4 monthly invoice listing multiple individual invoices
  // for a single client (or all clients) in one document. Supports multi-page:
  // every 10 rows a new .page div is added; row numbers continue across pages.
  static Future<void> downloadMonthly({
    required List<Invoice> invoices,
    required Client? client,
    required AppSettings settings,
    required List<BrickType> brickTypes,
    required String monthLabel,
  }) async {
    final sym = settings.currencySymbol.isNotEmpty
        ? settings.currencySymbol
        : '\$';

    // ── Load assets ───────────────────────────────────────────────────────────
    final template    = await rootBundle.loadString('assets/monthly_invoice_template.html');
    final css         = await rootBundle.loadString('assets/monthly_invoice_styles.css');
    final logoB64     = await _tryB64('assets/invoice-image/logo.png');
    final abaB64      = await _tryB64('assets/invoice-image/ABA.png');
    final acledaB64   = await _tryB64('assets/invoice-image/Aceleda.png');
    final telegramB64 = await _tryB64('assets/invoice-image/telegram.jpg');

    // ── Build brick-type lookup map ───────────────────────────────────────────
    final btMap   = { for (final bt in brickTypes) bt.id: bt };
    final dateFmt = DateFormat('dd/MM/yyyy');

    // ── Build allRowHtml ──────────────────────────────────────────────────────
    final allRowHtml = <String>[];
    for (final inv in invoices) {
      String dateStr = inv.date;
      try { dateStr = dateFmt.format(DateTime.parse(inv.date)); } catch (_) {}

      for (final item in inv.items) {
        final bt     = item.brickTypeId != null ? btMap[item.brickTypeId] : null;
        final desc   = _brickDesc(item, bt);
        final rowNum = allRowHtml.length + 1;
        allRowHtml.add('<tr>'
            '<td class="cell-no">$rowNum</td>'
            '<td class="cell-date">${_e(dateStr)}</td>'
            '<td class="cell-desc">${_e(desc)}</td>'
            '<td class="cell-qty">${_intFmt.format(item.quantity)}</td>'
            '<td class="cell-up">$sym${_fmt.format(item.unitPrice)}</td>'
            '<td class="cell-total cell-total-val">'
            '$sym${_fmt.format(item.total)}</td>'
            '</tr>');
      }
    }

    final netTotal = invoices.fold<double>(0, (s, inv) => s + inv.total);

    // ── Invoice reference number ──────────────────────────────────────────────
    String invoiceNo = 'M-$monthLabel';
    if (invoices.isNotEmpty) {
      try {
        final firstDate = DateTime.parse(invoices.first.date);
        final mm = '${firstDate.month}'.padLeft(2, '0');
        invoiceNo = 'M-${firstDate.year}$mm';
      } catch (_) {}
    }

    // ── Document date (today) ─────────────────────────────────────────────────
    final now   = DateTime.now();
    final day   = '${now.day}'.padLeft(2, '0');
    final month = '${now.month}'.padLeft(2, '0');
    final year  = '${now.year}';

    final html = _buildMonthlyHtml(
      template:    template,
      css:         css,
      logoB64:     logoB64,
      abaB64:      abaB64,
      acledaB64:   acledaB64,
      telegramB64: telegramB64,
      phone1:      settings.invoicePhone1,
      phone2:      settings.invoicePhone2,
      clientName:  client?.name  ?? 'Various Clients',
      clientPhone: client?.phone ?? '',
      invoiceNo:   invoiceNo,
      day:         day,
      month:       month,
      year:        year,
      allRowHtml:  allRowHtml,
      netTotal:    netTotal,
      sym:         sym,
    );

    // ── Show preview overlay ──────────────────────────────────────────────────
    js.context.callMethod(
        'previewMonthlyInvoicePdf', [html, 'Monthly-$monthLabel.pdf']);
  }

  // ── Shared multi-page builder ─────────────────────────────────────────────────
  //
  // Non-last pages hold 13 data rows (no tfoot, no bottom section).
  // Last page holds 10 data rows + tfoot + bottom section (ACLEDA, Signature,
  // Payment Date). Row numbers continue across pages (1–13, 14–26, …).
  static String _buildMonthlyHtml({
    required String template,
    required String css,
    required String? logoB64,
    required String? abaB64,
    required String? acledaB64,
    required String? telegramB64,
    required String phone1,
    required String phone2,
    required String clientName,
    required String clientPhone,
    required String invoiceNo,
    required String day,
    required String month,
    required String year,
    required List<String> allRowHtml,
    required double netTotal,
    required String sym,
  }) {
    const bodyOpen  = '<body>';
    const bodyClose = '</body>';
    final bodyIdx   = template.indexOf(bodyOpen);
    final bodyEnd   = template.lastIndexOf(bodyClose);

    // Head HTML (everything up to and including <body>), with {{STYLES}} filled.
    final headHtml = template
        .substring(0, bodyIdx + bodyOpen.length)
        .replaceAll('{{STYLES}}', css);

    // Page body template (the .page div) with all static tokens filled.
    final pageTpl = template
        .substring(bodyIdx + bodyOpen.length, bodyEnd)
        .trim()
        .replaceAll('{{LOGO_DATA_URI}}',
            logoB64 != null ? 'data:image/png;base64,$logoB64' : '')
        .replaceAll('{{TELEGRAM_QR}}',
            telegramB64 != null ? 'data:image/jpeg;base64,$telegramB64' : '')
        .replaceAll('{{ABA_QR}}',
            abaB64 != null ? 'data:image/png;base64,$abaB64' : '')
        .replaceAll('{{SELLER_PHONE1}}', _e(phone1))
        .replaceAll('{{SELLER_PHONE2}}', _e(phone2))
        .replaceAll('{{CLIENT_NAME}}',   _e(clientName))
        .replaceAll('{{CLIENT_PHONE}}',  _e(clientPhone))
        .replaceAll('{{INVOICE_NO}}',    _e(invoiceNo))
        .replaceAll('{{DAY}}',           day)
        .replaceAll('{{MONTH}}',         month)
        .replaceAll('{{YEAR}}',          year);

    const innerPageSize = 13; // non-last pages
    const lastPageSize  = 10; // last page (leaves room for tfoot)

    final n = allRowHtml.length;
    final int pageCount = (n <= lastPageSize)
        ? 1
        : (1 + ((n - lastPageSize + innerPageSize - 1) ~/ innerPageSize));

    final buf = StringBuffer(headHtml);

    for (int p = 0; p < pageCount; p++) {
      final bool isLast    = (p == pageCount - 1);
      final int  capacity  = isLast ? lastPageSize : innerPageSize;
      final int  start     = p * innerPageSize;
      final int  end       = (start + capacity).clamp(0, n);
      final pageRows = (start >= n)
          ? <String>[]
          : allRowHtml.sublist(start, end);

      // Real rows + empty padding rows to fill the page.
      final rowBuf = StringBuffer();
      for (final r in pageRows) {
        rowBuf.write(r);
      }
      for (int i = pageRows.length; i < capacity; i++) {
        final rowNum = start + i + 1;
        rowBuf.write('<tr>'
            '<td class="cell-no">$rowNum</td>'
            '<td class="cell-date"></td>'
            '<td class="cell-desc"></td>'
            '<td class="cell-qty"></td>'
            '<td class="cell-up"></td>'
            '<td class="cell-total"></td>'
            '</tr>');
      }

      final tfoot  = isLast ? _buildTfootHtml(sym, netTotal) : '<tfoot></tfoot>';
      final bottom = isLast ? _buildBottomHtml(acledaB64, abaB64) : '';

      buf.write(pageTpl
          .replaceAll('{{TABLE_ROWS}}',     rowBuf.toString())
          .replaceAll('{{TFOOT}}',          tfoot)
          .replaceAll('{{BOTTOM_SECTION}}', bottom));
    }

    buf.write('$bodyClose</html>');
    return buf.toString();
  }

  static String _buildBottomHtml(String? acledaB64, String? abaB64) {
    final acledaSrc = acledaB64 != null ? 'data:image/png;base64,$acledaB64' : '';
    final abaSrc    = abaB64    != null ? 'data:image/png;base64,$abaB64'    : '';
    return '<div class="acleda-block">'
        '<img src="$acledaSrc" alt="ACLEDA">'
        '<div class="qr-label">ACLEDA</div>'
        '</div>'
        '<div class="aba-block">'
        '<img src="$abaSrc" alt="ABA">'
        '<div class="qr-label">ABA</div>'
        '</div>'
        '<div class="signature-box">'
        '<div class="signature-title">ហត្ថលេខាទូទាត់/Signature:</div>'
        '<div class="signature-date">ថ្ងៃទី ខែ ឆ្នាំ 202</div>'
        '</div>'
        '<div class="payment-date-box">'
        '<div class="payment-date-title">កាលបរិច្ឆេតទូទាត់/Payment Date</div>'
        '<div class="payment-date-value">ថ្ងៃទី ខែ ឆ្នាំ 202</div>'
        '</div>';
  }

  static String _buildTfootHtml(String sym, double netTotal) {
    final s = '$sym${_fmt.format(netTotal)}';
    return '<tfoot>'
        '<tr>'
        '<td class="sum-empty" colspan="3"></td>'
        '<td class="sum-label" colspan="2">Net Total</td>'
        '<td class="sum-val">$s</td>'
        '</tr>'
        '<tr>'
        '<td class="sum-empty" colspan="3"></td>'
        '<td class="sum-label" colspan="2">Tax</td>'
        '<td class="sum-val">0%</td>'
        '</tr>'
        '<tr class="grand-total-row">'
        '<td class="sum-empty" colspan="3"></td>'
        '<td class="sum-label" colspan="2">Grand Total</td>'
        '<td class="sum-val">$s</td>'
        '</tr>'
        '</tfoot>';
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

  static String _e(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static Future<String?> _tryB64(String assetKey) async {
    try {
      return base64Encode(
          (await rootBundle.load(assetKey)).buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}

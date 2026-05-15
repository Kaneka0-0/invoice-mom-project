// Stub implementation of InvoiceHtmlService for non-web platforms (Android/iOS).
// These methods are never called on mobile — the app uses PdfService instead.

import '../models/models.dart';

class InvoiceHtmlService {
  static Future<void> download({
    required Invoice invoice,
    required Client? client,
    required AppSettings settings,
    String? editPath,
  }) async {
    throw UnsupportedError('InvoiceHtmlService is web-only');
  }

  static Future<void> downloadMonthlyFromRows({
    required List<Map<String, String>> rows,
    required Client? client,
    required AppSettings settings,
    required String monthLabel,
  }) async {
    throw UnsupportedError('InvoiceHtmlService is web-only');
  }

  static Future<void> downloadMonthly({
    required List<Invoice> invoices,
    required Client? client,
    required AppSettings settings,
    required List<BrickType> brickTypes,
    required String monthLabel,
  }) async {
    throw UnsupportedError('InvoiceHtmlService is web-only');
  }
}

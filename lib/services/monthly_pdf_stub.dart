import 'package:flutter/material.dart';
import '../models/models.dart';

Future<void> showMonthlyPdfPreview({
  required BuildContext context,
  required List<Invoice> invoices,
  required List<Client> allClients,
  required AppSettings settings,
  required String month,
  required List<BrickType> brickTypes,
}) async {
  throw UnsupportedError('Mobile-only — use InvoiceHtmlService on web');
}

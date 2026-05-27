import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'pdf_service.dart';

Future<void> showMonthlyPdfPreview({
  required BuildContext context,
  required List<Invoice> invoices,
  required List<Client> allClients,
  required AppSettings settings,
  required String month,
  required List<BrickType> brickTypes,
}) async {
  final bytes = await PdfService.generateMonthlyReport(
    invoices:   invoices,
    allClients: allClients,
    settings:   settings,
    month:      month,
    brickTypes: brickTypes,
  );
  if (context.mounted) {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}

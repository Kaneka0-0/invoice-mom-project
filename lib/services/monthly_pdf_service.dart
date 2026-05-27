// Conditional export: web gets the stub (never called due to kIsWeb guard);
// mobile/desktop gets the real implementation that uses PdfService + Printing.
export 'monthly_pdf_stub.dart'
    if (dart.library.io) 'monthly_pdf_native.dart';

// Conditional export: web uses the JS-bridge implementation;
// mobile/desktop uses the stub (PdfService handles native PDF there).
export 'invoice_html_service_web.dart'
    if (dart.library.io) 'invoice_html_service_stub.dart';

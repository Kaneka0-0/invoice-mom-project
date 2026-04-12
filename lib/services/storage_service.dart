import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persists all app data as JSON using SharedPreferences.
/// Works identically on mobile and web — no file-system access needed.
class StorageService {
  static const _key = 'panha_invoice_data';

  // ── Internal data bag ──────────────────────────────────────────────────────
  AppSettings settings = AppSettings();
  List<Client> clients = [];
  List<Worker> workers = [];
  List<Car> cars = [];
  List<Vendor> vendors = [];
  List<Borrow> borrows = [];
  List<Invoice> invoices = [];

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['settings'] != null) {
        settings = AppSettings.fromJson(data['settings'] as Map<String, dynamic>);
      }

      clients = _mapList(data['clients'], Client.fromJson);
      workers = _mapList(data['workers'], Worker.fromJson);
      cars = _mapList(data['cars'], Car.fromJson);
      vendors = _mapList(data['vendors'], Vendor.fromJson);
      borrows = _mapList(data['borrows'], Borrow.fromJson);
      invoices = _mapList(data['invoices'], Invoice.fromJson);
    } catch (_) {
      // Corrupt data — start fresh.
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'settings': settings.toJson(),
      'clients': clients.map((e) => e.toJson()).toList(),
      'workers': workers.map((e) => e.toJson()).toList(),
      'cars': cars.map((e) => e.toJson()).toList(),
      'vendors': vendors.map((e) => e.toJson()).toList(),
      'borrows': borrows.map((e) => e.toJson()).toList(),
      'invoices': invoices.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  // ── Invoice number ────────────────────────────────────────────────────────
  String nextInvoiceNumber() {
    final year = DateTime.now().year;
    final num = settings.nextInvoiceNum;
    settings.nextInvoiceNum = num + 1;
    return 'INV-$year-${num.toString().padLeft(4, '0')}';
  }

  // ── Lookup helpers ────────────────────────────────────────────────────────
  Client? findClient(String? id) =>
      id == null ? null : clients.firstWhere((c) => c.id == id, orElse: () => clients.first);

  Worker? findWorker(String? id) =>
      id == null ? null : workers.where((w) => w.id == id).firstOrNull;

  Car? findCar(String? id) =>
      id == null ? null : cars.where((c) => c.id == id).firstOrNull;

  Vendor? findVendor(String? id) =>
      id == null ? null : vendors.where((v) => v.id == id).firstOrNull;

  Borrow? findBorrow(String? id) =>
      id == null ? null : borrows.where((b) => b.id == id).firstOrNull;

  Invoice? findInvoice(String? id) =>
      id == null ? null : invoices.where((i) => i.id == id).firstOrNull;

  // ── Monthly filter ────────────────────────────────────────────────────────
  List<Invoice> invoicesForMonth(String yearMonth) =>
      invoices.where((i) => i.date.startsWith(yearMonth)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  // ── Borrow totals ─────────────────────────────────────────────────────────
  double totalOwedToVendors() => borrows
      .where((b) => b.status == BorrowStatus.owed)
      .fold(0, (sum, b) => sum + b.totalAmount);

  double totalOwedToVendor(String vendorId) => borrows
      .where((b) => b.vendorId == vendorId && b.status == BorrowStatus.owed)
      .fold(0, (sum, b) => sum + b.totalAmount);

  int totalBricksOwedToVendor(String vendorId) => borrows
      .where((b) => b.vendorId == vendorId && b.status == BorrowStatus.owed)
      .fold(0, (sum, b) => sum + b.quantity);

  // ── Revenue stats ─────────────────────────────────────────────────────────
  double totalRevenue() =>
      invoices.fold(0, (sum, i) => sum + i.total);

  double pendingAmount() => invoices
      .where((i) => i.status == InvoiceStatus.pending)
      .fold(0, (sum, i) => sum + i.total);

  double monthlyRevenue(String yearMonth) => invoicesForMonth(yearMonth)
      .fold(0, (sum, i) => sum + i.total);

  // ── Private ───────────────────────────────────────────────────────────────
  List<T> _mapList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

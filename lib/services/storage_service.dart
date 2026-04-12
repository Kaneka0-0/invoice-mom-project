import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persists all app data as JSON using SharedPreferences.
class StorageService {
  static const _key = 'panha_invoice_data_v2';

  AppSettings settings = AppSettings();
  List<Client> clients = [];
  List<Worker> workers = [];
  List<Car> cars = [];
  List<Vendor> vendors = [];
  List<BrickType> brickTypes = [];
  List<Inventory> inventory = [];
  List<BorrowTransaction> borrows = [];
  List<Invoice> invoices = [];
  List<Delivery> deliveries = [];
  List<WorkerTransaction> workerTransactions = [];

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

      clients            = _mapList(data['clients'],             Client.fromJson);
      workers            = _mapList(data['workers'],             Worker.fromJson);
      cars               = _mapList(data['cars'],                Car.fromJson);
      vendors            = _mapList(data['vendors'],             Vendor.fromJson);
      brickTypes         = _mapList(data['brick_types'],         BrickType.fromJson);
      inventory          = _mapList(data['inventory'],           Inventory.fromJson);
      borrows            = _mapList(data['borrows'],             BorrowTransaction.fromJson);
      invoices           = _mapList(data['invoices'],            Invoice.fromJson);
      deliveries         = _mapList(data['deliveries'],          Delivery.fromJson);
      workerTransactions = _mapList(data['worker_transactions'], WorkerTransaction.fromJson);
    } catch (_) {
      // Corrupt data — start fresh.
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'settings':            settings.toJson(),
      'clients':             clients.map((e) => e.toJson()).toList(),
      'workers':             workers.map((e) => e.toJson()).toList(),
      'cars':                cars.map((e) => e.toJson()).toList(),
      'vendors':             vendors.map((e) => e.toJson()).toList(),
      'brick_types':         brickTypes.map((e) => e.toJson()).toList(),
      'inventory':           inventory.map((e) => e.toJson()).toList(),
      'borrows':             borrows.map((e) => e.toJson()).toList(),
      'invoices':            invoices.map((e) => e.toJson()).toList(),
      'deliveries':          deliveries.map((e) => e.toJson()).toList(),
      'worker_transactions': workerTransactions.map((e) => e.toJson()).toList(),
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
  Client?           findClient(String? id)      => id == null ? null : clients.where((c) => c.id == id).firstOrNull;
  Worker?           findWorker(String? id)      => id == null ? null : workers.where((w) => w.id == id).firstOrNull;
  Car?              findCar(String? id)         => id == null ? null : cars.where((c) => c.id == id).firstOrNull;
  Vendor?           findVendor(String? id)      => id == null ? null : vendors.where((v) => v.id == id).firstOrNull;
  BrickType?        findBrickType(String? id)   => id == null ? null : brickTypes.where((b) => b.id == id).firstOrNull;
  Inventory?        findInventory(String? btId) => btId == null ? null : inventory.where((i) => i.brickTypeId == btId).firstOrNull;
  Invoice?          findInvoice(String? id)     => id == null ? null : invoices.where((i) => i.id == id).firstOrNull;
  Delivery?         findDelivery(String? id)    => id == null ? null : deliveries.where((d) => d.id == id).firstOrNull;

  // ── Monthly filter ────────────────────────────────────────────────────────
  List<Invoice> invoicesForMonth(String yearMonth) =>
      invoices.where((i) => i.date.startsWith(yearMonth)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  // ── Vendor borrow balance ─────────────────────────────────────────────────
  /// Net amount we owe to all vendors (borrow_in - borrow_out).
  double totalOwedToVendors() {
    double total = 0;
    for (final b in borrows) {
      if (b.type == BorrowType.borrowIn)  total += b.total;
      if (b.type == BorrowType.borrowOut) total -= b.total;
    }
    return total.clamp(0.0, double.infinity);
  }

  /// Net amount we owe to a specific vendor.
  double totalOwedToVendor(String vendorId) {
    double total = 0;
    for (final b in borrows.where((b) => b.vendorId == vendorId)) {
      if (b.type == BorrowType.borrowIn)  total += b.total;
      if (b.type == BorrowType.borrowOut) total -= b.total;
    }
    return total.clamp(0.0, double.infinity);
  }

  int totalBricksOwedToVendor(String vendorId) {
    int total = 0;
    for (final b in borrows.where((b) => b.vendorId == vendorId)) {
      if (b.type == BorrowType.borrowIn)  total += b.quantity;
      if (b.type == BorrowType.borrowOut) total -= b.quantity;
    }
    return total.clamp(0, 9999999);
  }

  /// Net amount a vendor owes us (lend_out - lend_return).
  double totalVendorOwesUs(String vendorId) {
    double total = 0;
    for (final b in borrows.where((b) => b.vendorId == vendorId)) {
      if (b.type == BorrowType.lendOut)    total += b.total;
      if (b.type == BorrowType.lendReturn) total -= b.total;
    }
    return total.clamp(0.0, double.infinity);
  }

  int totalBricksVendorOwesUs(String vendorId) {
    int total = 0;
    for (final b in borrows.where((b) => b.vendorId == vendorId)) {
      if (b.type == BorrowType.lendOut)    total += b.quantity;
      if (b.type == BorrowType.lendReturn) total -= b.quantity;
    }
    return total.clamp(0, 9999999);
  }

  // ── Revenue & payment stats ───────────────────────────────────────────────
  double totalRevenue() => invoices.fold(0, (s, i) => s + i.total);

  double pendingAmount() => invoices
      .where((i) => i.paymentStatus == PaymentStatus.unpaid)
      .fold(0, (s, i) => s + i.total);

  double monthlyRevenue(String yearMonth) =>
      invoicesForMonth(yearMonth).fold(0, (s, i) => s + i.total);

  // ── Delivery assignment tracking ─────────────────────────────────────────
  /// Total bricks assigned across non-cancelled deliveries for an invoice.
  /// Pass [excludeDeliveryId] when editing a delivery to avoid counting itself.
  int invoiceAssignedQty(String invoiceId, {String? excludeDeliveryId}) {
    int total = 0;
    for (final d in deliveries) {
      if (d.id == excludeDeliveryId) continue;
      if (d.status == DeliveryStatus.cancelled) continue;
      for (final item in d.items) {
        if (item.invoiceId == invoiceId) total += item.quantity;
      }
    }
    return total;
  }

  /// Bricks remaining to assign for an invoice (ordered - assigned).
  int invoiceRemainingQty(String invoiceId, {String? excludeDeliveryId}) {
    final inv = findInvoice(invoiceId);
    if (inv == null) return 0;
    final assigned = invoiceAssignedQty(invoiceId, excludeDeliveryId: excludeDeliveryId);
    return (inv.totalBricks - assigned).clamp(0, inv.totalBricks);
  }

  /// Total bricks actually delivered (from deliveries with status=delivered).
  int invoiceDeliveredQty(String invoiceId) {
    int total = 0;
    for (final d in deliveries) {
      if (d.status != DeliveryStatus.delivered) continue;
      for (final item in d.items) {
        if (item.invoiceId == invoiceId) total += item.quantity;
      }
    }
    return total;
  }

  // ── Worker finance ────────────────────────────────────────────────────────
  double workerBalance(String workerId) {
    double balance = 0;
    for (final t in workerTransactions.where((t) => t.workerId == workerId)) {
      switch (t.type) {
        case WorkerTransactionType.salary:
          balance += t.amount;
        case WorkerTransactionType.borrow:
          balance -= t.amount;
        case WorkerTransactionType.repayment:
          balance += t.amount;
      }
    }
    return balance;
  }

  // ── Private ───────────────────────────────────────────────────────────────
  List<T> _mapList<T>(dynamic list, T Function(Map<String, dynamic>) fromJson) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

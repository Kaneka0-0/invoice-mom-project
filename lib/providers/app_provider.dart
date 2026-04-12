import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../l10n/strings.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _store = StorageService();
  final _uuid = const Uuid();
  bool _isKh = false;
  bool _loading = true;
  bool _syncing = false;
  RealtimeChannel? _realtimeChannel;

  // ── Public getters ────────────────────────────────────────────────────────
  bool get isKh     => _isKh;
  bool get loading  => _loading;
  bool get syncing  => _syncing;
  S    get s        => S(_isKh);
  StorageService get store => _store;

  AppSettings          get settings           => _store.settings;
  List<Client>         get clients            => List.unmodifiable(_store.clients);
  List<Worker>         get workers            => List.unmodifiable(_store.workers);
  List<Car>            get cars               => List.unmodifiable(_store.cars);
  List<Vendor>         get vendors            => List.unmodifiable(_store.vendors);
  List<BrickType>      get brickTypes         => List.unmodifiable(_store.brickTypes);
  List<Inventory>      get inventory          => List.unmodifiable(_store.inventory);
  List<BorrowTransaction> get borrows         => List.unmodifiable(_store.borrows);
  List<Invoice>        get invoices           => List.unmodifiable(
        _store.invoices..sort((a, b) => b.date.compareTo(a.date)));
  List<Delivery>       get deliveries         => List.unmodifiable(_store.deliveries);
  List<WorkerTransaction> get workerTransactions =>
      List.unmodifiable(_store.workerTransactions);

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _store.load();
    _loading = false;
    notifyListeners();
    await _syncFromSupabase();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseSync.subscribeToAll(() => _syncFromSupabase());
  }

  Future<void> reload() => _syncFromSupabase();

  // ── Supabase sync ─────────────────────────────────────────────────────────
  Future<void> _syncFromSupabase() async {
    if (_syncing) return;
    _syncing = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SupabaseSync.fetchClients(),
        SupabaseSync.fetchWorkers(),
        SupabaseSync.fetchCars(),
        SupabaseSync.fetchVendors(),
        SupabaseSync.fetchBrickTypes(),
        SupabaseSync.fetchInventory(),
        SupabaseSync.fetchBorrows(),
        SupabaseSync.fetchInvoices(),
        SupabaseSync.fetchDeliveries(),
        SupabaseSync.fetchWorkerTransactions(),
        SupabaseSync.fetchSettings(),
      ]);

      _store.clients            = results[0] as List<Client>;
      _store.workers            = results[1] as List<Worker>;
      _store.cars               = results[2] as List<Car>;
      _store.vendors            = results[3] as List<Vendor>;
      _store.brickTypes         = results[4] as List<BrickType>;
      _store.inventory          = results[5] as List<Inventory>;
      _store.borrows            = results[6] as List<BorrowTransaction>;
      _store.invoices           = results[7] as List<Invoice>;
      _store.deliveries         = results[8] as List<Delivery>;
      _store.workerTransactions = results[9] as List<WorkerTransaction>;

      final remoteSettings = results[10] as AppSettings?;
      if (remoteSettings != null) _store.settings = remoteSettings;

      await _store.save();
    } catch (_) {
      // offline — keep local data
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  // ── Language ──────────────────────────────────────────────────────────────
  void toggleLanguage() {
    _isKh = !_isKh;
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Future<void> saveSettings(AppSettings updated) async {
    _store.settings
      ..companyName      = updated.companyName
      ..address          = updated.address
      ..phone            = updated.phone
      ..email            = updated.email
      ..brickPriceDefault = updated.brickPriceDefault
      ..carCapacity      = updated.carCapacity
      ..currency         = updated.currency
      ..currencySymbol   = updated.currencySymbol;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertSettings(_store.settings).catchError((_) {});
  }

  // ── Clients ───────────────────────────────────────────────────────────────
  Future<Client> addClient({
    required String name,
    String address = '',
    String phone = '',
    String notes = '',
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
  }) async {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      address: address,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
      latitude: latitude,
      longitude: longitude,
      googleMapsUrl: googleMapsUrl,
    );
    _store.clients.add(client);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertClient(client).catchError((_) {});
    return client;
  }

  Future<void> updateClient(Client client) async {
    final idx = _store.clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) _store.clients[idx] = client;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertClient(client).catchError((_) {});
  }

  Future<void> deleteClient(String id) async {
    _store.clients.removeWhere((c) => c.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteClient(id).catchError((_) {});
  }

  // ── Workers ───────────────────────────────────────────────────────────────
  Future<Worker> addWorker({
    required String name,
    String phone = '',
    WorkerRole role = WorkerRole.loader,
    String notes = '',
  }) async {
    final worker = Worker(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      role: role,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.workers.add(worker);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertWorker(worker).catchError((_) {});
    return worker;
  }

  Future<void> updateWorker(Worker worker) async {
    final idx = _store.workers.indexWhere((w) => w.id == worker.id);
    if (idx >= 0) _store.workers[idx] = worker;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertWorker(worker).catchError((_) {});
  }

  Future<void> deleteWorker(String id) async {
    _store.workers.removeWhere((w) => w.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteWorker(id).catchError((_) {});
  }

  // ── Cars ──────────────────────────────────────────────────────────────────
  Future<Car> addCar({
    required String plateNumber,
    int capacity = 30000,
    String description = '',
  }) async {
    final car = Car(
      id: _uuid.v4(),
      plateNumber: plateNumber,
      capacity: capacity,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.cars.add(car);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertCar(car).catchError((_) {});
    return car;
  }

  Future<void> updateCar(Car car) async {
    final idx = _store.cars.indexWhere((c) => c.id == car.id);
    if (idx >= 0) _store.cars[idx] = car;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertCar(car).catchError((_) {});
  }

  Future<void> deleteCar(String id) async {
    _store.cars.removeWhere((c) => c.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteCar(id).catchError((_) {});
  }

  // ── Vendors ───────────────────────────────────────────────────────────────
  Future<Vendor> addVendor({
    required String name,
    String address = '',
    String phone = '',
    String notes = '',
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
  }) async {
    final vendor = Vendor(
      id: _uuid.v4(),
      name: name,
      address: address,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
      latitude: latitude,
      longitude: longitude,
      googleMapsUrl: googleMapsUrl,
    );
    _store.vendors.add(vendor);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertVendor(vendor).catchError((_) {});
    return vendor;
  }

  Future<void> updateVendor(Vendor vendor) async {
    final idx = _store.vendors.indexWhere((v) => v.id == vendor.id);
    if (idx >= 0) _store.vendors[idx] = vendor;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertVendor(vendor).catchError((_) {});
  }

  Future<void> deleteVendor(String id) async {
    _store.vendors.removeWhere((v) => v.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteVendor(id).catchError((_) {});
  }

  // ── Brick Types ───────────────────────────────────────────────────────────
  Future<BrickType> addBrickType({
    required String name,
    String description = '',
  }) async {
    final bt = BrickType(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.brickTypes.add(bt);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertBrickType(bt).catchError((_) {});
    return bt;
  }

  Future<void> updateBrickType(BrickType bt) async {
    final idx = _store.brickTypes.indexWhere((b) => b.id == bt.id);
    if (idx >= 0) _store.brickTypes[idx] = bt;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertBrickType(bt).catchError((_) {});
  }

  Future<void> deleteBrickType(String id) async {
    _store.brickTypes.removeWhere((b) => b.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteBrickType(id).catchError((_) {});
  }

  // ── Borrows (ledger — insert only, no updates) ────────────────────────────
  Future<BorrowTransaction> addBorrow({
    required String vendorId,
    String? brickTypeId,
    required int quantity,
    double unitPrice = 0,
    BorrowType type = BorrowType.borrowIn,
    String? relatedInvoiceId,
  }) async {
    final borrow = BorrowTransaction(
      id: _uuid.v4(),
      vendorId: vendorId,
      brickTypeId: brickTypeId,
      quantity: quantity,
      unitPrice: unitPrice,
      total: quantity * unitPrice,
      type: type,
      relatedInvoiceId: relatedInvoiceId,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.borrows.add(borrow);
    await _store.save();
    notifyListeners();
    SupabaseSync.insertBorrow(borrow).catchError((_) {});
    return borrow;
  }

  Future<void> deleteBorrow(String id) async {
    _store.borrows.removeWhere((b) => b.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteBorrow(id).catchError((_) {});
  }

  // ── Invoices ──────────────────────────────────────────────────────────────
  Future<Invoice> addInvoice({
    required String date,
    String? clientId,
    List<InvoiceItem>? items,
    String notes = '',
    InvoiceStatus status = InvoiceStatus.draft,
  }) async {
    final id = _uuid.v4();
    final invoice = Invoice(
      id: id,
      number: _store.nextInvoiceNumber(),
      clientId: clientId,
      date: date,
      notes: notes,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
      items: items?.map((item) {
        item.invoiceId = id;
        if (item.id.isEmpty) item.id = _uuid.v4();
        return item;
      }).toList() ?? [],
    );
    invoice.recalculate();
    _store.invoices.add(invoice);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(invoice).catchError((_) {});
    return invoice;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    // Ensure all items have ids and invoiceId set
    for (final item in invoice.items) {
      if (item.id.isEmpty) item.id = _uuid.v4();
      item.invoiceId = invoice.id;
    }
    invoice.recalculate();
    final idx = _store.invoices.indexWhere((i) => i.id == invoice.id);
    if (idx >= 0) _store.invoices[idx] = invoice;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(invoice).catchError((_) {});
  }

  Future<void> deleteInvoice(String id) async {
    _store.invoices.removeWhere((i) => i.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteInvoice(id).catchError((_) {});
  }

  Future<void> markInvoicePaid(String id) async {
    final inv = _store.invoices.firstWhere((i) => i.id == id);
    inv.paymentStatus = PaymentStatus.paid;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(inv).catchError((_) {});
  }

  // ── Deliveries ────────────────────────────────────────────────────────────
  Future<Delivery> addDelivery({
    required String carId,
    String? driverId,
    String? deliveryDate,
    String notes = '',
    List<DeliveryItem>? items,
  }) async {
    final id = _uuid.v4();
    final delivery = Delivery(
      id: id,
      carId: carId,
      driverId: driverId,
      deliveryDate: deliveryDate,
      notes: notes,
      items: items?.map((item) {
        item.deliveryId = id;
        return item;
      }).toList() ?? [],
    );
    _store.deliveries.add(delivery);
    _syncInvoiceStatuses(delivery);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertDelivery(delivery).catchError((_) {});
    return delivery;
  }

  Future<void> updateDelivery(Delivery delivery) async {
    for (final item in delivery.items) {
      item.deliveryId = delivery.id;
    }
    final idx = _store.deliveries.indexWhere((d) => d.id == delivery.id);
    if (idx >= 0) _store.deliveries[idx] = delivery;
    _syncInvoiceStatuses(delivery);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertDelivery(delivery).catchError((_) {});
  }

  Future<void> deleteDelivery(String id) async {
    _store.deliveries.removeWhere((d) => d.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteDelivery(id).catchError((_) {});
  }

  Future<void> updateDeliveryStatus(String id, DeliveryStatus status) async {
    final delivery = _store.deliveries.firstWhere((d) => d.id == id);
    delivery.status = status;
    if (status == DeliveryStatus.loading || status == DeliveryStatus.onRoute) {
      delivery.startedAt = DateTime.now().toIso8601String();
    }
    if (status == DeliveryStatus.delivered) {
      delivery.completedAt = DateTime.now().toIso8601String();
    }
    _syncInvoiceStatuses(delivery);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertDelivery(delivery).catchError((_) {});
  }

  /// Auto-update invoice delivery statuses after a delivery changes.
  void _syncInvoiceStatuses(Delivery delivery) {
    for (final item in delivery.items) {
      final inv = _store.findInvoice(item.invoiceId);
      if (inv == null) continue;

      if (delivery.status == DeliveryStatus.cancelled) {
        // Recalculate: might have gone back to draft or confirmed
        final delivered = _store.invoiceDeliveredQty(inv.id);
        final assigned  = _store.invoiceAssignedQty(inv.id);
        if (delivered >= inv.totalBricks) {
          inv.status = InvoiceStatus.delivered;
        } else if (delivered > 0) {
          inv.status = InvoiceStatus.partiallyDelivered;
        } else if (assigned > 0) {
          inv.status = InvoiceStatus.confirmed;
        } else {
          inv.status = InvoiceStatus.draft;
        }
      } else if (delivery.status == DeliveryStatus.delivered) {
        final delivered = _store.invoiceDeliveredQty(inv.id);
        if (delivered >= inv.totalBricks) {
          inv.status = InvoiceStatus.delivered;
        } else if (delivered > 0) {
          inv.status = InvoiceStatus.partiallyDelivered;
        }
      } else {
        // planned / loading / on_route — move draft → confirmed
        if (inv.status == InvoiceStatus.draft) {
          inv.status = InvoiceStatus.confirmed;
        }
      }
      SupabaseSync.upsertInvoice(inv).catchError((_) {});
    }
  }

  // ── Worker Transactions ───────────────────────────────────────────────────
  Future<WorkerTransaction> addWorkerTransaction({
    required String workerId,
    required WorkerTransactionType type,
    required double amount,
    String notes = '',
  }) async {
    final t = WorkerTransaction(
      id: _uuid.v4(),
      workerId: workerId,
      type: type,
      amount: amount,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.workerTransactions.add(t);
    await _store.save();
    notifyListeners();
    SupabaseSync.insertWorkerTransaction(t).catchError((_) {});
    return t;
  }

  Future<void> deleteWorkerTransaction(String id) async {
    _store.workerTransactions.removeWhere((t) => t.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteWorkerTransaction(id).catchError((_) {});
  }
}

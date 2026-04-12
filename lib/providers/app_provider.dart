import 'package:flutter/material.dart';
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

  // ── Public getters ────────────────────────────────────────────────────────
  bool get isKh => _isKh;
  bool get loading => _loading;
  S get s => S(_isKh);
  StorageService get store => _store;

  AppSettings get settings => _store.settings;
  List<Client> get clients => List.unmodifiable(_store.clients);
  List<Worker> get workers => List.unmodifiable(_store.workers);
  List<Car> get cars => List.unmodifiable(_store.cars);
  List<Vendor> get vendors => List.unmodifiable(_store.vendors);
  List<Borrow> get borrows => List.unmodifiable(_store.borrows);
  List<Invoice> get invoices => List.unmodifiable(
        _store.invoices..sort((a, b) => b.date.compareTo(a.date)),
      );

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _store.load();
    _loading = false;
    notifyListeners();
    _syncFromSupabase();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final clients   = await SupabaseSync.fetchClients();
      final workers   = await SupabaseSync.fetchWorkers();
      final cars      = await SupabaseSync.fetchCars();
      final vendors   = await SupabaseSync.fetchVendors();
      final borrows   = await SupabaseSync.fetchBorrows();
      final invoices  = await SupabaseSync.fetchInvoices();
      bool changed = false;
      if (clients.isNotEmpty) { _store.clients..clear()..addAll(clients); changed = true; }
      if (workers.isNotEmpty) { _store.workers..clear()..addAll(workers); changed = true; }
      if (cars.isNotEmpty)    { _store.cars..clear()..addAll(cars);       changed = true; }
      if (vendors.isNotEmpty) { _store.vendors..clear()..addAll(vendors); changed = true; }
      if (borrows.isNotEmpty) { _store.borrows..clear()..addAll(borrows); changed = true; }
      if (invoices.isNotEmpty){ _store.invoices..clear()..addAll(invoices); changed = true; }
      if (changed) {
        await _store.save();
        notifyListeners();
      }
    } catch (_) {
      // offline — silently ignore
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
      ..companyName = updated.companyName
      ..companyNameKh = updated.companyNameKh
      ..address = updated.address
      ..addressKh = updated.addressKh
      ..phone = updated.phone
      ..email = updated.email
      ..brickPriceDefault = updated.brickPriceDefault
      ..carCapacity = updated.carCapacity
      ..currency = updated.currency
      ..currencySymbol = updated.currencySymbol;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertSettings(updated).catchError((_) {});
  }

  // ── Clients ───────────────────────────────────────────────────────────────
  Future<Client> addClient({
    required String name,
    String nameKh = '',
    String address = '',
    String addressKh = '',
    String phone = '',
    String notes = '',
  }) async {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      nameKh: nameKh,
      address: address,
      addressKh: addressKh,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
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
    String nameKh = '',
    String phone = '',
    WorkerRole role = WorkerRole.loader,
    String idCard = '',
    String notes = '',
  }) async {
    final worker = Worker(
      id: _uuid.v4(),
      name: name,
      nameKh: nameKh,
      phone: phone,
      role: role,
      idCard: idCard,
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
    String notes = '',
  }) async {
    final car = Car(
      id: _uuid.v4(),
      plateNumber: plateNumber,
      capacity: capacity,
      description: description,
      notes: notes,
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
    String nameKh = '',
    String address = '',
    String phone = '',
    String notes = '',
  }) async {
    final vendor = Vendor(
      id: _uuid.v4(),
      name: name,
      nameKh: nameKh,
      address: address,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
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

  // ── Borrows ───────────────────────────────────────────────────────────────
  Future<Borrow> addBorrow({
    required String vendorId,
    String? invoiceId,
    required String date,
    required int quantity,
    required double unitPrice,
    String notes = '',
  }) async {
    final borrow = Borrow(
      id: _uuid.v4(),
      vendorId: vendorId,
      invoiceId: invoiceId,
      date: date,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: quantity * unitPrice,
      status: BorrowStatus.owed,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.borrows.add(borrow);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertBorrow(borrow).catchError((_) {});
    return borrow;
  }

  Future<void> markBorrowPaid(String id) async {
    final borrow = _store.borrows.firstWhere((b) => b.id == id);
    borrow.status = BorrowStatus.paid;
    borrow.paymentDate = DateTime.now().toIso8601String().substring(0, 10);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertBorrow(borrow).catchError((_) {});
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
    String? carId,
    List<String> workerIds = const [],
    List<InvoiceItem> items = const [],
    String? borrowId,
    String notes = '',
    InvoiceStatus status = InvoiceStatus.draft,
  }) async {
    final invoice = Invoice(
      id: _uuid.v4(),
      number: _store.nextInvoiceNumber(),
      date: date,
      clientId: clientId,
      carId: carId,
      workerIds: workerIds,
      items: items,
      borrowId: borrowId,
      notes: notes,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
    );
    invoice.recalculate();
    _store.invoices.add(invoice);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(invoice).catchError((_) {});
    return invoice;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    invoice.recalculate();
    invoice.updatedAt = DateTime.now().toIso8601String();
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
    inv.status = InvoiceStatus.paid;
    inv.updatedAt = DateTime.now().toIso8601String();
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(inv).catchError((_) {});
  }
}

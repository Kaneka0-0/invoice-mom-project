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
  List<Invoice>        get invoices           => List.unmodifiable(
        _store.invoices..sort((a, b) => b.date.compareTo(a.date)));

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
        SupabaseSync.fetchClientLocations(),
        SupabaseSync.fetchInvoices(),
        SupabaseSync.fetchSettings(),
      ]);

      _store.clients         = results[0] as List<Client>;
      _store.clientLocations = results[1] as List<ClientLocation>;
      _store.invoices        = results[2] as List<Invoice>;

      final remoteSettings = results[3] as AppSettings?;
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
      ..companyName       = updated.companyName
      ..address           = updated.address
      ..phone             = updated.phone
      ..email             = updated.email
      ..brickPriceDefault = updated.brickPriceDefault
      ..carCapacity       = updated.carCapacity
      ..currency          = updated.currency
      ..currencySymbol    = updated.currencySymbol
      ..invoicePhone1     = updated.invoicePhone1
      ..invoicePhone2     = updated.invoicePhone2;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertSettings(_store.settings).catchError((_) {});
  }

  // ── Client Locations ──────────────────────────────────────────────────────
  List<ClientLocation> locationsForClient(String clientId) =>
      _store.locationsForClient(clientId);

  Future<ClientLocation> addClientLocation({
    required String clientId,
    required String name,
    String address = '',
  }) async {
    final loc = ClientLocation(
      id: _uuid.v4(),
      clientId: clientId,
      name: name,
      address: address,
      createdAt: DateTime.now().toIso8601String(),
    );
    _store.clientLocations.add(loc);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertClientLocation(loc).catchError((_) {});
    return loc;
  }

  Future<void> deleteClientLocation(String id) async {
    _store.clientLocations.removeWhere((l) => l.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteClientLocation(id).catchError((_) {});
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
    final backup = _store.clients.firstWhere((c) => c.id == id,
        orElse: () => throw StateError('not found'));
    _store.clients.removeWhere((c) => c.id == id);
    await _store.save();
    notifyListeners();
    try {
      await SupabaseSync.deleteClient(id);
    } catch (_) {
      // Roll back if Supabase delete failed
      _store.clients.add(backup);
      await _store.save();
      notifyListeners();
      rethrow;
    }
  }

  // ── Invoices ──────────────────────────────────────────────────────────────
  Future<Invoice> addInvoice({
    required String date,
    String? number,
    String? clientId,
    String? deliveryLocation,
    List<InvoiceItem>? items,
    String notes = '',
    double deposit = 0,
    InvoiceStatus status = InvoiceStatus.draft,
  }) async {
    final id = _uuid.v4();
    final invoice = Invoice(
      id: id,
      number: (number != null && number.isNotEmpty)
          ? number
          : _store.nextInvoiceNumber(DateTime.tryParse(date) ?? DateTime.now()),
      clientId: clientId,
      deliveryLocation: deliveryLocation,
      date: date,
      notes: notes,
      deposit: deposit,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
      items: items?.map((item) {
        item.invoiceId = id;
        if (item.id.isEmpty) item.id = _uuid.v4();
        return item;
      }).toList() ?? [],
    );
    invoice.recalculate();
    // Remove any local duplicate with the same number (from a previous failed save).
    _store.invoices.removeWhere(
        (i) => i.number == invoice.number && i.id != invoice.id);
    _store.invoices.add(invoice);
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(invoice).catchError((e) => debugPrint('upsertInvoice error: $e'));
    // Push updated nextInvoiceNum so it survives page refreshes / re-syncs.
    SupabaseSync.upsertSettings(_store.settings).catchError((_) {});
    return invoice;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    for (final item in invoice.items) {
      if (item.id.isEmpty) item.id = _uuid.v4();
      item.invoiceId = invoice.id;
    }
    invoice.recalculate();
    final idx = _store.invoices.indexWhere((i) => i.id == invoice.id);
    if (idx >= 0) _store.invoices[idx] = invoice;
    await _store.save();
    notifyListeners();
    SupabaseSync.upsertInvoice(invoice).catchError((e) => debugPrint('upsertInvoice error: $e'));
  }

  Future<void> deleteInvoice(String id) async {
    _store.invoices.removeWhere((i) => i.id == id);
    await _store.save();
    notifyListeners();
    SupabaseSync.deleteInvoice(id).catchError((e) => debugPrint('deleteInvoice error: $e'));
  }

}

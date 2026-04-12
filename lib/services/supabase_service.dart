import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

const _supabaseUrl = 'https://umuwraheuputhjtmdomy.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtdXdyYWhldXB1dGhqdG1kb215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MDU2NTEsImV4cCI6MjA5MTQ4MTY1MX0.TwIRK4fKP0TzQKNQyo9nS4O9h6iQSQSjERPXRpGDGpQ';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
}

SupabaseClient get _db => Supabase.instance.client;

class SupabaseSync {
  // ── Clients ──────────────────────────────────────────────────────────────
  static Future<List<Client>> fetchClients() async {
    final rows = await _db.from('clients').select().order('created_at');
    return rows.map((r) => Client.fromJson(r)).toList();
  }
  static Future<void> upsertClient(Client c) async =>
      _db.from('clients').upsert(c.toJson());
  static Future<void> deleteClient(String id) async =>
      _db.from('clients').delete().eq('id', id);

  // ── Workers ──────────────────────────────────────────────────────────────
  static Future<List<Worker>> fetchWorkers() async {
    final rows = await _db.from('workers').select().order('created_at');
    return rows.map((r) => Worker.fromJson(r)).toList();
  }
  static Future<void> upsertWorker(Worker w) async =>
      _db.from('workers').upsert(w.toJson());
  static Future<void> deleteWorker(String id) async =>
      _db.from('workers').delete().eq('id', id);

  // ── Cars ─────────────────────────────────────────────────────────────────
  static Future<List<Car>> fetchCars() async {
    final rows = await _db.from('cars').select().order('created_at');
    return rows.map((r) => Car.fromJson(r)).toList();
  }
  static Future<void> upsertCar(Car c) async =>
      _db.from('cars').upsert(c.toJson()..remove('created_at'));
  static Future<void> deleteCar(String id) async =>
      _db.from('cars').delete().eq('id', id);

  // ── Vendors ──────────────────────────────────────────────────────────────
  static Future<List<Vendor>> fetchVendors() async {
    final rows = await _db.from('vendors').select().order('created_at');
    return rows.map((r) => Vendor.fromJson(r)).toList();
  }
  static Future<void> upsertVendor(Vendor v) async =>
      _db.from('vendors').upsert(v.toJson());
  static Future<void> deleteVendor(String id) async =>
      _db.from('vendors').delete().eq('id', id);

  // ── Brick Types ──────────────────────────────────────────────────────────
  static Future<List<BrickType>> fetchBrickTypes() async {
    final rows = await _db.from('brick_types').select().order('created_at');
    return rows.map((r) => BrickType.fromJson(r)).toList();
  }
  static Future<void> upsertBrickType(BrickType b) async =>
      _db.from('brick_types').upsert(b.toJson());
  static Future<void> deleteBrickType(String id) async =>
      _db.from('brick_types').delete().eq('id', id);

  // ── Inventory ────────────────────────────────────────────────────────────
  static Future<List<Inventory>> fetchInventory() async {
    final rows = await _db.from('inventory').select();
    return rows.map((r) => Inventory.fromJson(r)).toList();
  }
  static Future<void> upsertInventory(Inventory i) async =>
      _db.from('inventory').upsert(i.toJson());

  // ── Invoices (with items via join) ────────────────────────────────────────
  static Future<List<Invoice>> fetchInvoices() async {
    final rows = await _db
        .from('invoices')
        .select('*, invoice_items(*)')
        .order('created_at');
    return rows.map((r) => Invoice.fromJson(r)).toList();
  }

  /// Upserts the invoice row, then replaces all its invoice_items.
  static Future<void> upsertInvoice(Invoice inv) async {
    // Build invoice row without the embedded items list
    final row = inv.toJson()..remove('items');
    await _db.from('invoices').upsert(row);

    // Replace items
    await _db.from('invoice_items').delete().eq('invoice_id', inv.id);
    if (inv.items.isNotEmpty) {
      await _db.from('invoice_items').insert(
        inv.items.map((item) {
          final j = item.toJson();
          j['invoice_id'] = inv.id;
          return j;
        }).toList(),
      );
    }
  }

  static Future<void> deleteInvoice(String id) async =>
      _db.from('invoices').delete().eq('id', id);

  // ── Deliveries (with items via join) ──────────────────────────────────────
  static Future<List<Delivery>> fetchDeliveries() async {
    final rows = await _db
        .from('deliveries')
        .select('*, delivery_items(*)')
        .order('delivery_date');
    return rows.map((r) => Delivery.fromJson(r)).toList();
  }

  static Future<void> upsertDelivery(Delivery d) async {
    final row = d.toJson()..remove('items');
    await _db.from('deliveries').upsert(row);

    await _db.from('delivery_items').delete().eq('delivery_id', d.id);
    if (d.items.isNotEmpty) {
      await _db.from('delivery_items').insert(
        d.items.map((item) {
          final j = item.toJson();
          j['delivery_id'] = d.id;
          return j;
        }).toList(),
      );
    }
  }

  static Future<void> deleteDelivery(String id) async =>
      _db.from('deliveries').delete().eq('id', id);

  // ── Borrow Transactions ───────────────────────────────────────────────────
  static Future<List<BorrowTransaction>> fetchBorrows() async {
    final rows = await _db.from('borrow_transactions').select().order('created_at');
    return rows.map((r) => BorrowTransaction.fromJson(r)).toList();
  }
  static Future<void> insertBorrow(BorrowTransaction b) async =>
      _db.from('borrow_transactions').insert(b.toJson());
  static Future<void> deleteBorrow(String id) async =>
      _db.from('borrow_transactions').delete().eq('id', id);

  // ── Worker Transactions ───────────────────────────────────────────────────
  static Future<List<WorkerTransaction>> fetchWorkerTransactions() async {
    final rows = await _db.from('worker_transactions').select().order('created_at');
    return rows.map((r) => WorkerTransaction.fromJson(r)).toList();
  }
  static Future<void> insertWorkerTransaction(WorkerTransaction t) async =>
      _db.from('worker_transactions').insert(t.toJson());
  static Future<void> deleteWorkerTransaction(String id) async =>
      _db.from('worker_transactions').delete().eq('id', id);

  // ── Settings ──────────────────────────────────────────────────────────────
  static Future<AppSettings?> fetchSettings() async {
    final rows = await _db.from('settings').select().limit(1);
    if (rows.isEmpty) return null;
    return AppSettings.fromJson(rows.first);
  }
  static Future<void> upsertSettings(AppSettings s) async {
    final json = s.toJson();
    json['id'] = 'default';
    await _db.from('settings').upsert(json);
  }

  // ── Realtime ──────────────────────────────────────────────────────────────
  static RealtimeChannel subscribeToAll(VoidCallback onRefresh) {
    const tables = [
      'clients', 'workers', 'cars', 'vendors',
      'brick_types', 'inventory', 'invoices', 'invoice_items',
      'deliveries', 'delivery_items', 'borrow_transactions',
      'worker_transactions', 'settings',
    ];
    var channel = _db.channel('panha:all');
    for (final table in tables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => onRefresh(),
      );
    }
    return channel..subscribe();
  }
}

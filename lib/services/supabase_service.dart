import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// ─── Supabase Config ──────────────────────────────────────────────────────────
// Only the ANON key belongs in client code.
// NEVER put the service_role key here.
const _supabaseUrl = 'https://umuwraheuputhjtmdomy.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtdXdyYWhldXB1dGhqdG1kb215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MDU2NTEsImV4cCI6MjA5MTQ4MTY1MX0.TwIRK4fKP0TzQKNQyo9nS4O9h6iQSQSjERPXRpGDGpQ';

/// Call once at app startup.
Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
}

SupabaseClient get _db => Supabase.instance.client;

// ─── Supabase Sync Service ────────────────────────────────────────────────────
// Syncs all data between local SharedPreferences and Supabase.
// Each table row uses the object's `id` as the primary key.
// Row-level security on Supabase should be set to allow anon read/write
// (or add auth for multi-user support later).
class SupabaseSync {
  // ── Clients ─────────────────────────────────────────────────────────────────
  static Future<List<Client>> fetchClients() async {
    final rows = await _db.from('clients').select().order('createdAt');
    return rows.map((r) => Client.fromJson(r)).toList();
  }

  static Future<void> upsertClient(Client c) async {
    await _db.from('clients').upsert(c.toJson());
  }

  static Future<void> deleteClient(String id) async {
    await _db.from('clients').delete().eq('id', id);
  }

  // ── Workers ──────────────────────────────────────────────────────────────────
  static Future<List<Worker>> fetchWorkers() async {
    final rows = await _db.from('workers').select().order('createdAt');
    return rows.map((r) => Worker.fromJson(r)).toList();
  }

  static Future<void> upsertWorker(Worker w) async {
    await _db.from('workers').upsert(w.toJson());
  }

  static Future<void> deleteWorker(String id) async {
    await _db.from('workers').delete().eq('id', id);
  }

  // ── Cars ─────────────────────────────────────────────────────────────────────
  static Future<List<Car>> fetchCars() async {
    final rows = await _db.from('cars').select();
    return rows.map((r) => Car.fromJson(r)).toList();
  }

  static Future<void> upsertCar(Car c) async {
    await _db.from('cars').upsert(c.toJson());
  }

  static Future<void> deleteCar(String id) async {
    await _db.from('cars').delete().eq('id', id);
  }

  // ── Vendors ──────────────────────────────────────────────────────────────────
  static Future<List<Vendor>> fetchVendors() async {
    final rows = await _db.from('vendors').select().order('createdAt');
    return rows.map((r) => Vendor.fromJson(r)).toList();
  }

  static Future<void> upsertVendor(Vendor v) async {
    await _db.from('vendors').upsert(v.toJson());
  }

  static Future<void> deleteVendor(String id) async {
    await _db.from('vendors').delete().eq('id', id);
  }

  // ── Borrows ──────────────────────────────────────────────────────────────────
  static Future<List<Borrow>> fetchBorrows() async {
    final rows = await _db.from('borrows').select().order('createdAt');
    return rows.map((r) => Borrow.fromJson(r)).toList();
  }

  static Future<void> upsertBorrow(Borrow b) async {
    await _db.from('borrows').upsert(b.toJson());
  }

  static Future<void> deleteBorrow(String id) async {
    await _db.from('borrows').delete().eq('id', id);
  }

  // ── Invoices ─────────────────────────────────────────────────────────────────
  static Future<List<Invoice>> fetchInvoices() async {
    final rows = await _db.from('invoices').select().order('createdAt');
    return rows.map((r) => Invoice.fromJson(r)).toList();
  }

  static Future<void> upsertInvoice(Invoice inv) async {
    await _db.from('invoices').upsert(inv.toJson());
  }

  static Future<void> deleteInvoice(String id) async {
    await _db.from('invoices').delete().eq('id', id);
  }

  // ── Settings ──────────────────────────────────────────────────────────────────
  static Future<AppSettings?> fetchSettings() async {
    final rows = await _db.from('settings').select().limit(1);
    if (rows.isEmpty) return null;
    final data = rows.first;
    return AppSettings.fromJson(data);
  }

  static Future<void> upsertSettings(AppSettings s) async {
    final json = s.toJson();
    json['id'] = 'global';
    await _db.from('settings').upsert(json);
  }
}

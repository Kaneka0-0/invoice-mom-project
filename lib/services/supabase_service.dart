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

// UUIDs from brick_types (existing rows) and brick_categories (seeded) tables.
String? _brickTypeId(String priceType) => switch (priceType) {
  'normal' => '65db6386-2d0c-431e-8ed4-cc08930d6325',
  'burned' => 'd885775c-8cd2-4ed2-8813-80a1e9612a5c',
  _        => null,
};

String? _brickCategoryId(String brickCategory) => switch (brickCategory) {
  'hol' => '00000000-0000-0000-0001-000000000001',
  'sol' => '00000000-0000-0000-0001-000000000002',
  _     => null,
};

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

  // ── Invoices (with items via join) ────────────────────────────────────────
  static Future<List<Invoice>> fetchInvoices() async {
    try {
      final rows = await _db
          .from('invoices')
          .select('*, invoice_items(*)')
          .order('created_at', ascending: false);
      return rows.map((r) => Invoice.fromJson(r)).toList();
    } catch (_) {
      // invoice_items table join failed — fall back to invoices only
      final rows = await _db
          .from('invoices')
          .select()
          .order('created_at', ascending: false);
      return rows.map((r) => Invoice.fromJson(r)).toList();
    }
  }

  /// Upserts the invoice row, then replaces all its invoice_items.
  static Future<void> upsertInvoice(Invoice inv) async {
    final row = <String, dynamic>{
      'id':         inv.id,
      'number':     inv.number,
      'client_id':  inv.clientId,
      'date':       inv.date,
      'status':     inv.status.name,
      'subtotal':   inv.subtotal,
      'total':      inv.total,
      'deposit':    inv.deposit,
      'notes':      inv.notes,
      'created_at': inv.createdAt,
    };

    await _db.from('invoices').upsert(row);

    // Replace invoice_items (table may not exist yet — ignore errors)
    try {
      await _db.from('invoice_items').delete().eq('invoice_id', inv.id);
      if (inv.items.isNotEmpty) {
        await _db.from('invoice_items').insert(
          inv.items.map((item) => {
            'id':                 item.id,
            'invoice_id':         inv.id,
            'quantity':           item.quantity,
            'unit_price':         item.unitPrice,
            'total':              item.total,
            'price_type':         item.priceType,
            'brick_category':     item.brickCategory,
            'brick_type_id':      _brickTypeId(item.priceType),
            'brick_category_id':  _brickCategoryId(item.brickCategory),
          }).toList(),
        );
      }
    } catch (_) {}
  }

  static Future<void> deleteInvoice(String id) async {
    // Clear all FK references first (cascade delete not configured in DB)
    try { await _db.from('invoice_items').delete().eq('invoice_id', id); } catch (_) {}
    try { await _db.from('delivery_items').delete().eq('invoice_id', id); } catch (_) {}
    try { await _db.from('delivery_proofs').delete().eq('invoice_id', id); } catch (_) {}
    try { await _db.from('borrow_transactions').delete().eq('related_invoice_id', id); } catch (_) {}
    await _db.from('invoices').delete().eq('id', id);
  }

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
      'clients', 'invoices', 'invoice_items', 'settings',
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

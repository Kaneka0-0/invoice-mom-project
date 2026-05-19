import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../services/supabase_service.dart';
import '../../../theme.dart';

// Opens a compact bottom-sheet to add or edit a client.
Future<void> showClientSheet(BuildContext context, {String? id}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppProvider>(),
      child: _ClientSheet(id: id),
    ),
  );
}

class _ClientSheet extends StatefulWidget {
  final String? id;
  const _ClientSheet({this.id});

  @override
  State<_ClientSheet> createState() => _ClientSheetState();
}

class _ClientSheetState extends State<_ClientSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // Each entry: {id: existing location id or null, ctrl: TextEditingController}
  final List<_LocEntry> _locs = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final provider = context.read<AppProvider>();
      final c = provider.store.clients.firstWhere(
        (x) => x.id == widget.id,
        orElse: () => Client(id: '', name: '', createdAt: ''),
      );
      _nameCtrl.text  = c.name;
      _phoneCtrl.text = c.phone;
      _notesCtrl.text = c.notes;

      // Load existing locations
      final existing = provider.locationsForClient(widget.id!);
      for (final loc in existing) {
        _locs.add(_LocEntry(id: loc.id, ctrl: TextEditingController(text: loc.name)));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    for (final e in _locs) e.ctrl.dispose();
    super.dispose();
  }

  void _addLocation() {
    setState(() => _locs.add(_LocEntry(ctrl: TextEditingController())));
  }

  void _removeLocation(int index) {
    final entry = _locs[index];
    entry.ctrl.dispose();
    setState(() => _locs.removeAt(index));
    // If it was a saved location, delete from provider
    if (entry.id != null && widget.id != null) {
      context.read<AppProvider>().deleteClientLocation(entry.id!).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s        = provider.s;
    final isEdit   = widget.id != null;
    final bottom   = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2218).withAlpha(12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 16, color: Color(0xFF0B2218)),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? '${s.edit} ${s.clients}' : '${s.add} ${s.clients}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B2218),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: '${s.name} *',
                        prefixIcon: const Icon(Icons.badge_outlined,
                            size: 18, color: AppColors.muted),
                        isDense: true,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: s.phone,
                        prefixIcon: const Icon(Icons.phone_outlined,
                            size: 18, color: AppColors.muted),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Delivery Locations ─────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Delivery Locations',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _addLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B2218),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Add',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_locs.isEmpty)
                      GestureDetector(
                        onTap: _addLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt_outlined,
                                  size: 16, color: AppColors.muted),
                              const SizedBox(width: 8),
                              Text('Add a delivery location',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._locs.asMap().entries.map((e) {
                        final i   = e.key;
                        final loc = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B2218).withAlpha(12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B2218),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: loc.ctrl,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Site A, Phnom Penh',
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeLocation(i),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 14, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: s.notes,
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Icon(Icons.notes_rounded,
                              size: 18, color: AppColors.muted),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(context, provider),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(s.save,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B2218),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.id == null) {
        // New client
        final client = await provider.addClient(
          name:  _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
        // Save non-empty locations
        for (final loc in _locs) {
          final name = loc.ctrl.text.trim();
          if (name.isNotEmpty) {
            await provider.addClientLocation(
                clientId: client.id, name: name);
          }
        }
      } else {
        // Update existing client
        final client =
            provider.store.clients.firstWhere((c) => c.id == widget.id);
        client.name  = _nameCtrl.text.trim();
        client.phone = _phoneCtrl.text.trim();
        client.notes = _notesCtrl.text.trim();
        await provider.updateClient(client);

        // Upsert locations: update existing, add new
        final existing = provider.locationsForClient(widget.id!);
        for (final loc in _locs) {
          final name = loc.ctrl.text.trim();
          if (name.isEmpty) continue;
          if (loc.id != null) {
            // Update if changed
            final prev = existing.firstWhere((e) => e.id == loc.id,
                orElse: () => ClientLocation(
                    id: '', clientId: '', name: ''));
            if (prev.name != name) {
              prev.name = name;
              await provider.store.save();
              SupabaseSync.upsertClientLocation(prev).catchError((_) {});
            }
          } else {
            // New location
            await provider.addClientLocation(
                clientId: widget.id!, name: name);
          }
        }
      }
      if (context.mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LocEntry {
  final String? id; // null = new, non-null = existing
  final TextEditingController ctrl;
  _LocEntry({this.id, required this.ctrl});
}

// Keep a routable screen as fallback for deep-links (/clients/new, /clients/:id/edit).
class ClientFormScreen extends StatefulWidget {
  final String? id;
  const ClientFormScreen({super.key, this.id});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showClientSheet(context, id: widget.id);
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.transparent);
}

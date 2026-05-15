import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
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
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _addressCtrl= TextEditingController();
  final _notesCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final c = context.read<AppProvider>().store.clients
          .firstWhere((x) => x.id == widget.id,
              orElse: () => Client(id: '', name: '', createdAt: ''));
      _nameCtrl.text    = c.name;
      _phoneCtrl.text   = c.phone;
      _addressCtrl.text = c.address;
      _notesCtrl.text   = c.notes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s        = provider.s;
    final isEdit   = widget.id != null;
    final bottom   = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Row(
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
            const SizedBox(height: 18),

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
            const SizedBox(height: 12),

            // Address
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.address,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.muted),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

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
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
    );
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.id == null) {
        await provider.addClient(
          name:    _nameCtrl.text.trim(),
          phone:   _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          notes:   _notesCtrl.text.trim(),
        );
      } else {
        final client =
            provider.store.clients.firstWhere((c) => c.id == widget.id);
        client.name    = _nameCtrl.text.trim();
        client.phone   = _phoneCtrl.text.trim();
        client.address = _addressCtrl.text.trim();
        client.notes   = _notesCtrl.text.trim();
        await provider.updateClient(client);
      }
      if (context.mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// Keep a routable screen as fallback for deep-links (/clients/new, /clients/:id/edit).
// It just opens the sheet on top of a transparent page.
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

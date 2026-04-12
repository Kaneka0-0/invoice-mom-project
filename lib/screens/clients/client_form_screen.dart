import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';

class ClientFormScreen extends StatefulWidget {
  final String? id;
  const ClientFormScreen({super.key, this.id});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _mapsCtrl    = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (widget.id == null) return;
    final c = context.read<AppProvider>().store.clients
        .firstWhere((x) => x.id == widget.id,
            orElse: () => Client(id: '', name: '', createdAt: ''));
    _nameCtrl.text    = c.name;
    _addressCtrl.text = c.address;
    _phoneCtrl.text   = c.phone;
    _notesCtrl.text   = c.notes;
    _mapsCtrl.text    = c.googleMapsUrl ?? '';
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _mapsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final isEdit = widget.id != null;
        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? '${s.edit} ${s.clients}' : '${s.add} ${s.clients}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FormSection(
                    title: s.name,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: '${s.name} *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FormSection(
                    title: s.address,
                    children: [
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(labelText: s.address),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _mapsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Google Maps URL (optional)',
                          prefixIcon: Icon(Icons.map_outlined),
                          hintText: 'https://maps.google.com/...',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FormSection(
                    title: s.phone,
                    children: [
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: InputDecoration(
                            labelText: s.phone,
                            prefixIcon: const Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FormSection(
                    title: s.notes,
                    children: [
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: InputDecoration(
                            labelText: s.notes, alignLabelWithHint: true),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          _saving ? null : () => _save(context, provider),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(s.save),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final mapsUrl = _mapsCtrl.text.trim();
      if (widget.id == null) {
        await provider.addClient(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          googleMapsUrl: mapsUrl.isEmpty ? null : mapsUrl,
        );
      } else {
        final client =
            provider.store.clients.firstWhere((c) => c.id == widget.id);
        client.name          = _nameCtrl.text.trim();
        client.address       = _addressCtrl.text.trim();
        client.phone         = _phoneCtrl.text.trim();
        client.notes         = _notesCtrl.text.trim();
        client.googleMapsUrl = mapsUrl.isEmpty ? null : mapsUrl;
        await provider.updateClient(client);
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

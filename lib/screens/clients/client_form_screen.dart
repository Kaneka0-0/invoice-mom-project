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
  final _nameCtrl = TextEditingController();
  final _nameKhCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressKhCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (widget.id == null) return;
    final provider = context.read<AppProvider>();
    final c = provider.store.clients.firstWhere(
      (x) => x.id == widget.id,
      orElse: () => Client(id: '', name: '', createdAt: ''),
    );
    _nameCtrl.text = c.name;
    _nameKhCtrl.text = c.nameKh;
    _addressCtrl.text = c.address;
    _addressKhCtrl.text = c.addressKh;
    _phoneCtrl.text = c.phone;
    _notesCtrl.text = c.notes;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameKhCtrl.dispose();
    _addressCtrl.dispose();
    _addressKhCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
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
                  title: '${s.clients} ${s.name}',
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: s.name),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameKhCtrl,
                      decoration:
                          InputDecoration(labelText: s.nameKh),
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
                      controller: _addressKhCtrl,
                      decoration:
                          InputDecoration(labelText: s.addressKh),
                      maxLines: 2,
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
                    onPressed: _saving ? null : () => _save(context, provider),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
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
      if (widget.id == null) {
        await provider.addClient(
          name: _nameCtrl.text.trim(),
          nameKh: _nameKhCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          addressKh: _addressKhCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final client = provider.store.clients
            .firstWhere((c) => c.id == widget.id);
        client.name = _nameCtrl.text.trim();
        client.nameKh = _nameKhCtrl.text.trim();
        client.address = _addressCtrl.text.trim();
        client.addressKh = _addressKhCtrl.text.trim();
        client.phone = _phoneCtrl.text.trim();
        client.notes = _notesCtrl.text.trim();
        await provider.updateClient(client);
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

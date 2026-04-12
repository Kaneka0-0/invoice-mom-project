import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';

class VendorFormScreen extends StatefulWidget {
  final String? id;
  const VendorFormScreen({super.key, this.id});

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameKhCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
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
    final v = provider.store.vendors
        .firstWhere((x) => x.id == widget.id, orElse: () => Vendor(id: '', name: '', createdAt: ''));
    _nameCtrl.text = v.name;
    _nameKhCtrl.text = v.nameKh;
    _addressCtrl.text = v.address;
    _phoneCtrl.text = v.phone;
    _notesCtrl.text = v.notes;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameKhCtrl.dispose();
    _addressCtrl.dispose();
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
            title: Text(isEdit ? '${s.edit} ${s.vendors}' : '${s.add} ${s.vendors}'),
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
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Neighbor vendors are brick suppliers you borrow from when your own stock runs short.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
                FormSection(
                  title: s.vendors,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          InputDecoration(labelText: s.name),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameKhCtrl,
                      decoration: InputDecoration(labelText: s.nameKh),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(labelText: s.address),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                          labelText: s.phone,
                          prefixIcon: const Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
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
        await provider.addVendor(
          name: _nameCtrl.text.trim(),
          nameKh: _nameKhCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final vendor = provider.store.vendors
            .firstWhere((v) => v.id == widget.id);
        vendor.name = _nameCtrl.text.trim();
        vendor.nameKh = _nameKhCtrl.text.trim();
        vendor.address = _addressCtrl.text.trim();
        vendor.phone = _phoneCtrl.text.trim();
        vendor.notes = _notesCtrl.text.trim();
        await provider.updateVendor(vendor);
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

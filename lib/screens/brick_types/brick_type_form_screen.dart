import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/common_widgets.dart';

class BrickTypeFormScreen extends StatefulWidget {
  final String? id;
  const BrickTypeFormScreen({super.key, this.id});

  @override
  State<BrickTypeFormScreen> createState() => _BrickTypeFormScreenState();
}

class _BrickTypeFormScreenState extends State<BrickTypeFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (widget.id == null) return;
    final bt = context.read<AppProvider>().store.findBrickType(widget.id!);
    if (bt == null) return;
    _nameCtrl.text = bt.name;
    _descCtrl.text = bt.description;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Brick Type' : 'Add Brick Type'),
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
                title: 'Brick Type',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'e.g. Standard, Premium, Hollow',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'e.g. Standard red clay brick, 25×12×6 cm',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<AppProvider>();
      if (widget.id == null) {
        await provider.addBrickType(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        );
      } else {
        final bt = provider.store.findBrickType(widget.id!);
        if (bt != null) {
          bt.name        = _nameCtrl.text.trim();
          bt.description = _descCtrl.text.trim();
          await provider.updateBrickType(bt);
        }
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

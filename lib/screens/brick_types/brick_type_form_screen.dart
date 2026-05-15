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
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _catCtrl    = TextEditingController();
  final _descCtrl   = TextEditingController();
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
    _catCtrl.text  = bt.category;
    _descCtrl.text = bt.description;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final provider = context.watch<AppProvider>();

    // Collect unique category names already in use for autocomplete
    final existingCategories = provider.brickTypes
        .map((b) => b.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

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
              // ── Category ──────────────────────────────────────────────
              FormSection(
                title: 'Category  •  ប្រភេទ',
                children: [
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _catCtrl.text),
                    optionsBuilder: (v) => existingCategories
                        .where((c) => c.toLowerCase()
                            .contains(v.text.toLowerCase())),
                    fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                      _catCtrl.text = ctrl.text;
                      return TextFormField(
                        controller: ctrl,
                        focusNode: focus,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          hintText:
                              'e.g.  ឥដ្ឋភ្លើង Brunt Brick',
                          helperText:
                              'Groups brick types on the invoice',
                        ),
                        onFieldSubmitted: (_) => onSubmit(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      );
                    },
                    onSelected: (v) => setState(() => _catCtrl.text = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Name ──────────────────────────────────────────────────
              FormSection(
                title: 'Brick Type Name  •  ឈ្មោះប្រភេទ',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'e.g.  ឥដ្ឋប្រហោង  Hollow',
                      helperText: 'Shown on the invoice item row',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Notes ─────────────────────────────────────────────────
              FormSection(
                title: 'Notes  (optional)',
                children: [
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Dimensions, colour, etc.',
                    ),
                    maxLines: 2,
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
          name:        _nameCtrl.text.trim(),
          category:    _catCtrl.text.trim(),
          description: _descCtrl.text.trim(),
        );
      } else {
        final bt = provider.store.findBrickType(widget.id!);
        if (bt != null) {
          bt.name        = _nameCtrl.text.trim();
          bt.category    = _catCtrl.text.trim();
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

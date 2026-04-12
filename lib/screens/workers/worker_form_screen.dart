import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';

class WorkerFormScreen extends StatefulWidget {
  final String? id;
  const WorkerFormScreen({super.key, this.id});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameKhCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  WorkerRole _role = WorkerRole.loader;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (widget.id == null) return;
    final provider = context.read<AppProvider>();
    final w = provider.store.workers
        .firstWhere((x) => x.id == widget.id, orElse: () => Worker(id: '', name: '', createdAt: ''));
    _nameCtrl.text = w.name;
    _nameKhCtrl.text = w.nameKh;
    _phoneCtrl.text = w.phone;
    _idCardCtrl.text = w.idCard;
    _notesCtrl.text = w.notes;
    setState(() => _role = w.role);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameKhCtrl.dispose();
    _phoneCtrl.dispose();
    _idCardCtrl.dispose();
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
            title: Text(isEdit ? '${s.edit} ${s.workers}' : '${s.add} ${s.workers}'),
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
                      decoration: InputDecoration(labelText: s.name),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameKhCtrl,
                      decoration: InputDecoration(labelText: '${s.nameKh}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FormSection(
                  title: s.role,
                  children: [
                    DropdownButtonFormField<WorkerRole>(
                      initialValue: _role,
                      decoration: InputDecoration(labelText: s.role),
                      items: WorkerRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(provider.isKh
                                    ? r.labelKh
                                    : r.label),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _role = v ?? _role),
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _idCardCtrl,
                      decoration: InputDecoration(
                          labelText: s.idCard,
                          prefixIcon: const Icon(Icons.badge_outlined)),
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
        await provider.addWorker(
          name: _nameCtrl.text.trim(),
          nameKh: _nameKhCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          role: _role,
          idCard: _idCardCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final worker = provider.store.workers
            .firstWhere((w) => w.id == widget.id);
        worker.name = _nameCtrl.text.trim();
        worker.nameKh = _nameKhCtrl.text.trim();
        worker.phone = _phoneCtrl.text.trim();
        worker.role = _role;
        worker.idCard = _idCardCtrl.text.trim();
        worker.notes = _notesCtrl.text.trim();
        await provider.updateWorker(worker);
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

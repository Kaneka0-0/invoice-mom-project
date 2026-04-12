import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../widgets/common_widgets.dart';

class CarFormScreen extends StatefulWidget {
  final String? id;
  const CarFormScreen({super.key, this.id});

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '30000');
  final _descCtrl = TextEditingController();
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
    final car = provider.store.cars
        .firstWhere((c) => c.id == widget.id, orElse: () => Car(id: '', plateNumber: ''));
    _plateCtrl.text = car.plateNumber;
    _capacityCtrl.text = car.capacity.toString();
    _descCtrl.text = car.description;
    _notesCtrl.text = car.notes;
    setState(() {});
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _capacityCtrl.dispose();
    _descCtrl.dispose();
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
            title: Text(isEdit ? '${s.edit} ${s.cars}' : '${s.add} ${s.cars}'),
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
                  title: s.cars,
                  children: [
                    TextFormField(
                      controller: _plateCtrl,
                      decoration: InputDecoration(
                        labelText: '${s.plateNumber} *',
                        hintText: 'e.g. PP 1234A',
                        prefixIcon: const Icon(Icons.local_shipping_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityCtrl,
                      decoration: InputDecoration(
                        labelText: s.capacity,
                        suffixText: 'bricks',
                        helperText: 'Default: 30,000 bricks per car',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Must be a positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g. Red Truck',
                      ),
                    ),
                    const SizedBox(height: 12),
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
      final capacity = int.tryParse(_capacityCtrl.text) ?? 30000;
      if (widget.id == null) {
        await provider.addCar(
          plateNumber: _plateCtrl.text.trim().toUpperCase(),
          capacity: capacity,
          description: _descCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final car = provider.store.cars
            .firstWhere((c) => c.id == widget.id);
        car.plateNumber = _plateCtrl.text.trim().toUpperCase();
        car.capacity = capacity;
        car.description = _descCtrl.text.trim();
        car.notes = _notesCtrl.text.trim();
        await provider.updateCar(car);
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

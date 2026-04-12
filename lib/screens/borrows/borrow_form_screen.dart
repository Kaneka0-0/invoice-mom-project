import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class BorrowFormScreen extends StatefulWidget {
  const BorrowFormScreen({super.key});

  @override
  State<BorrowFormScreen> createState() => _BorrowFormScreenState();
}

class _BorrowFormScreenState extends State<BorrowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _vendorId;
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        if (_priceCtrl.text.isEmpty) {
          _priceCtrl.text =
              provider.settings.brickPriceDefault.toStringAsFixed(4);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.isKh ? 'ខ្ចីឥដ្ឋ' : 'Record Borrowed Bricks'),
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
                // Context info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.isKh
                        ? 'ប្រើទំព័រនេះ ពេលដែលឥដ្ឋមិនគ្រប់ ហើយត្រូវខ្ចីពីអ្នកលក់ជិតខាង។ ជំពាក់នឹងត្រូវបន្ថែមទៅក្នុងបញ្ជី។'
                        : 'Use this when your bricks ran short and you borrowed from a neighbor vendor. The debt will be tracked in the Borrows list.',
                    style: const TextStyle(fontSize: 13, color: AppColors.slate),
                  ),
                ),
                const SizedBox(height: 20),

                FormSection(
                  title: s.borrowDate,
                  children: [
                    InkWell(
                      onTap: () => _pickDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: s.date,
                          suffixIcon:
                              const Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(_date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                FormSection(
                  title: s.selectVendor,
                  children: [
                    if (provider.vendors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No vendors yet. Add a vendor first.',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: _vendorId,
                      decoration: InputDecoration(labelText: s.vendor),
                      items: provider.vendors
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(v.name),
                              ))
                          .toList(),
                      validator: (v) =>
                          (v == null) ? 'Please select a vendor' : null,
                      onChanged: (v) => setState(() => _vendorId = v),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.push('/vendors/new');
                        setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('${s.add} ${s.vendors}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                FormSection(
                  title: '${s.quantity} & ${s.unitPrice}',
                  children: [
                    TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        suffixText: 'bricks',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price per brick',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Total preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.pale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.total,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forest)),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final qty = int.tryParse(_qtyCtrl.text) ?? 0;
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      await provider.addBorrow(
        vendorId: _vendorId!,
        date: _date,
        quantity: qty,
        unitPrice: price,
        notes: _notesCtrl.text.trim(),
      );
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

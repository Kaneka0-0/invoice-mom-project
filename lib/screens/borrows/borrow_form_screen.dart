import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class BorrowFormScreen extends StatefulWidget {
  const BorrowFormScreen({super.key});

  @override
  State<BorrowFormScreen> createState() => _BorrowFormScreenState();
}

class _BorrowFormScreenState extends State<BorrowFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  String?  _vendorId;
  String?  _brickTypeId;
  BorrowType _type = BorrowType.borrowIn;
  final _qtyCtrl   = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  double get _total {
    final qty   = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
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
            title: const Text('Brick Transaction'),
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
                  // ── Transaction Direction ───────────────────────────
                  FormSection(
                    title: 'Transaction Type',
                    children: [
                      // Row 1: We borrow / We return
                      Row(
                        children: [
                          Expanded(
                            child: _TypeTile(
                              label: 'We Borrowed',
                              sub: 'From neighbor',
                              icon: Icons.arrow_downward_rounded,
                              color: AppColors.warning,
                              selected: _type == BorrowType.borrowIn,
                              onTap: () => setState(
                                  () => _type = BorrowType.borrowIn),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeTile(
                              label: 'We Returned',
                              sub: 'To neighbor',
                              icon: Icons.arrow_upward_rounded,
                              color: AppColors.success,
                              selected: _type == BorrowType.borrowOut,
                              onTap: () => setState(
                                  () => _type = BorrowType.borrowOut),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Row 2: We lent / They returned
                      Row(
                        children: [
                          Expanded(
                            child: _TypeTile(
                              label: 'We Lent',
                              sub: 'To neighbor',
                              icon: Icons.north_east_rounded,
                              color: AppColors.forest,
                              selected: _type == BorrowType.lendOut,
                              onTap: () => setState(
                                  () => _type = BorrowType.lendOut),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeTile(
                              label: 'They Returned',
                              sub: 'From neighbor',
                              icon: Icons.south_west_rounded,
                              color: AppColors.neutral,
                              selected: _type == BorrowType.lendReturn,
                              onTap: () => setState(
                                  () => _type = BorrowType.lendReturn),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _typeDescription(_type),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Vendor ────────────────────────────────────────
                  FormSection(
                    title: s.selectVendor,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _vendorId,
                        decoration: InputDecoration(labelText: s.vendor),
                        items: provider.vendors
                            .map((v) => DropdownMenuItem(
                                  value: v.id,
                                  child: Text(v.name),
                                ))
                            .toList(),
                        validator: (v) =>
                            v == null ? 'Please select a vendor' : null,
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

                  // ── Brick Type ────────────────────────────────────
                  if (provider.brickTypes.isNotEmpty) ...[
                    FormSection(
                      title: 'Brick Type',
                      children: [
                        DropdownButtonFormField<String>(
                          value: _brickTypeId,
                          decoration: const InputDecoration(
                              labelText: 'Brick Type (optional)'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('— Any —')),
                            ...provider.brickTypes.map((b) =>
                                DropdownMenuItem(
                                    value: b.id, child: Text(b.name))),
                          ],
                          onChanged: (v) =>
                              setState(() => _brickTypeId = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Qty & Price ───────────────────────────────────
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
                        decoration: InputDecoration(
                          labelText: 'Price per brick',
                          prefixText: provider.settings.currencySymbol,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
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
                              '${provider.settings.currencySymbol}${NumberFormat('#,##0.00').format(_total)}',
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

  String _typeDescription(BorrowType type) {
    switch (type) {
      case BorrowType.borrowIn:
        return 'You borrowed bricks from this neighbor (they are owed bricks or money)';
      case BorrowType.borrowOut:
        return 'You returned bricks to this neighbor (reduces what you owe them)';
      case BorrowType.lendOut:
        return 'You lent bricks to this neighbor (they owe you bricks or money)';
      case BorrowType.lendReturn:
        return 'This neighbor returned the bricks they borrowed from you';
    }
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await provider.addBorrow(
        vendorId:    _vendorId!,
        brickTypeId: _brickTypeId,
        quantity:    int.tryParse(_qtyCtrl.text) ?? 0,
        unitPrice:   double.tryParse(_priceCtrl.text) ?? 0,
        type:        _type,
      );
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Type selection tile ───────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : AppColors.muted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppColors.ink,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

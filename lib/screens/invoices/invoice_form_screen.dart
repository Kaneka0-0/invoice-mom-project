import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class InvoiceFormScreen extends StatefulWidget {
  final String? id; // null = create, set = edit

  const InvoiceFormScreen({super.key, this.id});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _clientId;
  String? _carId;
  List<String> _workerIds = [];
  List<_ItemRow> _items = [_ItemRow()];
  String? _borrowId;
  String _notes = '';
  InvoiceStatus _status = InvoiceStatus.draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  void _loadExisting() {
    if (widget.id == null) return;
    final provider = context.read<AppProvider>();
    final inv = provider.store.findInvoice(widget.id);
    if (inv == null) return;
    setState(() {
      _date = inv.date;
      _clientId = inv.clientId;
      _carId = inv.carId;
      _workerIds = List.from(inv.workerIds);
      _items = inv.items
          .map((item) => _ItemRow(
                description: item.description,
                descriptionKh: item.descriptionKh,
                quantity: item.quantity.toString(),
                unit: item.unit,
                unitPrice: item.unitPrice.toString(),
              ))
          .toList();
      _borrowId = inv.borrowId;
      _notes = inv.notes;
      _status = inv.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final isEdit = widget.id != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? s.edit : s.newInvoice),
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
                // ── Date ───────────────────────────────────────────────
                FormSection(
                  title: '${s.invoiceDate}  •  ${s.date}',
                  children: [
                    _DateField(
                      value: _date,
                      onChanged: (v) => setState(() => _date = v),
                      label: s.date,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Client ─────────────────────────────────────────────
                FormSection(
                  title: '${s.billTo}  •  ${s.clients}',
                  children: [
                    _DropdownField<String>(
                      label: s.selectClient,
                      value: _clientId,
                      items: provider.clients
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name}${c.nameKh.isNotEmpty ? ' / ${c.nameKh}' : ''}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _clientId = v),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.push('/clients/new');
                        setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('${s.add} ${s.clients}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Car & Workers ──────────────────────────────────────
                FormSection(
                  title: '${s.delivery}',
                  children: [
                    _DropdownField<String>(
                      label: s.selectCar,
                      value: _carId,
                      items: provider.cars
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                    '${c.plateNumber}  (${NumberFormat('#,###').format(c.capacity)} bricks)'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _carId = v),
                    ),
                    if (_carId != null) ...[
                      const SizedBox(height: 6),
                      _carCapacityPreview(provider),
                    ],
                    const SizedBox(height: 12),
                    Text(s.selectWorkers,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.slate)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: provider.workers.map((w) {
                        final selected = _workerIds.contains(w.id);
                        return FilterChip(
                          label: Text(
                              '${w.name} (${w.role.label})',
                              style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _workerIds.add(w.id);
                              } else {
                                _workerIds.remove(w.id);
                              }
                            });
                          },
                          selectedColor: AppColors.pale,
                          checkmarkColor: AppColors.forest,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Items ──────────────────────────────────────────────
                FormSection(
                  title: '${s.items} (${_items.length} rows)',
                  children: [
                    ..._items.asMap().entries.map((e) => _ItemRowWidget(
                          index: e.key,
                          row: e.value,
                          onRemove: _items.length > 1
                              ? () => setState(() => _items.removeAt(e.key))
                              : null,
                          defaultPrice:
                              provider.settings.brickPriceDefault,
                          sym: provider.settings.currencySymbol,
                        )),
                    const SizedBox(height: 8),
                    if (_items.length < 20)
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _items.add(_ItemRow())),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(s.addItem),
                      ),
                    const SizedBox(height: 8),
                    _TotalPreview(
                        items: _items,
                        sym: provider.settings.currencySymbol),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Borrowed bricks ────────────────────────────────────
                FormSection(
                  title: '${s.borrowedBricks} (${s.vendors})',
                  children: [
                    Text(
                      provider.isKh
                          ? 'ប្រសិនបើឥដ្ឋមិនគ្រប់ ហើយត្រូវខ្ចីពីអ្នកលក់ជិតខាង'
                          : 'If bricks ran short and you borrowed from a neighbor vendor',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    _DropdownField<String>(
                      label: s.selectVendor + ' (optional)',
                      value: _borrowId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— None —')),
                        ...provider.borrows
                            .where((b) =>
                                b.status == BorrowStatus.owed &&
                                (b.invoiceId == null ||
                                    b.invoiceId == widget.id))
                            .map((b) {
                          final vendor =
                              provider.store.findVendor(b.vendorId);
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              '${vendor?.name ?? '?'}  •  ${NumberFormat('#,###').format(b.quantity)} bricks  •  ${provider.settings.currencySymbol}${b.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _borrowId = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Notes & Status ─────────────────────────────────────
                FormSection(
                  title: '${s.notes} & ${s.status}',
                  children: [
                    TextFormField(
                      initialValue: _notes,
                      decoration: InputDecoration(
                          labelText: s.notes, alignLabelWithHint: true),
                      maxLines: 3,
                      onChanged: (v) => _notes = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InvoiceStatus>(
                      initialValue: _status,
                      decoration:
                          InputDecoration(labelText: s.status),
                      items: InvoiceStatus.values
                          .map((st) => DropdownMenuItem(
                                value: st,
                                child: Text(provider.isKh
                                    ? st.labelKh
                                    : st.label),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _status = v ?? _status),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Save button ────────────────────────────────────────
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(context, provider),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
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

  Widget _carCapacityPreview(AppProvider provider) {
    final car = provider.store.findCar(_carId);
    if (car == null) return const SizedBox.shrink();
    final totalBricks = _items.fold<double>(
      0,
      (sum, item) =>
          sum + (double.tryParse(item.quantity) ?? 0),
    );
    final ratio = (totalBricks / car.capacity).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${NumberFormat('#,###').format(totalBricks.toInt())} / ${NumberFormat('#,###').format(car.capacity)} bricks ($pct%)',
          style: TextStyle(
              fontSize: 12,
              color: ratio > 0.9 ? AppColors.warning : AppColors.slate),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.border,
            color: ratio > 0.9 ? AppColors.warning : AppColors.forest,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);

    final items = _items
        .where((row) => row.description.isNotEmpty)
        .map((row) {
      final qty = double.tryParse(row.quantity) ?? 0;
      final price = double.tryParse(row.unitPrice) ?? 0;
      return InvoiceItem(
        description: row.description,
        descriptionKh: row.descriptionKh,
        quantity: qty,
        unit: row.unit,
        unitPrice: price,
        total: qty * price,
      );
    }).toList();

    try {
      if (widget.id == null) {
        final inv = await provider.addInvoice(
          date: _date,
          clientId: _clientId,
          carId: _carId,
          workerIds: _workerIds,
          items: items,
          borrowId: _borrowId,
          notes: _notes,
          status: _status,
        );
        if (context.mounted) context.go('/invoices/${inv.id}');
      } else {
        final inv = provider.store.findInvoice(widget.id)!;
        inv.date = _date;
        inv.clientId = _clientId;
        inv.carId = _carId;
        inv.workerIds = _workerIds;
        inv.items = items;
        inv.borrowId = _borrowId;
        inv.notes = _notes;
        inv.status = _status;
        await provider.updateInvoice(inv);
        if (context.mounted) context.go('/invoices/${widget.id}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Item row data ──────────────────────────────────────────────────────────────
class _ItemRow {
  String description;
  String descriptionKh;
  String quantity;
  String unit;
  String unitPrice;

  _ItemRow({
    this.description = '',
    this.descriptionKh = '',
    this.quantity = '',
    this.unit = 'pcs',
    this.unitPrice = '',
  });
}

// ── Item row widget ────────────────────────────────────────────────────────────
class _ItemRowWidget extends StatefulWidget {
  final int index;
  final _ItemRow row;
  final VoidCallback? onRemove;
  final double defaultPrice;
  final String sym;

  const _ItemRowWidget({
    required this.index,
    required this.row,
    required this.onRemove,
    required this.defaultPrice,
    required this.sym,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _descKhCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.row.description);
    _descKhCtrl = TextEditingController(text: widget.row.descriptionKh);
    _qtyCtrl = TextEditingController(text: widget.row.quantity);
    _priceCtrl = TextEditingController(
        text: widget.row.unitPrice.isEmpty
            ? widget.defaultPrice.toStringAsFixed(2)
            : widget.row.unitPrice);
    widget.row.unitPrice = _priceCtrl.text;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _descKhCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.index.isEven ? AppColors.mint : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: AppColors.danger, size: 18),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
            onChanged: (v) => row.description = v,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descKhCtrl,
            decoration: const InputDecoration(
              labelText: 'Khmer Description',
              isDense: true,
            ),
            onChanged: (v) => row.descriptionKh = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) => row.quantity = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: row.unit,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    isDense: true,
                  ),
                  items: ['pcs', 'kg', 'ton', 'box', 'set']
                      .map((u) =>
                          DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => row.unit = v ?? row.unit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Price (${widget.sym})',
                    isDense: true,
                    prefixText: widget.sym,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) => row.unitPrice = v,
                ),
              ),
            ],
          ),
          Builder(builder: (ctx) {
            final qty = double.tryParse(_qtyCtrl.text) ?? 0;
            final price = double.tryParse(_priceCtrl.text) ?? 0;
            final total = qty * price;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Row total: ${widget.sym}${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.forest),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Total preview ──────────────────────────────────────────────────────────────
class _TotalPreview extends StatelessWidget {
  final List<_ItemRow> items;
  final String sym;

  const _TotalPreview({required this.items, required this.sym});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, row) {
      final qty = double.tryParse(row.quantity) ?? 0;
      final price = double.tryParse(row.unitPrice) ?? 0;
      return sum + qty * price;
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TOTAL',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          Text(
            '$sym${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable dropdown field ────────────────────────────────────────────────────
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const _DateField(
      {required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        DateTime initial;
        try {
          initial = DateTime.parse(value);
        } catch (_) {
          initial = DateTime.now();
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value.isEmpty ? 'Select date' : value),
      ),
    );
  }
}

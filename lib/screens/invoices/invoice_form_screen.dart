import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class InvoiceFormScreen extends StatefulWidget {
  final String? id;
  const InvoiceFormScreen({super.key, this.id});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid    = const Uuid();

  String  _date     = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _clientId;
  List<_ItemRow> _items = [];
  String  _notes    = '';
  InvoiceStatus  _status        = InvoiceStatus.draft;
  PaymentStatus  _paymentStatus = PaymentStatus.unpaid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  void _loadExisting() {
    if (widget.id == null) {
      setState(() => _items = [_ItemRow(id: _uuid.v4())]);
      return;
    }
    final provider = context.read<AppProvider>();
    final inv = provider.store.findInvoice(widget.id);
    if (inv == null) {
      setState(() => _items = [_ItemRow(id: _uuid.v4())]);
      return;
    }
    setState(() {
      _date          = inv.date;
      _clientId      = inv.clientId;
      _notes         = inv.notes;
      _status        = inv.status;
      _paymentStatus = inv.paymentStatus;
      _items = inv.items.map((item) => _ItemRow(
            id:          item.id,
            brickTypeId: item.brickTypeId,
            quantity:    item.quantity.toString(),
            unitPrice:   item.unitPrice.toString(),
          )).toList();
      if (_items.isEmpty) _items = [_ItemRow(id: _uuid.v4())];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s      = provider.s;
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
                  // ── Date ────────────────────────────────────────────
                  FormSection(
                    title: s.invoiceDate,
                    children: [
                      _DateField(
                        value: _date,
                        onChanged: (v) => setState(() => _date = v),
                        label: s.date,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Client ───────────────────────────────────────────
                  FormSection(
                    title: '${s.billTo}  •  ${s.clients}',
                    children: [
                      DropdownButtonFormField<String>(
                        value: _clientId,
                        decoration: InputDecoration(labelText: s.selectClient),
                        items: provider.clients
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                        isExpanded: true,
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

                  // ── Items ────────────────────────────────────────────
                  FormSection(
                    title: '${s.items} (${_items.length} rows)',
                    children: [
                      ..._items.asMap().entries.map((e) => _ItemRowWidget(
                            index: e.key,
                            row:   e.value,
                            brickTypes: provider.brickTypes,
                            onRemove: _items.length > 1
                                ? () => setState(() => _items.removeAt(e.key))
                                : null,
                            defaultPrice: provider.settings.brickPriceDefault,
                            sym: provider.settings.currencySymbol,
                            onChanged: () => setState(() {}),
                          )),
                      const SizedBox(height: 8),
                      if (_items.length < 20)
                        OutlinedButton.icon(
                          onPressed: () => setState(
                              () => _items.add(_ItemRow(id: _uuid.v4()))),
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

                  // ── Notes & Status ───────────────────────────────────
                  FormSection(
                    title: '${s.notes} & ${s.status}',
                    children: [
                      TextFormField(
                        initialValue: _notes,
                        decoration: InputDecoration(
                            labelText: s.notes,
                            alignLabelWithHint: true),
                        maxLines: 3,
                        onChanged: (v) => _notes = v,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<InvoiceStatus>(
                        value: _status,
                        decoration: InputDecoration(labelText: s.status),
                        items: InvoiceStatus.values
                            .map((st) => DropdownMenuItem(
                                  value: st,
                                  child: Text(st.label),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PaymentStatus>(
                        value: _paymentStatus,
                        decoration: const InputDecoration(
                            labelText: 'Payment Status'),
                        items: PaymentStatus.values
                            .map((ps) => DropdownMenuItem(
                                  value: ps,
                                  child: Text(ps.label),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _paymentStatus = v ?? _paymentStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Save ─────────────────────────────────────────────
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
    _formKey.currentState!.save();
    setState(() => _saving = true);

    final invoiceId = widget.id ?? _uuid.v4();
    final items = _items
        .where((row) => row.quantity.isNotEmpty)
        .map((row) {
          final qty   = int.tryParse(row.quantity) ?? 0;
          final price = double.tryParse(row.unitPrice) ?? 0;
          return InvoiceItem(
            id:          row.id.isEmpty ? _uuid.v4() : row.id,
            invoiceId:   invoiceId,
            brickTypeId: row.brickTypeId,
            quantity:    qty,
            unitPrice:   price,
            total:       qty * price,
          );
        })
        .where((item) => item.quantity > 0)
        .toList();

    try {
      if (widget.id == null) {
        final inv = await provider.addInvoice(
          date:     _date,
          clientId: _clientId,
          items:    items,
          notes:    _notes,
          status:   _status,
        );
        // Apply payment status separately
        if (_paymentStatus != PaymentStatus.unpaid) {
          inv.paymentStatus = _paymentStatus;
          await provider.updateInvoice(inv);
        }
        if (context.mounted) context.go('/invoices/${inv.id}');
      } else {
        final inv = provider.store.findInvoice(widget.id)!;
        inv.date          = _date;
        inv.clientId      = _clientId;
        inv.items         = items;
        inv.notes         = _notes;
        inv.status        = _status;
        inv.paymentStatus = _paymentStatus;
        await provider.updateInvoice(inv);
        if (context.mounted) context.go('/invoices/${widget.id}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Item row data ─────────────────────────────────────────────────────────────
class _ItemRow {
  String  id;
  String? brickTypeId;
  String  quantity;
  String  unitPrice;

  _ItemRow({
    required this.id,
    this.brickTypeId,
    this.quantity  = '',
    this.unitPrice = '',
  });
}

// ── Item row widget ───────────────────────────────────────────────────────────
class _ItemRowWidget extends StatefulWidget {
  final int    index;
  final _ItemRow row;
  final List<BrickType> brickTypes;
  final VoidCallback?  onRemove;
  final double defaultPrice;
  final String sym;
  final VoidCallback onChanged;

  const _ItemRowWidget({
    required this.index,
    required this.row,
    required this.brickTypes,
    required this.onRemove,
    required this.defaultPrice,
    required this.sym,
    required this.onChanged,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl   = TextEditingController(text: widget.row.quantity);
    _priceCtrl = TextEditingController(
        text: widget.row.unitPrice.isEmpty
            ? widget.defaultPrice.toStringAsFixed(4)
            : widget.row.unitPrice);
    widget.row.unitPrice = _priceCtrl.text;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final qty   = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final rowTotal = qty * price;

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
          // Row header with index + remove button
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
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

          // Brick type selector
          if (widget.brickTypes.isNotEmpty)
            DropdownButtonFormField<String>(
              value: row.brickTypeId,
              decoration: const InputDecoration(
                  labelText: 'Brick Type', isDense: true),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('— Select type —')),
                ...widget.brickTypes.map((b) =>
                    DropdownMenuItem(value: b.id, child: Text(b.name))),
              ],
              onChanged: (v) => setState(() => row.brickTypeId = v),
              isExpanded: true,
            )
          else
            const Text(
              'No brick types configured. Add them in settings.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          const SizedBox(height: 8),

          // Qty + Price
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Qty (bricks)', isDense: true),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) {
                    row.quantity = v;
                    widget.onChanged();
                  },
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
                      prefixText: widget.sym),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) {
                    row.unitPrice = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Row total: ${widget.sym}${rowTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: AppColors.forest),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Total preview ─────────────────────────────────────────────────────────────
class _TotalPreview extends StatelessWidget {
  final List<_ItemRow> items;
  final String sym;

  const _TotalPreview({required this.items, required this.sym});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, row) {
      final qty   = int.tryParse(row.quantity) ?? 0;
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
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const _DateField(
      {required this.value,
      required this.onChanged,
      required this.label});

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

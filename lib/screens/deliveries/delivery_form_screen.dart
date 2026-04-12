import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import 'package:uuid/uuid.dart';

class DeliveryFormScreen extends StatefulWidget {
  final String? id;
  const DeliveryFormScreen({super.key, this.id});

  bool get isEdit => id != null;

  @override
  State<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends State<DeliveryFormScreen> {
  int _step = 0;
  String? _selectedCarId;
  String? _selectedDriverId;
  DateTime? _deliveryDate;
  final _notesCtrl = TextEditingController();
  final List<_DraftItem> _draftItems = [];
  bool _saving = false;
  final _uuid = const Uuid();

  static const _stepLabels = ['Truck', 'Driver', 'Invoices', 'Review'];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadExisting();
      });
    }
  }

  void _loadExisting() {
    final p = context.read<AppProvider>();
    final delivery = p.store.findDelivery(widget.id);
    if (delivery == null) return;
    setState(() {
      _selectedCarId    = delivery.carId;
      _selectedDriverId = delivery.driverId;
      _notesCtrl.text   = delivery.notes;
      if (delivery.deliveryDate != null) {
        try {
          _deliveryDate = DateTime.parse(delivery.deliveryDate!);
        } catch (_) {}
      }
      for (final item in delivery.items) {
        _draftItems.add(_DraftItem(
          id: item.id,
          invoiceId: item.invoiceId,
          quantity: item.quantity,
        ));
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final i in _draftItems) { i.dispose(); }
    super.dispose();
  }

  // ── Capacity helpers ───────────────────────────────────────────────────────

  int get _totalAssigned => _draftItems.fold(0, (s, i) => s + i.quantity);

  Car? _selectedCar(AppProvider p) =>
      p.store.findCar(_selectedCarId);

  double _capacityRatio(AppProvider p) {
    final car = _selectedCar(p);
    if (car == null || car.capacity <= 0) return 0;
    return (_totalAssigned / car.capacity).clamp(0.0, 1.5);
  }

  bool _overCapacity(AppProvider p) {
    final car = _selectedCar(p);
    if (car == null) return false;
    return _totalAssigned > car.capacity;
  }

  // ── Available invoices for step 3 ─────────────────────────────────────────

  List<Invoice> _availableInvoices(AppProvider p) {
    return p.invoices.where((inv) {
      if (inv.status == InvoiceStatus.cancelled) return false;
      if (inv.status == InvoiceStatus.delivered) return false;
      final rem = p.store.invoiceRemainingQty(inv.id,
          excludeDeliveryId: widget.id);
      final inDraft = _draftItems.any((d) => d.invoiceId == inv.id);
      // Show if there are bricks left to assign OR it's already in the draft
      return rem > 0 || inDraft;
    }).toList();
  }

  /// Max bricks user can assign for this invoice in the current delivery.
  /// = bricks remaining in other deliveries (excludeDeliveryId handles edit mode).
  int _invoiceMaxQty(AppProvider p, String invoiceId) {
    return p.store.invoiceRemainingQty(invoiceId,
        excludeDeliveryId: widget.id);
  }

  /// How many bricks are still free in the selected truck after current draft.
  int _truckFreeSpace(AppProvider p) {
    final car = _selectedCar(p);
    if (car == null) return 0;
    return (car.capacity - _totalAssigned).clamp(0, car.capacity);
  }

  /// Smart default qty when user taps "Add invoice":
  /// fills as much as fits in the truck, capped by invoice remaining.
  int _defaultQtyForAdd(AppProvider p, String invoiceId) {
    final rem   = _invoiceMaxQty(p, invoiceId);
    final free  = _truckFreeSpace(p);
    return (free > 0 ? free.clamp(1, rem) : rem).clamp(1, rem);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool get _canGoNext {
    return switch (_step) {
      0 => _selectedCarId != null,
      1 => true, // driver is optional
      2 => _draftItems.isNotEmpty,
      _ => false,
    };
  }

  void _next() {
    if (_step < 3 && _canGoNext) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save(BuildContext context, AppProvider p) async {
    if (_overCapacity(p)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total bricks exceed truck capacity'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final items = _draftItems.map((d) => DeliveryItem(
            id: d.id ?? _uuid.v4(),
            deliveryId: widget.id ?? '',
            invoiceId: d.invoiceId,
            quantity: d.quantity,
          )).toList();

      if (widget.isEdit) {
        final existing = p.store.findDelivery(widget.id)!;
        existing.carId       = _selectedCarId!;
        existing.driverId    = _selectedDriverId;
        existing.deliveryDate = _deliveryDate?.toIso8601String().substring(0, 10);
        existing.notes       = _notesCtrl.text.trim();
        existing.items       = items;
        await p.updateDelivery(existing);
      } else {
        await p.addDelivery(
          carId:        _selectedCarId!,
          driverId:     _selectedDriverId,
          deliveryDate: _deliveryDate?.toIso8601String().substring(0, 10),
          notes:        _notesCtrl.text.trim(),
          items:        items,
        );
      }
      if (context.mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isEdit ? 'Edit Delivery' : 'Plan Delivery'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── Step indicator ────────────────────────────────────
                _StepIndicator(current: _step, labels: _stepLabels),
                // ── Step content ──────────────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(context, provider),
                    ),
                  ),
                ),
                // ── Bottom navigation ─────────────────────────────────
                _BottomNav(
                  step: _step,
                  totalSteps: _stepLabels.length,
                  canGoNext: _canGoNext,
                  saving: _saving,
                  onBack: _back,
                  onNext: _next,
                  onSave: () => _save(context, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, AppProvider p) {
    return switch (_step) {
      0 => _TruckStep(
          cars: p.cars,
          selectedId: _selectedCarId,
          onSelect: (id) => setState(() => _selectedCarId = id),
        ),
      1 => _DriverStep(
          workers:          p.workers,
          selectedDriverId: _selectedDriverId,
          deliveryDate:     _deliveryDate,
          notesCtrl:        _notesCtrl,
          onDriverChanged:  (id) => setState(() => _selectedDriverId = id),
          onDateChanged:    (d) => setState(() => _deliveryDate = d),
        ),
      2 => _InvoiceStep(
          provider:    p,
          draftItems:  _draftItems,
          excludeId:   widget.id,
          car:         _selectedCar(p),
          totalAssigned: _totalAssigned,
          capacityRatio: _capacityRatio(p),
          overCapacity: _overCapacity(p),
          invoiceMaxQty: (id) => _invoiceMaxQty(p, id),
          availableInvoices: _availableInvoices(p),
          onAdd: (invoiceId) => setState(() {
            final qty = _defaultQtyForAdd(p, invoiceId);
            _draftItems.add(_DraftItem(invoiceId: invoiceId, quantity: qty));
          }),
          onRemove: (invoiceId) => setState(() {
            _draftItems.removeWhere((d) => d.invoiceId == invoiceId);
          }),
          onQtyChanged: (invoiceId, qty) => setState(() {
            final idx = _draftItems.indexWhere((d) => d.invoiceId == invoiceId);
            if (idx >= 0) _draftItems[idx].quantity = qty;
          }),
        ),
      _ => _ReviewStep(
          provider:     p,
          draftItems:   _draftItems,
          car:          _selectedCar(p),
          driver:       p.store.findWorker(_selectedDriverId),
          deliveryDate: _deliveryDate,
          notes:        _notesCtrl.text,
          totalAssigned: _totalAssigned,
          overCapacity: _overCapacity(p),
        ),
    };
  }
}

// ─── Step 1: Truck Selection ──────────────────────────────────────────────────

class _TruckStep extends StatelessWidget {
  final List<Car> cars;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _TruckStep({
    required this.cars,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final intFmt = NumberFormat('#,###');

    if (cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            const Text('No trucks registered',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/cars/new'),
              child: const Text('Add Truck'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Select Truck',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('Choose the truck for this delivery',
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        ...cars.map((car) {
          final sel = car.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(car.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? AppColors.forest.withAlpha(15) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppColors.forest : AppColors.border,
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.forest.withAlpha(20)
                          : AppColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: sel ? AppColors.forest : AppColors.muted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.plateNumber,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: sel ? AppColors.forest : AppColors.ink,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 12, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              'Capacity: ${intFmt.format(car.capacity)} bricks',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        if (car.description.isNotEmpty)
                          Text(car.description,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  if (sel)
                    const Icon(Icons.check_circle,
                        color: AppColors.forest, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Step 2: Driver + Date ────────────────────────────────────────────────────

class _DriverStep extends StatelessWidget {
  final List<Worker> workers;
  final String? selectedDriverId;
  final DateTime? deliveryDate;
  final TextEditingController notesCtrl;
  final ValueChanged<String?> onDriverChanged;
  final ValueChanged<DateTime?> onDateChanged;

  const _DriverStep({
    required this.workers,
    required this.selectedDriverId,
    required this.deliveryDate,
    required this.notesCtrl,
    required this.onDriverChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Drivers first, then others
    final sorted = List<Worker>.from(workers)
      ..sort((a, b) {
        final aD = a.role == WorkerRole.driver ? 0 : 1;
        final bD = b.role == WorkerRole.driver ? 0 : 1;
        return aD.compareTo(bD);
      });

    final dateStr = deliveryDate != null
        ? DateFormat('dd MMM yyyy').format(deliveryDate!)
        : 'Tap to select date';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Driver & Date',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('Assign a driver and schedule the delivery (optional)',
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 20),

        // Driver dropdown
        DropdownButtonFormField<String?>(
          value: selectedDriverId,
          decoration: const InputDecoration(
            labelText: 'Driver (optional)',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('— No driver —')),
            ...sorted.map((w) => DropdownMenuItem<String?>(
                  value: w.id,
                  child: Row(
                    children: [
                      Text(w.name),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pale,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(w.role.label,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.slate)),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: onDriverChanged,
        ),
        const SizedBox(height: 16),

        // Date picker
        const Text('Delivery Date',
            style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: deliveryDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            onDateChanged(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.muted),
                const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: deliveryDate != null
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
                const Spacer(),
                if (deliveryDate != null)
                  GestureDetector(
                    onTap: () => onDateChanged(null),
                    child: const Icon(Icons.clear,
                        size: 16, color: AppColors.muted),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        TextFormField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }
}

// ─── Step 3: Invoice Assignment ───────────────────────────────────────────────

class _InvoiceStep extends StatelessWidget {
  final AppProvider provider;
  final List<_DraftItem> draftItems;
  final String? excludeId;
  final Car? car;
  final int totalAssigned;
  final double capacityRatio;
  final bool overCapacity;
  final int Function(String invoiceId) invoiceMaxQty;
  final List<Invoice> availableInvoices;
  final void Function(String invoiceId) onAdd;
  final void Function(String invoiceId) onRemove;
  final void Function(String invoiceId, int qty) onQtyChanged;

  const _InvoiceStep({
    required this.provider,
    required this.draftItems,
    required this.excludeId,
    required this.car,
    required this.totalAssigned,
    required this.capacityRatio,
    required this.overCapacity,
    required this.invoiceMaxQty,
    required this.availableInvoices,
    required this.onAdd,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final intFmt  = NumberFormat('#,###');
    final addedIds = draftItems.map((d) => d.invoiceId).toSet();
    final unAdded  = availableInvoices
        .where((inv) => !addedIds.contains(inv.id))
        .toList();
    final truckFree = car != null
        ? (car!.capacity - totalAssigned).clamp(0, car!.capacity)
        : 0;

    return Column(
      children: [
        // ── Sticky capacity bar ──────────────────────────────────────
        _CapacityBar(
          used:      totalAssigned,
          capacity:  car?.capacity ?? 0,
          ratio:     capacityRatio,
          over:      overCapacity,
        ),
        // ── Invoice list ─────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Added invoices
              if (draftItems.isNotEmpty) ...[
                const Text('Added to Delivery',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest)),
                const SizedBox(height: 8),
                ...draftItems.map((item) {
                  final inv = provider.store.findInvoice(item.invoiceId);
                  final client = provider.store.findClient(inv?.clientId);
                  final maxQty = invoiceMaxQty(item.invoiceId);
                  return _AddedInvoiceRow(
                    invoice:   inv,
                    clientName: client?.name,
                    item:       item,
                    maxQty:     maxQty,
                    onRemove:   () => onRemove(item.invoiceId),
                    onQtyChanged: (qty) => onQtyChanged(item.invoiceId, qty),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],

              // Available to add
              Text(
                unAdded.isEmpty
                    ? 'All available invoices added'
                    : 'Available Invoices',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate),
              ),
              const SizedBox(height: 8),
              if (unAdded.isEmpty && draftItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No invoices with pending deliveries',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                ),
              ...unAdded.map((inv) {
                final client = provider.store.findClient(inv.clientId);
                final rem = invoiceMaxQty(inv.id);
                return _AvailableInvoiceRow(
                  invoice:    inv,
                  clientName: client?.name,
                  remaining:  rem,
                  truckFree:  truckFree,
                  intFmt:     intFmt,
                  onAdd: () => onAdd(inv.id),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final int used;
  final int capacity;
  final double ratio;
  final bool over;

  const _CapacityBar({
    required this.used,
    required this.capacity,
    required this.ratio,
    required this.over,
  });

  @override
  Widget build(BuildContext context) {
    final intFmt  = NumberFormat('#,###');
    final color   = over ? AppColors.danger : ratio > 0.9 ? AppColors.warning : AppColors.forest;
    final capText = capacity > 0 ? intFmt.format(capacity) : '—';
    final free    = (capacity - used).clamp(0, capacity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  over
                      ? 'Over capacity! ${intFmt.format(used)} / $capText'
                      : '${intFmt.format(used)} / $capText bricks loaded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Text(
                over
                    ? 'Over by ${intFmt.format(used - capacity)}'
                    : capacity > 0
                        ? '${intFmt.format(free)} free'
                        : 'No truck',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddedInvoiceRow extends StatefulWidget {
  final Invoice? invoice;
  final String? clientName;
  final _DraftItem item;
  final int maxQty;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChanged;

  const _AddedInvoiceRow({
    required this.invoice,
    required this.clientName,
    required this.item,
    required this.maxQty,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  State<_AddedInvoiceRow> createState() => _AddedInvoiceRowState();
}

class _AddedInvoiceRowState extends State<_AddedInvoiceRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intFmt = NumberFormat('#,###');
    final over = widget.item.quantity > widget.maxQty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: over
            ? AppColors.danger.withAlpha(10)
            : AppColors.forest.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: over
              ? AppColors.danger.withAlpha(60)
              : AppColors.forest.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.invoice?.number ?? widget.item.invoiceId,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (widget.clientName != null)
                      Text(
                        widget.clientName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'Max: ${intFmt.format(widget.maxQty)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity input
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: _ctrl,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                suffixText: 'bricks',
                errorText: over ? '> max' : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                final qty = int.tryParse(v) ?? 0;
                widget.onQtyChanged(qty);
              },
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.danger, size: 20),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AvailableInvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final String? clientName;
  final int remaining;     // total invoice remaining
  final int truckFree;     // free space in truck right now
  final NumberFormat intFmt;
  final VoidCallback onAdd;

  const _AvailableInvoiceRow({
    required this.invoice,
    required this.clientName,
    required this.remaining,
    required this.truckFree,
    required this.intFmt,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // How many bricks "Add" will pre-fill
    final willAdd = truckFree > 0
        ? truckFree.clamp(1, remaining)
        : remaining;
    final partial = willAdd < remaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.number,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (clientName != null)
                      Text(
                        clientName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '${intFmt.format(remaining)} bricks remaining'
                      '${partial ? "  •  ${intFmt.format(willAdd)} fits" : ""}',
                      style: TextStyle(
                          fontSize: 11,
                          color: partial ? AppColors.warning : AppColors.slate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.forest,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Review ───────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final AppProvider provider;
  final List<_DraftItem> draftItems;
  final Car? car;
  final Worker? driver;
  final DateTime? deliveryDate;
  final String notes;
  final int totalAssigned;
  final bool overCapacity;

  const _ReviewStep({
    required this.provider,
    required this.draftItems,
    required this.car,
    required this.driver,
    required this.deliveryDate,
    required this.notes,
    required this.totalAssigned,
    required this.overCapacity,
  });

  @override
  Widget build(BuildContext context) {
    final intFmt = NumberFormat('#,###');
    final dateStr = deliveryDate != null
        ? DateFormat('dd MMM yyyy').format(deliveryDate!)
        : 'No date set';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Review & Confirm',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('Review delivery details before saving',
            style: TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 20),

        // ── Summary card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _ReviewRow(
                icon: Icons.local_shipping_outlined,
                label: 'Truck',
                value: car?.plateNumber ?? '—',
                sub: car != null
                    ? 'Capacity: ${intFmt.format(car!.capacity)} bricks'
                    : null,
              ),
              const Divider(height: 16),
              _ReviewRow(
                icon: Icons.person_outline,
                label: 'Driver',
                value: driver?.name ?? 'Not assigned',
              ),
              const Divider(height: 16),
              _ReviewRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: dateStr,
              ),
              if (notes.isNotEmpty) ...[
                const Divider(height: 16),
                _ReviewRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: notes,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Capacity summary ─────────────────────────────────────────
        if (car != null)
          _CapacityBar(
            used:     totalAssigned,
            capacity: car!.capacity,
            ratio:    car!.capacity > 0
                ? (totalAssigned / car!.capacity).clamp(0.0, 1.5)
                : 0,
            over: overCapacity,
          ),
        const SizedBox(height: 16),

        // ── Invoice table ────────────────────────────────────────────
        const Text('Invoices',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        ...draftItems.map((item) {
          final inv    = provider.store.findInvoice(item.invoiceId);
          final client = provider.store.findClient(inv?.clientId);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv?.number ?? item.invoiceId,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      if (client != null)
                        Text(client.name,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                Text(
                  '${intFmt.format(item.quantity)} bricks',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),

        if (overCapacity)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total (${intFmt.format(totalAssigned)}) exceeds truck capacity '
                    '(${intFmt.format(car?.capacity ?? 0)}). '
                    'Please reduce quantities.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.muted)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final List<String> labels;

  const _StepIndicator({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final i     = e.key;
          final label = e.value;
          final done  = i < current;
          final active = i == current;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.forest
                            : active
                                ? AppColors.forest
                                : AppColors.border,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : AppColors.muted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? AppColors.forest : AppColors.muted,
                      ),
                    ),
                  ],
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: i < current ? AppColors.forest : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool canGoNext;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const _BottomNav({
    required this.step,
    required this.totalSteps,
    required this.canGoNext,
    required this.saving,
    required this.onBack,
    required this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (step > 0)
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
          const Spacer(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
            ),
          if (isLast)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 16),
                label: Text(saving ? 'Saving...' : 'Save Delivery'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Draft Item model ─────────────────────────────────────────────────────────

class _DraftItem {
  final String? id; // null for new items
  final String invoiceId;
  int quantity;

  _DraftItem({this.id, required this.invoiceId, required this.quantity});

  void dispose() {} // kept for symmetric API
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../services/invoice_html_service.dart';
import '../../../theme.dart';
import '../clients/client_form_screen.dart';
import 'package:uuid/uuid.dart';

class InvoiceFormScreen extends StatefulWidget {
  final String? id;
  const InvoiceFormScreen({super.key, this.id});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _clientId;
  String? _deliveryLocation;
  bool _saving = false;

  final _depositCtrl = TextEditingController();

  // Fixed 4 slots: normal/hol, normal/sol, burned/hol, burned/sol
  late final List<_BrickEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [
      _BrickEntry(priceType: 'normal', brickCategory: 'hol'),
      _BrickEntry(priceType: 'normal', brickCategory: 'sol'),
      _BrickEntry(priceType: 'burned', brickCategory: 'hol'),
      _BrickEntry(priceType: 'burned', brickCategory: 'sol'),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _depositCtrl.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _loadExisting() {
    final provider = context.read<AppProvider>();
    final defaultPrice = provider.settings.brickPriceDefault;
    for (final e in _entries) {
      e.priceCtrl.text = defaultPrice.toStringAsFixed(3);
    }

    if (widget.id == null) {
      setState(() {});
      return;
    }

    final inv = provider.store.findInvoice(widget.id);
    if (inv == null) {
      setState(() {});
      return;
    }

    setState(() {
      _date = inv.date;
      _clientId = inv.clientId;
      _deliveryLocation = inv.deliveryLocation;
      if (inv.deposit > 0) {
        _depositCtrl.text = inv.deposit.toString();
      }
      for (final item in inv.items) {
        try {
          final entry = _entries.firstWhere(
            (e) => e.priceType == item.priceType && e.brickCategory == item.brickCategory,
          );
          entry.existingId = item.id;
          entry.qtyCtrl.text = item.quantity.toString();
          entry.priceCtrl.text = item.unitPrice.toStringAsFixed(3);
        } catch (_) {}
      }
    });
  }

  double get _grandTotal => _entries.fold(0.0, (s, e) => s + e.total);

  Future<void> _pickLocation(BuildContext context, List<ClientLocation> locations) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(locations: locations),
    );
    if (picked != null && mounted) {
      setState(() => _deliveryLocation = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final isEdit = widget.id != null;
        final sym = provider.settings.currencySymbol;
        final fmt = NumberFormat('#,##0.00');

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B2218),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              isEdit ? 'Edit Invoice' : s.newInvoice,
              style: const TextStyle(
                color: Color(0xFF0D1F17),
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B2218), size: 18),
              onPressed: () => context.pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B2218)),
                      )
                    : GestureDetector(
                        onTap: () => _save(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2218),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isEdit ? s.save : 'Add',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // ── Date ──────────────────────────────────────────────
                  _FormCard(
                    icon: Icons.calendar_today_outlined,
                    title: s.invoiceDate,
                    child: _DateField(
                      value: _date,
                      onChanged: (v) => setState(() => _date = v),
                      label: s.date,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Client ────────────────────────────────────────────
                  _FormCard(
                    icon: Icons.person_outline_rounded,
                    title: s.billTo,
                    child: _ClientPicker(
                      clients: provider.clients,
                      selectedId: _clientId,
                      onChanged: (id) {
                        setState(() {
                          _clientId = id;
                          _deliveryLocation = null;
                        });
                        if (id != null) {
                          final locs = provider.locationsForClient(id);
                          if (locs.length == 1) {
                            setState(() => _deliveryLocation = locs.first.name);
                          } else if (locs.length > 1) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _pickLocation(context, locs);
                            });
                          }
                        }
                      },
                      onAddNew: () async {
                        await showClientSheet(context);
                        setState(() {});
                      },
                      s: s,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Selected location chip ─────────────────────────────
                  if (_deliveryLocation != null) ...[
                    GestureDetector(
                      onTap: () {
                        if (_clientId != null) {
                          final locs = provider.locationsForClient(_clientId!);
                          if (locs.isNotEmpty) _pickLocation(context, locs);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2218).withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0B2218).withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: Color(0xFF0B2218)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _deliveryLocation!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B2218),
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0B2218)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Deposit ───────────────────────────────────────────
                  _FormCard(
                    icon: Icons.payments_outlined,
                    title: provider.isKh ? 'ប្រាក់កក់' : 'Deposit',
                    child: TextField(
                      controller: _depositCtrl,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        isDense: true,
                        prefixText: '${provider.settings.currencySymbol} ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Items ─────────────────────────────────────────────
                  _FormCard(
                    icon: Icons.inventory_2_outlined,
                    title: s.items,
                    child: Column(
                      children: [
                        _BrickGroup(
                          label: provider.isKh ? 'ឥដ្ឋធម្មតា' : 'Normal',
                          holLabel: provider.isKh ? 'ប្រហោង' : 'Hol',
                          solLabel: provider.isKh ? 'ចំនួន' : 'Sol',
                          holEntry: _entries[0],
                          solEntry: _entries[1],
                          sym: sym,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _BrickGroup(
                          label: provider.isKh ? 'ឥដ្ឋខ្លោច' : 'Burnt',
                          holLabel: provider.isKh ? 'ប្រហោង' : 'Hol',
                          solLabel: provider.isKh ? 'ចំនួន' : 'Sol',
                          holEntry: _entries[2],
                          solEntry: _entries[3],
                          sym: sym,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B2218), Color(0xFF1A4030)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL',
                                  style: TextStyle(
                                      color: Color(0xFF86EFAC),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      fontSize: 12)),
                              Text(
                                '$sym${fmt.format(_grandTotal)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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

    final filled = _entries.where((e) => e.qty > 0).toList();
    if (filled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter quantity for at least one brick type'),
      ));
      return;
    }

    setState(() => _saving = true);

    final deposit = double.tryParse(_depositCtrl.text) ?? 0;
    final invoiceId = widget.id ?? _uuid.v4();
    final items = filled
        .map((e) => InvoiceItem(
              id: e.existingId.isEmpty ? _uuid.v4() : e.existingId,
              invoiceId: invoiceId,
              brickTypeId: null,
              quantity: e.qty,
              unitPrice: e.price,
              total: e.total,
              priceType: e.priceType,
              brickCategory: e.brickCategory,
            ))
        .toList();

    try {
      Invoice savedInv;
      if (widget.id == null) {
        savedInv = await provider.addInvoice(
          date: _date,
          clientId: _clientId,
          deliveryLocation: _deliveryLocation,
          items: items,
          deposit: deposit,
        );

        if (context.mounted) {
          context.go('/invoices');
          final client = provider.store.findClient(savedInv.clientId ?? '');
          InvoiceHtmlService.download(
            invoice: savedInv,
            client: client,
            settings: provider.settings,
            editPath: '/invoices/${savedInv.id}/edit',
          );
        }
      } else {
        final inv = provider.store.findInvoice(widget.id)!;
        inv.date = _date;
        inv.clientId = _clientId;
        inv.deliveryLocation = _deliveryLocation;
        inv.items = items;
        inv.deposit = deposit;
        await provider.updateInvoice(inv);
        savedInv = inv;

        if (context.mounted) {
          context.go('/invoices');
          final client = provider.store.findClient(savedInv.clientId ?? '');
          InvoiceHtmlService.download(
            invoice: savedInv,
            client: client,
            settings: provider.settings,
            editPath: '/invoices/${savedInv.id}/edit',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2218).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: const Color(0xFF0B2218)),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B2218),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Brick entry (one slot: priceType × brickCategory) ────────────────────────

class _BrickEntry {
  final String priceType;
  final String brickCategory;
  String existingId;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _BrickEntry({
    required this.priceType,
    required this.brickCategory,
  })  : existingId = '',
        qtyCtrl = TextEditingController(),
        priceCtrl = TextEditingController();

  int get qty => int.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get total => qty * price;

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ── Brick group card (Normal or Burnt with Hol + Sol rows) ───────────────────

class _BrickGroup extends StatelessWidget {
  final String label;
  final String holLabel;
  final String solLabel;
  final _BrickEntry holEntry;
  final _BrickEntry solEntry;
  final String sym;
  final VoidCallback onChanged;

  const _BrickGroup({
    required this.label,
    required this.holLabel,
    required this.solLabel,
    required this.holEntry,
    required this.solEntry,
    required this.sym,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final groupTotal = holEntry.total + solEntry.total;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2ECE7)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF5F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B2218))),
                const Spacer(),
                if (groupTotal > 0)
                  Text(
                    '$sym${fmt.format(groupTotal)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B2218)),
                  ),
              ],
            ),
          ),
          _BrickEntryRow(
            label: holLabel,
            entry: holEntry,
            sym: sym,
            onChanged: onChanged,
            showDivider: true,
          ),
          _BrickEntryRow(
            label: solLabel,
            entry: solEntry,
            sym: sym,
            onChanged: onChanged,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _BrickEntryRow extends StatelessWidget {
  final String label;
  final _BrickEntry entry;
  final String sym;
  final VoidCallback onChanged;
  final bool showDivider;

  const _BrickEntryRow({
    required this.label,
    required this.entry,
    required this.sym,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1F17),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.qtyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    isDense: true,
                    prefixIcon: Icon(Icons.format_list_numbered, size: 14, color: AppColors.muted),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: entry.priceCtrl,
                  decoration: InputDecoration(
                    hintText: 'Price',
                    isDense: true,
                    prefixText: '$sym ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Container(height: 1, color: const Color(0xFFF0F0F0)),
      ],
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const _DateField({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    String display = value;
    try {
      display = DateFormat('dd MMM yyyy').format(DateTime.parse(value));
    } catch (_) {}

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
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.muted),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.muted),
        ),
        child: Text(
          display.isEmpty ? 'Select date' : display,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0D1F17)),
        ),
      ),
    );
  }
}

// ── Client picker (searchable dropdown with add button) ───────────────────────

class _ClientPicker extends StatefulWidget {
  final List<Client> clients;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;
  final dynamic s;

  const _ClientPicker({
    required this.clients,
    required this.selectedId,
    required this.onChanged,
    required this.onAddNew,
    required this.s,
  });

  @override
  State<_ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends State<_ClientPicker> {
  final _searchCtrl = TextEditingController();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  String get _selectedName {
    if (widget.selectedId == null) return '';
    return widget.clients
        .firstWhere((c) => c.id == widget.selectedId,
            orElse: () => Client(id: '', name: '', createdAt: ''))
        .name;
  }

  void _toggle(BuildContext context) {
    _open ? _close() : _open_(context);
  }

  void _open_(BuildContext context) {
    _open = true;
    _searchCtrl.clear();
    _overlay = _buildOverlay(context);
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    _open = false;
    _searchCtrl.clear();
  }

  OverlayEntry _buildOverlay(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final spaceBelow = screenH - offset.dy - size.height;
    final showAbove = spaceBelow < 320;

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: showAbove ? const Offset(0, -320) : Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                child: SizedBox(
                  width: size.width,
                  child: _ClientPickerDropdown(
                    clients: widget.clients,
                    searchCtrl: _searchCtrl,
                    selectedId: widget.selectedId,
                    onSelect: (id) {
                      widget.onChanged(id);
                      _close();
                    },
                    onAddNew: () {
                      _close();
                      widget.onAddNew();
                    },
                    s: widget.s,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _close();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClient = widget.selectedId != null && _selectedName.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => _toggle(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: hasClient ? const Color(0xFF0B2218).withAlpha(8) : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasClient ? const Color(0xFF0B2218).withAlpha(60) : const Color(0xFFE2E8E4),
              width: hasClient ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasClient ? Icons.person_rounded : Icons.person_outline_rounded,
                size: 18,
                color: hasClient ? const Color(0xFF0B2218) : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasClient ? _selectedName : widget.s.selectClient,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasClient ? FontWeight.w600 : FontWeight.normal,
                    color: hasClient ? const Color(0xFF0D1F17) : AppColors.muted,
                  ),
                ),
              ),
              if (hasClient)
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                    _close();
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                )
              else
                Icon(
                  _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientPickerDropdown extends StatefulWidget {
  final List<Client> clients;
  final TextEditingController searchCtrl;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAddNew;
  final dynamic s;

  const _ClientPickerDropdown({
    required this.clients,
    required this.searchCtrl,
    required this.selectedId,
    required this.onSelect,
    required this.onAddNew,
    required this.s,
  });

  @override
  State<_ClientPickerDropdown> createState() => _ClientPickerDropdownState();
}

class _ClientPickerDropdownState extends State<_ClientPickerDropdown> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty
        ? widget.clients
        : widget.clients.where((c) => c.name.toLowerCase().contains(q)).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: widget.searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                fillColor: const Color(0xFFF4F4F5),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0B2218), width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Add new client button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: GestureDetector(
              onTap: widget.onAddNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2218).withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0B2218).withAlpha(40),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Color(0xFF0B2218)),
                    SizedBox(width: 8),
                    Text('Add New Client',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B2218),
                        )),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Client list
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Text('No clients found', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final selected = c.id == widget.selectedId;
                  return InkWell(
                    onTap: () => widget.onSelect(c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF0B2218)
                                  : const Color(0xFF0B2218).withAlpha(14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF0B2218),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? const Color(0xFF0B2218)
                                          : const Color(0xFF0D1F17),
                                    )),
                                if (c.phone.isNotEmpty)
                                  Text(c.phone,
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0B2218)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Location picker bottom sheet ──────────────────────────────────────────────

class _LocationPickerSheet extends StatelessWidget {
  final List<ClientLocation> locations;
  const _LocationPickerSheet({required this.locations});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2218).withAlpha(12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0B2218)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Select Delivery Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B2218),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...locations.map((loc) => GestureDetector(
                onTap: () => Navigator.of(context).pop(loc.name),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0B2218)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B2218),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

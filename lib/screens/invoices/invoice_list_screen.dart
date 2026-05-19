import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/invoice_html_service.dart';
import '../../../services/supabase_service.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _search = '';
  String? _monthFilter;
  String? _clientFilter;
  bool _generalFilter = false;
  bool _tableView     = false;
  late final Stream<List<Invoice>> _invoicesStream;

  @override
  void initState() {
    super.initState();
    _invoicesStream = SupabaseSync.invoicesStream();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s   = provider.s;
        final sym = provider.settings.currencySymbol;

        return StreamBuilder<List<Invoice>>(
          stream: _invoicesStream,
          builder: (context, snapshot) {
            final filtered = (snapshot.data ?? provider.invoices).where((inv) {
              final client = provider.store.findClient(inv.clientId);
              final matchSearch = _search.isEmpty ||
                  inv.number.toLowerCase().contains(_search.toLowerCase()) ||
                  (client?.name.toLowerCase().contains(_search.toLowerCase()) ?? false);
              final matchMonth   = _monthFilter == null || inv.date.startsWith(_monthFilter!);
              final matchClient  = _clientFilter == null || inv.clientId == _clientFilter;
              final matchGeneral = !_generalFilter || (inv.clientId == null || inv.clientId!.isEmpty);
              return matchSearch && matchMonth && matchClient && matchGeneral;
            }).toList();

            return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: Column(
            children: [
              // ── Page header ────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.invoices,
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D1F17),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'All your invoices',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _tableView = !_tableView),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _tableView
                                      ? const Color(0xFF0B2218)
                                      : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  _tableView
                                      ? Icons.table_rows_rounded
                                      : Icons.grid_view_rounded,
                                  size: 17,
                                  color: _tableView ? Colors.white : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Search bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: s.search,
                            prefixIcon: const Icon(Icons.search, size: 20),
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF0B2218), width: 1.5),
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 10),
                        // Month + General + Client filters
                        Row(
                          children: [
                            _MonthButton(
                              label: _monthFilter == null
                                  ? 'Month'
                                  : _monthLabel(_monthFilter!),
                              onTap: () => _pickMonth(context),
                              onClear: _monthFilter != null
                                  ? () => setState(() => _monthFilter = null)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            _GeneralButton(
                              active: _generalFilter,
                              onTap: () => setState(() {
                                _generalFilter = !_generalFilter;
                                if (_generalFilter) _clientFilter = null;
                              }),
                            ),
                            const SizedBox(width: 8),
                            if (provider.clients.isNotEmpty)
                              _ClientFilterDropdown(
                                clients: provider.clients,
                                selectedId: _clientFilter,
                                onChanged: (id) => setState(() {
                                  _clientFilter = id;
                                  if (id != null) _generalFilter = false;
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_hasActiveFilter)
                Container(
                  color: const Color(0xFFF0FAF4),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt,
                          size: 14, color: Color(0xFF0B2218)),
                      const SizedBox(width: 6),
                      Text(
                        '${filtered.length} invoice${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0B2218),
                            fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: const Text('Clear all',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0B2218),
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: s.noInvoices,
                          actionLabel: s.newInvoice,
                          onAction: () => context.push('/invoices/new'),
                        ),
                      )
                    : _tableView
                        ? _InvoiceTableBody(
                            invoices: filtered,
                            provider: provider,
                            sym: sym,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: (filtered.length / 2).ceil(),
                            itemBuilder: (ctx, rowIdx) {
                              final i    = rowIdx * 2;
                              final inv1 = filtered[i];
                              final cl1  = provider.store.findClient(inv1.clientId);
                              final inv2 = (i + 1 < filtered.length) ? filtered[i + 1] : null;
                              final cl2  = inv2 != null ? provider.store.findClient(inv2.clientId) : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InvoiceCard(
                                        invoice:    inv1,
                                        clientName: cl1?.name ?? '—',
                                        sym:        sym,
                                        onTap: () => InvoiceHtmlService.download(
                                          invoice:    provider.store.findInvoice(inv1.id) ?? inv1,
                                          client:     cl1,
                                          settings:   provider.settings,
                                          editPath:   '/invoices/${inv1.id}/edit',
                                        ),
                                        onDelete: () async {
                                          final ok = await showDeleteDialog(ctx, itemName: 'Invoice');
                                          if (ok && ctx.mounted) await provider.deleteInvoice(inv1.id);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    if (inv2 != null)
                                      Expanded(
                                        child: _InvoiceCard(
                                          invoice:    inv2,
                                          clientName: cl2?.name ?? '—',
                                          sym:        sym,
                                          onTap: () => InvoiceHtmlService.download(
                                            invoice:    provider.store.findInvoice(inv2.id) ?? inv2,
                                            client:     cl2,
                                            settings:   provider.settings,
                                            editPath:   '/invoices/${inv2.id}/edit',
                                          ),
                                          onDelete: () async {
                                            final ok = await showDeleteDialog(ctx, itemName: 'Invoice');
                                            if (ok && ctx.mounted) await provider.deleteInvoice(inv2.id);
                                          },
                                        ),
                                      )
                                    else
                                      const Expanded(child: SizedBox()),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/invoices/new'),
            backgroundColor: const Color(0xFF0B2218),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
          },
        );
      },
    );
  }

  bool get _hasActiveFilter =>
      _monthFilter != null || _clientFilter != null || _search.isNotEmpty || _generalFilter;

  void _clearFilters() {
    setState(() {
      _search         = '';
      _monthFilter    = null;
      _clientFilter   = null;
      _generalFilter  = false;
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _monthFilter =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
    }
  }

  String _monthLabel(String month) {
    try {
      return DateFormat('MMM yyyy').format(DateTime.parse('$month-01'));
    } catch (_) {
      return month;
    }
  }
}

// ── Month button ───────────────────────────────────────────────────────────────
class _MonthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _MonthButton(
      {required this.label, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    final active = onClear != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B2218) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF0B2218)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month,
                size: 14,
                color: active ? Colors.white : AppColors.muted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.white : AppColors.slate,
                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
            if (active) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── General filter button ─────────────────────────────────────────────────────
class _GeneralButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _GeneralButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B2218) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF0B2218) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined,
                size: 14,
                color: active ? Colors.white : AppColors.muted),
            const SizedBox(width: 5),
            Text(
              'General',
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : AppColors.slate,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Invoice card (matches home screen style) ──────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String clientName;
  final String sym;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.clientName,
    required this.sym,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt     = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy');
    String dateStr = invoice.date;
    try { dateStr = dateFmt.format(DateTime.parse(invoice.date)); } catch (_) {}
    final itemCount = invoice.items.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName != '—' ? clientName : invoice.number,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (clientName != '—') ...[
                        const SizedBox(height: 3),
                        Text(
                          invoice.number,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),
            Text(
              'Invoice Details',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            _DetailRow(label: 'Amount', value: '$sym${fmt.format(invoice.total)}'),
            const SizedBox(height: 6),
            _DetailRow(label: 'Date', value: dateStr),
            if (itemCount > 0) ...[
              const SizedBox(height: 6),
              _DetailRow(label: 'Items',
                  value: '$itemCount item${itemCount == 1 ? '' : 's'}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
      ],
    );
  }
}

// ── Searchable client filter dropdown ─────────────────────────────────────────
class _ClientFilterDropdown extends StatefulWidget {
  final List<Client> clients;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ClientFilterDropdown({
    required this.clients,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<_ClientFilterDropdown> createState() => _ClientFilterDropdownState();
}

class _ClientFilterDropdownState extends State<_ClientFilterDropdown> {
  final _searchCtrl = TextEditingController();
  final _layerLink  = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  String get _selectedName {
    if (widget.selectedId == null) return 'All Clients';
    return widget.clients
        .firstWhere((c) => c.id == widget.selectedId,
            orElse: () => Client(id: '', name: 'All Clients', createdAt: ''))
        .name;
  }

  void _openDropdown(BuildContext context) {
    if (_open) {
      _closeDropdown();
      return;
    }
    _open = true;
    _searchCtrl.clear();
    _overlay = _buildOverlay(context);
    Overlay.of(context).insert(_overlay!);
  }

  void _closeDropdown() {
    _overlay?.remove();
    _overlay = null;
    _open = false;
    _searchCtrl.clear();
  }

  OverlayEntry _buildOverlay(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
                child: SizedBox(
                  width: size.width,
                  child: _DropdownContent(
                    clients: widget.clients,
                    searchCtrl: _searchCtrl,
                    selectedId: widget.selectedId,
                    onSelect: (id) {
                      widget.onChanged(id);
                      _closeDropdown();
                    },
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
    _closeDropdown();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = widget.selectedId != null;
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => _openDropdown(context),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasFilter ? AppColors.pale : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasFilter ? AppColors.forest : AppColors.border,
              width: hasFilter ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline,
                  size: 15,
                  color: hasFilter ? AppColors.forest : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                _selectedName,
                style: TextStyle(
                  fontSize: 12,
                  color: hasFilter ? AppColors.forest : AppColors.slate,
                  fontWeight:
                      hasFilter ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              if (hasFilter)
                GestureDetector(
                  onTap: () {
                    widget.onChanged(null);
                    _closeDropdown();
                  },
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.forest),
                )
              else
                const Icon(Icons.expand_more,
                    size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownContent extends StatefulWidget {
  final List<Client> clients;
  final TextEditingController searchCtrl;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _DropdownContent({
    required this.clients,
    required this.searchCtrl,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_DropdownContent> createState() => _DropdownContentState();
}

class _DropdownContentState extends State<_DropdownContent> {
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
        : widget.clients
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: widget.searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          // "All" option
          _DropdownOption(
            label: 'All Clients',
            selected: widget.selectedId == null,
            onTap: () => widget.onSelect(null),
          ),
          // Client list
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                return _DropdownOption(
                  label: c.name,
                  selected: widget.selectedId == c.id,
                  onTap: () => widget.onSelect(c.id),
                );
              },
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No clients found',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: selected ? AppColors.pale : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? AppColors.forest : AppColors.ink,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 16, color: AppColors.forest),
          ],
        ),
      ),
    );
  }
}

// ── Table view for invoice list ───────────────────────────────────────────────

class _InvoiceTableBody extends StatelessWidget {
  final List<Invoice> invoices;
  final AppProvider provider;
  final String sym;

  const _InvoiceTableBody({
    required this.invoices,
    required this.provider,
    required this.sym,
  });

  static const _colW  = [2.0, 2.2, 1.8, 1.5];
  static const _heads = ['CLIENT', 'INVOICE NO', 'DATE', 'AMOUNT'];
  static final _fmt   = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final total = _colW.fold(0.0, (a, b) => a + b);
      final ws    = _colW.map((w) => w / total * box.maxWidth).toList();

      return Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: List.generate(_heads.length, (i) => SizedBox(
                width: ws[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Text(
                    _heads[i],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.4,
                    ),
                    textAlign: i == _heads.length - 1 ? TextAlign.right : TextAlign.left,
                  ),
                ),
              )),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (ctx, i) {
                final inv    = invoices[i];
                final client = provider.store.findClient(inv.clientId);
                String date  = '';
                try { date = DateFormat('dd MMM yyyy').format(DateTime.parse(inv.date)); } catch (_) {}
                final tot    = inv.total;

                return GestureDetector(
                  onTap: () => InvoiceHtmlService.download(
                    invoice:  provider.store.findInvoice(inv.id) ?? inv,
                    client:   client,
                    settings: provider.settings,
                    editPath: '/invoices/${inv.id}/edit',
                  ),
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        SizedBox(
                          width: ws[0],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Text(client?.name ?? '—',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D1F17)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        SizedBox(
                          width: ws[1],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Text(inv.number,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        SizedBox(
                          width: ws[2],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Text(date,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ),
                        ),
                        SizedBox(
                          width: ws[3],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Text('$sym${_fmt.format(tot)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B2218)),
                                textAlign: TextAlign.right),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}


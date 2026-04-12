import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  DeliveryStatus? _filter;

  // ── Pending bricks helpers ─────────────────────────────────────────────────

  /// Invoices with at least 1 brick not yet assigned to any non-cancelled delivery.
  List<_PendingInvoice> _pendingInvoices(AppProvider p) {
    final result = <_PendingInvoice>[];
    for (final inv in p.invoices) {
      if (inv.status == InvoiceStatus.cancelled) continue;
      if (inv.status == InvoiceStatus.delivered) continue;
      if (inv.totalBricks == 0) continue;
      final assigned  = p.store.invoiceAssignedQty(inv.id);
      final remaining = p.store.invoiceRemainingQty(inv.id);
      if (remaining > 0) {
        result.add(_PendingInvoice(
          invoice:   inv,
          client:    p.store.findClient(inv.clientId),
          total:     inv.totalBricks,
          assigned:  assigned,
          remaining: remaining,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final all = List<Delivery>.from(provider.deliveries)
          ..sort((a, b) {
            final da = a.deliveryDate ?? '';
            final db = b.deliveryDate ?? '';
            return db.compareTo(da);
          });
        final filtered = _filter == null
            ? all
            : all.where((d) => d.status == _filter).toList();

        final pending = _pendingInvoices(provider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Deliveries'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/deliveries/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // ── Pending bricks panel ────────────────────────────────────
              if (pending.isNotEmpty)
                _PendingBricksPanel(
                  pending: pending,
                  onPlan: () => context.push('/deliveries/new'),
                ),
              // ── Filter chips ────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: all.length,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    ...DeliveryStatus.values.map((s) => _FilterChip(
                          label: s.label,
                          count: all.where((d) => d.status == s).length,
                          selected: _filter == s,
                          color: _statusChipColor(s),
                          onTap: () => setState(
                              () => _filter = _filter == s ? null : s),
                        )),
                  ],
                ),
              ),
              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.local_shipping_outlined,
                        message: all.isEmpty
                            ? 'No deliveries yet'
                            : 'No ${_filter?.label ?? ''} deliveries',
                        actionLabel: all.isEmpty ? 'Plan Delivery' : null,
                        onAction: all.isEmpty
                            ? () => context.push('/deliveries/new')
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _DeliveryCard(
                          delivery: filtered[i],
                          provider: provider,
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/deliveries/new'),
            icon: const Icon(Icons.add),
            label: const Text('Plan Delivery'),
          ),
        );
      },
    );
  }

  Color _statusChipColor(DeliveryStatus s) => switch (s) {
        DeliveryStatus.planned   => AppColors.neutral,
        DeliveryStatus.loading   => AppColors.warning,
        DeliveryStatus.onRoute   => AppColors.forest,
        DeliveryStatus.delivered => AppColors.success,
        DeliveryStatus.cancelled => AppColors.danger,
      };
}

// ── Pending invoice data ──────────────────────────────────────────────────────

class _PendingInvoice {
  final Invoice invoice;
  final Client? client;
  final int total;
  final int assigned;
  final int remaining;

  const _PendingInvoice({
    required this.invoice,
    required this.client,
    required this.total,
    required this.assigned,
    required this.remaining,
  });
}

// ── Pending bricks panel ──────────────────────────────────────────────────────

class _PendingBricksPanel extends StatefulWidget {
  final List<_PendingInvoice> pending;
  final VoidCallback onPlan;

  const _PendingBricksPanel({
    required this.pending,
    required this.onPlan,
  });

  @override
  State<_PendingBricksPanel> createState() => _PendingBricksPanelState();
}

class _PendingBricksPanelState extends State<_PendingBricksPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final intFmt       = NumberFormat('#,###');
    final totalPending = widget.pending.fold<int>(0, (s, p) => s + p.remaining);
    final totalOrdered = widget.pending.fold<int>(0, (s, p) => s + p.total);
    final totalAssigned = widget.pending.fold<int>(0, (s, p) => s + p.assigned);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // ── Header row (always visible) ──────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pending_actions_outlined,
                        size: 17, color: AppColors.warning),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Bricks',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink),
                        ),
                        Text(
                          '${intFmt.format(totalPending)} bricks unloaded'
                          '  •  ${widget.pending.length} invoice${widget.pending.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  // Overall progress pill
                  if (totalOrdered > 0) ...[
                    _ProgressPill(
                      assigned: totalAssigned,
                      total: totalOrdered,
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Plan button
                  GestureDetector(
                    onTap: widget.onPlan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 13, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Plan',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Invoice rows (collapsible) ────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.pending.map((p) => _PendingInvoiceRow(
                  item: p,
                  intFmt: intFmt,
                )),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _PendingInvoiceRow extends StatelessWidget {
  final _PendingInvoice item;
  final NumberFormat intFmt;

  const _PendingInvoiceRow({
    required this.item,
    required this.intFmt,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = item.total > 0 ? item.assigned / item.total : 0.0;
    final fullyUnassigned = item.assigned == 0;

    return InkWell(
      onTap: () => context.push('/invoices/${item.invoice.id}'),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Left: invoice number + client
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.invoice.number,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (item.invoice.status == InvoiceStatus.partiallyDelivered)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Partial',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forest)),
                      ),
                  ],
                ),
                if (item.client != null)
                  Text(item.client!.name,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          // Right: qty breakdown + mini bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fullyUnassigned
                    ? '${intFmt.format(item.remaining)} bricks waiting'
                    : '${intFmt.format(item.remaining)} remaining / ${intFmt.format(item.total)} total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fullyUnassigned ? AppColors.warning : AppColors.slate,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fullyUnassigned ? AppColors.warning : AppColors.forest,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullyUnassigned
                    ? 'Not assigned to any truck'
                    : '${intFmt.format(item.assigned)} assigned',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _ProgressPill extends StatelessWidget {
  final int assigned;
  final int total;

  const _ProgressPill({required this.assigned, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? ((assigned / total) * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Text(
        '$pct% loaded',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.warning),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    this.color = AppColors.forest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(30) : AppColors.canvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            count > 0 ? '$label  $count' : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? color : AppColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delivery card ─────────────────────────────────────────────────────────────

class _DeliveryCard extends StatefulWidget {
  final Delivery delivery;
  final AppProvider provider;

  const _DeliveryCard({required this.delivery, required this.provider});

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _expanded = false;

  Delivery get d => widget.delivery;
  AppProvider get p => widget.provider;

  @override
  Widget build(BuildContext context) {
    final car    = p.store.findCar(d.carId);
    final driver = p.store.findWorker(d.driverId);
    final intFmt = NumberFormat('#,###');

    final totalBricks = d.items.fold<int>(0, (s, i) => s + i.quantity);
    final dateFmt = _fmtDate(d.deliveryDate);

    final (statusColor, statusBg) = _statusStyle(d.status);
    final isFinal = d.status == DeliveryStatus.delivered ||
        d.status == DeliveryStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Tappable left section — expands/collapses
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        // Status indicator icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _statusIcon(d.status),
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      car?.plateNumber ?? 'Unknown Truck',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      d.status.label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Text(
                                    driver?.name ?? 'No driver',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFmt,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${intFmt.format(totalBricks)} bricks'
                                    '  •  ${d.items.length} invoice${d.items.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate),
                                  ),
                                  if (car != null) ...[
                                    const SizedBox(width: 8),
                                    _MiniCapacityBar(
                                        used: totalBricks,
                                        capacity: car.capacity),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Mark Complete button (active deliveries only) ──
                if (!isFinal) ...[
                  const SizedBox(width: 8),
                  _CompleteButton(
                    onTap: () => _markComplete(context),
                  ),
                ],
              ],
            ),
          ),

          // ── Expanded content ──────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            // Invoice rows
            if (d.items.isNotEmpty)
              ...d.items.map((item) {
                final inv = p.store.findInvoice(item.invoiceId);
                final client = p.store.findClient(inv?.clientId);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv?.number ?? item.invoiceId,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
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
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  if (!isFinal)
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                          '/deliveries/${d.id}/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  const SizedBox(width: 8),
                  ..._actionButtons(context),
                  const Spacer(),
                  if (!isFinal)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 18),
                      onPressed: () => _delete(context),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // One-tap complete: marks delivery delivered + auto-syncs invoice statuses
  Future<void> _markComplete(BuildContext context) async {
    await p.updateDeliveryStatus(d.id, DeliveryStatus.delivered);
  }

  Future<void> _setStatus(BuildContext context, DeliveryStatus status) async {
    if (status == DeliveryStatus.cancelled) {
      final ok = await showDeleteDialog(context, itemName: 'delivery');
      if (!ok || !context.mounted) return;
    }
    await p.updateDeliveryStatus(d.id, status);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDeleteDialog(context, itemName: 'delivery');
    if (ok && context.mounted) {
      await p.deleteDelivery(d.id);
    }
  }

  List<Widget> _actionButtons(BuildContext context) {
    return switch (d.status) {
      DeliveryStatus.planned => [
          OutlinedButton.icon(
            onPressed: () => _setStatus(context, DeliveryStatus.loading),
            icon: const Icon(Icons.inventory_outlined, size: 14),
            label: const Text('Loading'),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning)),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () => _setStatus(context, DeliveryStatus.cancelled),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        ],
      DeliveryStatus.loading => [
          OutlinedButton.icon(
            onPressed: () => _setStatus(context, DeliveryStatus.onRoute),
            icon: const Icon(Icons.local_shipping_outlined, size: 14),
            label: const Text('On Route'),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.forest,
                side: const BorderSide(color: AppColors.forest)),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () => _setStatus(context, DeliveryStatus.cancelled),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        ],
      _ => [],
    };
  }

  String _fmtDate(String? date) {
    if (date == null || date.isEmpty) return 'No date';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  (Color, Color) _statusStyle(DeliveryStatus s) => switch (s) {
        DeliveryStatus.planned   => (AppColors.neutral, AppColors.neutral.withAlpha(20)),
        DeliveryStatus.loading   => (AppColors.warning, AppColors.warning.withAlpha(20)),
        DeliveryStatus.onRoute   => (AppColors.forest, AppColors.forest.withAlpha(20)),
        DeliveryStatus.delivered => (AppColors.success, AppColors.success.withAlpha(20)),
        DeliveryStatus.cancelled => (AppColors.danger, AppColors.danger.withAlpha(20)),
      };

  IconData _statusIcon(DeliveryStatus s) => switch (s) {
        DeliveryStatus.planned   => Icons.schedule_outlined,
        DeliveryStatus.loading   => Icons.inventory_outlined,
        DeliveryStatus.onRoute   => Icons.local_shipping_outlined,
        DeliveryStatus.delivered => Icons.check_circle_outline,
        DeliveryStatus.cancelled => Icons.cancel_outlined,
      };
}

// ── Complete button ───────────────────────────────────────────────────────────

class _CompleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CompleteButton({required this.onTap});

  @override
  State<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<_CompleteButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await Future.microtask(widget.onTap);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Mini capacity bar ─────────────────────────────────────────────────────────

class _MiniCapacityBar extends StatelessWidget {
  final int used;
  final int capacity;

  const _MiniCapacityBar({required this.used, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio = capacity > 0 ? (used / capacity).clamp(0.0, 1.0) : 0.0;
    final over  = used > capacity;
    final color = over ? AppColors.danger : ratio > 0.85 ? AppColors.warning : AppColors.forest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: ratio,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(ratio * 100).round()}%',
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

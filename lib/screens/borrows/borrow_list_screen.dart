import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class BorrowListScreen extends StatelessWidget {
  const BorrowListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s      = provider.s;
        final fmt    = NumberFormat('#,##0.00');
        final intFmt = NumberFormat('#,###');

        final vendorIds = provider.borrows
            .map((b) => b.vendorId)
            .toSet()
            .toList();

        // Total we owe to all vendors
        final totalWeOwe = provider.store.totalOwedToVendors();
        // Total all vendors owe us
        final totalTheyOwe = vendorIds.fold<double>(
            0, (s, vId) => s + provider.store.totalVendorOwesUs(vId));

        return Scaffold(
          appBar: AppBar(
            title: Text(s.borrows),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/borrows/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // ── Summary banners ───────────────────────────────────────
              if (totalWeOwe > 0)
                _SummaryBanner(
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.warning,
                  bgColor: const Color(0xFFFFFBEB),
                  text:
                      'We owe: \$${fmt.format(totalWeOwe)}',
                ),
              if (totalTheyOwe > 0)
                _SummaryBanner(
                  icon: Icons.info_outline,
                  color: AppColors.forest,
                  bgColor: const Color(0xFFD8F3DC),
                  text:
                      'Neighbors owe us: \$${fmt.format(totalTheyOwe)}',
                ),

              // ── Per-vendor list ───────────────────────────────────────
              Expanded(
                child: provider.borrows.isEmpty
                    ? EmptyState(
                        icon: Icons.swap_horiz_outlined,
                        message: s.noBorrows,
                        actionLabel: 'Record Transaction',
                        onAction: () => context.push('/borrows/new'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: vendorIds.length,
                        itemBuilder: (ctx, i) {
                          final vId    = vendorIds[i];
                          final vendor = provider.store.findVendor(vId);
                          final weOwe =
                              provider.store.totalOwedToVendor(vId);
                          final theyOwe =
                              provider.store.totalVendorOwesUs(vId);
                          final bricksWeOwe =
                              provider.store.totalBricksOwedToVendor(vId);
                          final bricksTheyOwe =
                              provider.store.totalBricksVendorOwesUs(vId);
                          final txns = provider.borrows
                              .where((b) => b.vendorId == vId)
                              .toList()
                            ..sort((a, b) =>
                                b.createdAt.compareTo(a.createdAt));

                          return _VendorBorrowCard(
                            vendor: vendor,
                            weOwe: weOwe,
                            theyOwe: theyOwe,
                            bricksWeOwe: bricksWeOwe,
                            bricksTheyOwe: bricksTheyOwe,
                            transactions: txns,
                            provider: provider,
                            fmt: fmt,
                            intFmt: intFmt,
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/borrows/new'),
            icon: const Icon(Icons.add),
            label: Text(provider.isKh ? 'ខ្ចីឥដ្ឋ' : 'Record'),
          ),
        );
      },
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;

  const _SummaryBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Per-vendor card ───────────────────────────────────────────────────────────

class _VendorBorrowCard extends StatefulWidget {
  final Vendor? vendor;
  final double weOwe;
  final double theyOwe;
  final int bricksWeOwe;
  final int bricksTheyOwe;
  final List<BorrowTransaction> transactions;
  final AppProvider provider;
  final NumberFormat fmt;
  final NumberFormat intFmt;

  const _VendorBorrowCard({
    required this.vendor,
    required this.weOwe,
    required this.theyOwe,
    required this.bricksWeOwe,
    required this.bricksTheyOwe,
    required this.transactions,
    required this.provider,
    required this.fmt,
    required this.intFmt,
  });

  @override
  State<_VendorBorrowCard> createState() => _VendorBorrowCardState();
}

class _VendorBorrowCardState extends State<_VendorBorrowCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final allSettled = widget.weOwe <= 0 && widget.theyOwe <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // ── Vendor header ─────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: allSettled
                          ? AppColors.success.withAlpha(20)
                          : AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      allSettled
                          ? Icons.check_circle_outline
                          : Icons.store_outlined,
                      color: allSettled
                          ? AppColors.success
                          : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vendor?.name ?? 'Unknown Vendor',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        // Show per-direction summary
                        if (widget.weOwe > 0)
                          Text(
                            'We owe: ${widget.intFmt.format(widget.bricksWeOwe)} bricks',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.warning),
                          ),
                        if (widget.theyOwe > 0)
                          Text(
                            'They owe us: ${widget.intFmt.format(widget.bricksTheyOwe)} bricks',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.forest),
                          ),
                        if (allSettled)
                          const Text('Settled',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.weOwe > 0)
                        Text(
                          '-\$${widget.fmt.format(widget.weOwe)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      if (widget.theyOwe > 0)
                        Text(
                          '+\$${widget.fmt.format(widget.theyOwe)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      Text(
                        '${widget.transactions.length} tx',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Transaction rows ──────────────────────────────────────
          if (_expanded)
            ...widget.transactions.map((t) {
              final bt = widget.provider.store.findBrickType(t.brickTypeId ?? '');
              String dateStr = t.createdAt;
              try {
                dateStr = DateFormat('dd/MM/yy HH:mm')
                    .format(DateTime.parse(t.createdAt));
              } catch (_) {}

              final (rowColor, borderColor, iconColor, icon, sign) =
                  switch (t.type) {
                BorrowType.borrowIn   => (AppColors.warning.withAlpha(10),  AppColors.warning.withAlpha(40),  AppColors.warning, Icons.arrow_downward_rounded, '+'),
                BorrowType.borrowOut  => (AppColors.success.withAlpha(10),  AppColors.success.withAlpha(40),  AppColors.success, Icons.arrow_upward_rounded,   '-'),
                BorrowType.lendOut    => (AppColors.forest.withAlpha(10),   AppColors.forest.withAlpha(40),   AppColors.forest,  Icons.north_east_rounded,      '+'),
                BorrowType.lendReturn => (AppColors.neutral.withAlpha(10),  AppColors.neutral.withAlpha(40),  AppColors.neutral, Icons.south_west_rounded,      '-'),
              };

              return Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: rowColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.type.label}  •  '
                            '${widget.intFmt.format(t.quantity)} bricks'
                            '${bt != null ? "  •  ${bt.name}" : ""}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text(
                      '$sign\$${widget.fmt.format(t.total)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: iconColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 16),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final ok = await showDeleteDialog(context,
                            itemName: 'transaction');
                        if (ok && context.mounted) {
                          await widget.provider.deleteBorrow(t.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
          if (_expanded) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

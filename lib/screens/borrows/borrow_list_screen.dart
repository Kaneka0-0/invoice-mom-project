import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class BorrowListScreen extends StatefulWidget {
  const BorrowListScreen({super.key});

  @override
  State<BorrowListScreen> createState() => _BorrowListScreenState();
}

class _BorrowListScreenState extends State<BorrowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final fmt = NumberFormat('#,##0.00');
        final intFmt = NumberFormat('#,###');
        final dateFmt = DateFormat('dd/MM/yyyy');

        final owed = provider.borrows
            .where((b) => b.status == BorrowStatus.owed)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final paid = provider.borrows
            .where((b) => b.status == BorrowStatus.paid)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final totalOwed = owed.fold<double>(0, (s, b) => s + b.totalAmount);
        final totalBricksOwed = owed.fold<int>(0, (s, b) => s + b.quantity);

        return Scaffold(
          appBar: AppBar(
            title: Text(s.borrows),
            bottom: TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: s.owed),
                Tab(text: s.paid),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
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
              // ── Summary bar ───────────────────────────────────────
              if (totalOwed > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: const Color(0xFFFFFBEB),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.isKh
                              ? 'ជំពាក់: \$${fmt.format(totalOwed)}  (${intFmt.format(totalBricksOwed)} ឥដ្ឋ)'
                              : 'Total Owed: \$${fmt.format(totalOwed)}  (${intFmt.format(totalBricksOwed)} bricks)',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Tab views ─────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _BorrowTab(
                      borrows: owed,
                      provider: provider,
                      fmt: fmt,
                      intFmt: intFmt,
                      dateFmt: dateFmt,
                      showMarkPaid: true,
                      emptyMsg: s.noBorrows,
                    ),
                    _BorrowTab(
                      borrows: paid,
                      provider: provider,
                      fmt: fmt,
                      intFmt: intFmt,
                      dateFmt: dateFmt,
                      showMarkPaid: false,
                      emptyMsg: provider.isKh
                          ? 'មិនទាន់មានការខ្ចីដែលបានបង់'
                          : 'No paid borrows yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/borrows/new'),
            icon: const Icon(Icons.add),
            label: Text(
                provider.isKh ? 'ខ្ចីឥដ្ឋ' : 'Record Borrow'),
          ),
        );
      },
    );
  }
}

class _BorrowTab extends StatelessWidget {
  final List<Borrow> borrows;
  final AppProvider provider;
  final NumberFormat fmt;
  final NumberFormat intFmt;
  final DateFormat dateFmt;
  final bool showMarkPaid;
  final String emptyMsg;

  const _BorrowTab({
    required this.borrows,
    required this.provider,
    required this.fmt,
    required this.intFmt,
    required this.dateFmt,
    required this.showMarkPaid,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (borrows.isEmpty) {
      return EmptyState(
        icon: Icons.swap_horiz_outlined,
        message: emptyMsg,
        actionLabel: provider.isKh ? 'ខ្ចីឥដ្ឋ' : 'Record Borrow',
        onAction: () => context.push('/borrows/new'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: borrows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final b = borrows[i];
        final vendor = provider.store.findVendor(b.vendorId);
        String dateStr = b.date;
        try {
          dateStr = dateFmt.format(DateTime.parse(b.date));
        } catch (_) {}

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: showMarkPaid
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            showMarkPaid
                                ? Icons.warning_amber
                                : Icons.check_circle,
                            size: 14,
                            color: showMarkPaid
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            showMarkPaid
                                ? (provider.isKh ? 'ជំពាក់' : 'Owed')
                                : (provider.isKh ? 'បានបង់' : 'Paid'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: showMarkPaid
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (vendor != null) ...[
                  InfoRow(
                    label: provider.s.vendor,
                    value: vendor.name,
                    valueStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                InfoRow(
                  label: provider.s.quantity,
                  value: '${intFmt.format(b.quantity)} bricks',
                ),
                InfoRow(
                  label: provider.s.unitPrice,
                  value: '\$${fmt.format(b.unitPrice)} / brick',
                ),
                InfoRow(
                  label: provider.s.amountOwed,
                  value: '\$${fmt.format(b.totalAmount)}',
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: showMarkPaid
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
                if (b.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InfoRow(label: provider.s.notes, value: b.notes),
                ],
                if (showMarkPaid) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline,
                            size: 16),
                        label: Text(provider.s.markPaid),
                        onPressed: () async {
                          await provider.markBorrowPaid(b.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.isKh
                                    ? 'សម្គាល់ថាបានបង់រួច'
                                    : 'Marked as paid'),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 18),
                        onPressed: () async {
                          final ok = await showDeleteDialog(
                              context,
                              itemName: 'Borrow record');
                          if (ok && context.mounted) {
                            await provider.deleteBorrow(b.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

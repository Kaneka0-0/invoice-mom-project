import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

// ── Worker Advances screen ────────────────────────────────────────────────────
// Records cash advances (borrows) given to workers and their repayments.

class WorkerAdvancesScreen extends StatelessWidget {
  const WorkerAdvancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final fmt    = NumberFormat('#,##0.00');
        final txns   = provider.workerTransactions
            .where((t) =>
                t.type == WorkerTransactionType.borrow ||
                t.type == WorkerTransactionType.repayment)
            .toList();

        // Workers that have at least one borrow/repayment transaction
        final workerIds = txns.map((t) => t.workerId).toSet().toList();

        // Total outstanding across all workers
        final totalOwed = workerIds.fold<double>(0, (sum, wId) {
          final workerTxns = txns.where((t) => t.workerId == wId);
          final borrows    = workerTxns.where((t) => t.type == WorkerTransactionType.borrow)
                                       .fold<double>(0, (s, t) => s + t.amount);
          final repaid     = workerTxns.where((t) => t.type == WorkerTransactionType.repayment)
                                       .fold<double>(0, (s, t) => s + t.amount);
          return sum + (borrows - repaid).clamp(0.0, double.infinity);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Worker Advances'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddSheet(context, provider),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // ── Summary banner ──────────────────────────────────────────
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
                          'Total Outstanding: \$${fmt.format(totalOwed)}',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Per-worker list ─────────────────────────────────────────
              Expanded(
                child: txns.isEmpty
                    ? EmptyState(
                        icon: Icons.payments_outlined,
                        message: 'No advances recorded',
                        actionLabel: 'Record Advance',
                        onAction: () => _showAddSheet(context, provider),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: workerIds.length,
                        itemBuilder: (ctx, i) {
                          final wId   = workerIds[i];
                          final worker = provider.store.findWorker(wId);
                          final wTxns = txns
                              .where((t) => t.workerId == wId)
                              .toList()
                            ..sort((a, b) =>
                                b.createdAt.compareTo(a.createdAt));
                          final borrowed = wTxns
                              .where((t) => t.type == WorkerTransactionType.borrow)
                              .fold<double>(0, (s, t) => s + t.amount);
                          final repaid = wTxns
                              .where((t) => t.type == WorkerTransactionType.repayment)
                              .fold<double>(0, (s, t) => s + t.amount);
                          final outstanding = (borrowed - repaid).clamp(0.0, double.infinity);

                          return _WorkerAdvanceCard(
                            worker: worker,
                            outstanding: outstanding,
                            transactions: wTxns,
                            provider: provider,
                            fmt: fmt,
                            onAddTap: () => _showAddSheet(context, provider, preselectedWorkerId: wId),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Record Advance'),
          ),
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, AppProvider provider,
      {String? preselectedWorkerId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddAdvanceSheet(
        provider: provider,
        preselectedWorkerId: preselectedWorkerId,
      ),
    );
  }
}

// ── Per-worker expandable card ────────────────────────────────────────────────

class _WorkerAdvanceCard extends StatefulWidget {
  final Worker? worker;
  final double outstanding;
  final List<WorkerTransaction> transactions;
  final AppProvider provider;
  final NumberFormat fmt;
  final VoidCallback onAddTap;

  const _WorkerAdvanceCard({
    required this.worker,
    required this.outstanding,
    required this.transactions,
    required this.provider,
    required this.fmt,
    required this.onAddTap,
  });

  @override
  State<_WorkerAdvanceCard> createState() => _WorkerAdvanceCardState();
}

class _WorkerAdvanceCardState extends State<_WorkerAdvanceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isSettled = widget.outstanding <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isSettled
                        ? AppColors.success.withAlpha(20)
                        : AppColors.warning.withAlpha(20),
                    child: Icon(
                      isSettled
                          ? Icons.check_circle_outline
                          : Icons.person_outline,
                      color: isSettled ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.worker?.name ?? 'Unknown Worker',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          isSettled
                              ? 'Settled'
                              : '${widget.transactions.length} transaction${widget.transactions.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSettled ? AppColors.success : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${widget.fmt.format(widget.outstanding)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSettled ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        'outstanding',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.forest, size: 20),
                    onPressed: widget.onAddTap,
                    tooltip: 'Add transaction',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Transaction rows ────────────────────────────────────────
          if (_expanded)
            ...widget.transactions.map((t) {
              final isBorrow = t.type == WorkerTransactionType.borrow;
              String dateStr = t.createdAt;
              try {
                dateStr = DateFormat('dd/MM/yy HH:mm')
                    .format(DateTime.parse(t.createdAt));
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBorrow
                      ? AppColors.warning.withAlpha(10)
                      : AppColors.success.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBorrow
                        ? AppColors.warning.withAlpha(40)
                        : AppColors.success.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBorrow
                          ? Icons.arrow_circle_down_outlined
                          : Icons.arrow_circle_up_outlined,
                      size: 18,
                      color: isBorrow ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBorrow ? 'Advance given' : 'Repayment received',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (t.notes.isNotEmpty)
                            Text(t.notes,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text(
                      '${isBorrow ? '-' : '+'}\$${widget.fmt.format(t.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isBorrow ? AppColors.warning : AppColors.success,
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
                          await widget.provider.deleteWorkerTransaction(t.id);
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

// ── Add advance bottom sheet ──────────────────────────────────────────────────

class _AddAdvanceSheet extends StatefulWidget {
  final AppProvider provider;
  final String? preselectedWorkerId;

  const _AddAdvanceSheet({
    required this.provider,
    this.preselectedWorkerId,
  });

  @override
  State<_AddAdvanceSheet> createState() => _AddAdvanceSheetState();
}

class _AddAdvanceSheetState extends State<_AddAdvanceSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  late String? _workerId;
  WorkerTransactionType _type = WorkerTransactionType.borrow;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _workerId = widget.preselectedWorkerId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Record Advance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Type toggle
            SegmentedButton<WorkerTransactionType>(
              segments: const [
                ButtonSegment(
                  value: WorkerTransactionType.borrow,
                  label: Text('Give Advance'),
                  icon: Icon(Icons.arrow_circle_down_outlined),
                ),
                ButtonSegment(
                  value: WorkerTransactionType.repayment,
                  label: Text('Repayment'),
                  icon: Icon(Icons.arrow_circle_up_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _type == WorkerTransactionType.borrow
                  ? 'Worker receives money in advance'
                  : 'Worker repays a previous advance',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),

            // Worker dropdown
            DropdownButtonFormField<String>(
              value: _workerId,
              decoration: const InputDecoration(
                labelText: 'Worker *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: provider.workers
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      ))
                  .toList(),
              validator: (v) => v == null ? 'Please select a worker' : null,
              onChanged: (v) => setState(() => _workerId = v),
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: provider.settings.currencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Reason for advance, etc.',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_type == WorkerTransactionType.borrow
                    ? 'Record Advance'
                    : 'Record Repayment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.provider.addWorkerTransaction(
        workerId: _workerId!,
        type: _type,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s        = provider.s;
        final store    = provider.store;
        final now      = DateTime.now();
        final ym       = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final monthInv = store.invoicesForMonth(ym);
        final revenue  = store.monthlyRevenue(ym);
        final pending  = store.pendingAmount();
        final owed     = store.totalOwedToVendors();
        final recent   = provider.invoices.take(5).toList();
        final sym      = provider.settings.currencySymbol;
        final fmt      = NumberFormat('#,##0.00');
        final monthFmt = DateFormat('MMMM yyyy').format(now);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: CustomScrollView(
            slivers: [
              // ── Hero header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  companyName:   provider.settings.companyName,
                  companyNameKh: provider.settings.companyNameKh,
                  monthLabel:    monthFmt,
                  isKh:          provider.isKh,
                  onLangTap:     provider.toggleLanguage,
                  onNewInvoice:  () => context.push('/invoices/new'),
                ),
              ),

              // ── Stats ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: s.thisMonth),
                      const SizedBox(height: 12),
                      _StatsRow(
                        invoiceCount: monthInv.length,
                        revenue: revenue,
                        pending: pending,
                        owed: owed,
                        sym: sym,
                        fmt: fmt,
                        s: s,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick actions ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _QuickActions(s: s),
                ),
              ),

              // ── Vendor debt alert ─────────────────────────────────────
              if (owed > 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _DebtBanner(
                      owed: owed,
                      sym: sym,
                      fmt: fmt,
                      isKh: provider.isKh,
                      onTap: () => context.go('/borrows'),
                    ),
                  ),
                ),

              // ── Recent invoices ───────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: s.recentInvoices,
                    trailing: TextButton(
                      onPressed: () => context.go('/invoices'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View all →',
                        style: GoogleFonts.inter(
                          color: AppColors.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (recent.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: s.noInvoices,
                      actionLabel: s.newInvoice,
                      onAction: () => context.push('/invoices/new'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: recent.asMap().entries.map((e) {
                          final i   = e.key;
                          final inv = e.value;
                          final isLast = i == recent.length - 1;
                          final client = store.findClient(inv.clientId);
                          return _InvoiceTile(
                            invoice:    inv,
                            clientName: client?.name ?? '—',
                            sym:        sym,
                            fmt:        fmt,
                            isKh:       provider.isKh,
                            isLast:     isLast,
                            onTap: () => context.push('/invoices/${inv.id}'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/invoices/new'),
            icon: const Icon(Icons.add, size: 20),
            label: Text(s.newInvoice,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            elevation: 2,
          ),
        );
      },
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String companyName;
  final String companyNameKh;
  final String monthLabel;
  final bool isKh;
  final VoidCallback onLangTap;
  final VoidCallback onNewInvoice;

  const _HeroHeader({
    required this.companyName,
    required this.companyNameKh,
    required this.monthLabel,
    required this.isKh,
    required this.onLangTap,
    required this.onNewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.forest),
      child: Stack(
        children: [
          // Brick pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: BrickPatternPainter(
                color: Colors.white,
                opacity: 0.055,
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: logo + lang toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text('🧱', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text(
                              'BRICK FACTORY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Lang toggle
                      GestureDetector(
                        onTap: onLangTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.language,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isKh ? 'ខ្មែរ' : 'EN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Company name
                  Text(
                    companyName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyNameKh,
                    style: GoogleFonts.battambang(
                      color: Colors.white.withAlpha(190),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Month chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int invoiceCount;
  final double revenue;
  final double pending;
  final double owed;
  final String sym;
  final NumberFormat fmt;
  final dynamic s;

  const _StatsRow({
    required this.invoiceCount,
    required this.revenue,
    required this.pending,
    required this.owed,
    required this.sym,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        label: s.totalInvoices,
        value: '$invoiceCount',
        icon: Icons.receipt_long_rounded,
        color: AppColors.forest,
      ),
      _StatData(
        label: s.totalRevenue,
        value: '$sym${fmt.format(revenue)}',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      _StatData(
        label: s.pendingAmount,
        value: '$sym${fmt.format(pending)}',
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
      ),
      _StatData(
        label: s.debtToVendors,
        value: '$sym${fmt.format(owed)}',
        icon: Icons.account_balance_wallet_outlined,
        color: owed > 0 ? AppColors.danger : AppColors.muted,
      ),
    ];

    return LayoutBuilder(builder: (ctx, box) {
      if (box.maxWidth > 500) {
        // 4-column row
        return Row(
          children: stats.map((d) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: d != stats.last ? 10 : 0),
              child: StatCard(
                label: d.label,
                value: d.value,
                icon: d.icon,
                color: d.color,
              ),
            ),
          )).toList(),
        );
      }
      // horizontal scroll row
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.only(right: e.key < stats.length - 1 ? 10 : 0),
            child: SizedBox(
              width: 150,
              child: StatCard(label: e.value.label, value: e.value.value, icon: e.value.icon, color: e.value.color),
            ),
          )).toList(),
        ),
      );
    });
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatData({required this.label, required this.value, required this.icon, required this.color});
}

// ── Quick actions ──────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final dynamic s;
  const _QuickActions({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionTile(
              icon: Icons.add_circle_rounded,
              label: 'New Invoice',
              color: AppColors.forest,
              onTap: () => context.push('/invoices/new'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.person_add_rounded,
              label: 'Add Client',
              color: AppColors.medium,
              onTap: () => context.push('/clients/new'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Borrow',
              color: AppColors.warning,
              onTap: () => context.push('/borrows/new'),
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ── Vendor debt banner ────────────────────────────────────────────────────────

class _DebtBanner extends StatelessWidget {
  final double owed;
  final String sym;
  final NumberFormat fmt;
  final bool isKh;
  final VoidCallback onTap;

  const _DebtBanner({
    required this.owed,
    required this.sym,
    required this.fmt,
    required this.isKh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isKh ? 'ជំពាក់អ្នកលក់' : 'Outstanding Vendor Debt',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$sym${fmt.format(owed)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.warning, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Invoice tile ──────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final String clientName;
  final String sym;
  final NumberFormat fmt;
  final bool isKh;
  final bool isLast;
  final VoidCallback onTap;

  const _InvoiceTile({
    required this.invoice,
    required this.clientName,
    required this.sym,
    required this.fmt,
    required this.isKh,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    String date = '';
    try { date = dateFmt.format(DateTime.parse(invoice.date)); } catch (_) {}

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isLast ? 14 : 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Status indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor(invoice.status.name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Number + client
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    clientName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              '$sym${fmt.format(invoice.total)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

const _kSidebarDark = Color(0xFF0B2218);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s       = provider.s;
        final store   = provider.store;
        final revenue = store.totalRevenue();
        final recent  = provider.invoices.take(8).toList();
        final sym     = provider.settings.currencySymbol;
        final fmt     = NumberFormat('#,##0.00');

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: RefreshIndicator(
            color: AppColors.forest,
            onRefresh: provider.reload,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PageHeader(
                    isKh: provider.isKh,
                    onLangTap: provider.toggleLanguage,
                    s: s,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StatCards(
                      invoiceCount: provider.invoices.length,
                      revenue: revenue,
                      sym: sym,
                      fmt: fmt,
                      s: s,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ClientsSection(
                      clients: provider.clients.take(3).toList(),
                      s: s,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
                  sliver: SliverToBoxAdapter(
                    child: _InvoiceGrid(
                      invoices: recent,
                      store: store,
                      sym: sym,
                      fmt: fmt,
                      s: s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/invoices/new'),
            backgroundColor: _kSidebarDark,
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

// ── Page header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final bool isKh;
  final VoidCallback onLangTap;
  final dynamic s;

  const _PageHeader({
    required this.isKh,
    required this.onLangTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Image.asset(
                            'assets/invoice-image/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        'Activities Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overview of your business metrics',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onLangTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kSidebarDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 5),
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Stat cards ─────────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final int invoiceCount;
  final double revenue;
  final String sym;
  final NumberFormat fmt;
  final dynamic s;

  const _StatCards({
    required this.invoiceCount,
    required this.revenue,
    required this.sym,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        label: s.totalInvoices,
        value: '$invoiceCount',
        icon: Icons.receipt_long_rounded,
      ),
      _CardData(
        label: s.totalRevenue,
        value: '$sym${fmt.format(revenue)}',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return LayoutBuilder(builder: (ctx, box) {
      if (box.maxWidth > 500) {
        return Row(
          children: cards.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: e.key < cards.length - 1 ? 14 : 0),
                child: _StatCard(data: e.value),
              ),
            );
          }).toList(),
        );
      }
      return Column(
        children: cards
            .map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatCard(data: d),
                ))
            .toList(),
      );
    });
  }
}

class _CardData {
  final String label;
  final String value;
  final IconData icon;
  const _CardData(
      {required this.label, required this.value, required this.icon});
}

class _StatCard extends StatelessWidget {
  final _CardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kSidebarDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kSidebarDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Clients section ───────────────────────────────────────────────────────────

class _ClientsSection extends StatelessWidget {
  final List<Client> clients;
  final dynamic s;

  const _ClientsSection({required this.clients, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.clients,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your registered clients',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/clients'),
              child: Text(
                'See all',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (clients.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(
                s.noClients,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: clients.asMap().entries.map((e) {
                final client = e.value;
                final isLast = e.key == clients.length - 1;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF0B2218).withAlpha(18),
                        child: Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF0B2218),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        client.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      subtitle: client.phone.isNotEmpty
                          ? Text(
                              client.phone,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.muted),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.muted, size: 18),
                      onTap: () => context.go('/clients'),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, indent: 64, color: Color(0xFFE5E7EB)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Invoice grid ──────────────────────────────────────────────────────────────

class _InvoiceGrid extends StatelessWidget {
  final List<Invoice> invoices;
  final dynamic store;
  final String sym;
  final NumberFormat fmt;
  final dynamic s;

  const _InvoiceGrid({
    required this.invoices,
    required this.store,
    required this.sym,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Status',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Recent invoices and their status',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: Text(
                'See all',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              message: s.noInvoices,
              actionLabel: s.newInvoice,
              onAction: () => context.push('/invoices/new'),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: invoices.asMap().entries.map((e) {
                final inv    = e.value;
                final isLast = e.key == invoices.length - 1;
                final client = store.findClient(inv.clientId);
                String date  = '';
                try { date = DateFormat('dd MMM yyyy').format(DateTime.parse(inv.date)); } catch (_) {}
                final total  = inv.items.fold(0.0, (s, i) => s + i.quantity * i.unitPrice);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0B2218).withAlpha(18),
                        child: Text(
                          (client?.name ?? inv.number).isNotEmpty
                              ? (client?.name ?? inv.number)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF0B2218),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        client?.name ?? '—',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${inv.number}  ·  $date',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$sym${fmt.format(total)}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text('${inv.items.length} item${inv.items.length != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                      onTap: () => context.push('/invoices/${inv.id}/edit'),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 64, color: Color(0xFFE5E7EB)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}



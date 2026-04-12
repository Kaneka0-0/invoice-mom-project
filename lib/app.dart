import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/invoices/invoice_list_screen.dart';
import 'screens/invoices/invoice_form_screen.dart';
import 'screens/invoices/invoice_view_screen.dart';
import 'screens/clients/client_list_screen.dart';
import 'screens/clients/client_form_screen.dart';
import 'screens/workers/worker_list_screen.dart';
import 'screens/workers/worker_form_screen.dart';
import 'screens/cars/car_list_screen.dart';
import 'screens/cars/car_form_screen.dart';
import 'screens/vendors/vendor_list_screen.dart';
import 'screens/vendors/vendor_form_screen.dart';
import 'screens/borrows/borrow_list_screen.dart';
import 'screens/borrows/borrow_form_screen.dart';
import 'screens/settings_screen.dart';

class PanhaApp extends StatelessWidget {
  const PanhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const Scaffold(
              backgroundColor: AppColors.canvas,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🧱', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    CircularProgressIndicator(
                      color: AppColors.forest,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return MaterialApp.router(
          title: 'Panha Invoice',
          theme: AppTheme.light,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(child: child, location: state.uri.toString()),
        routes: [
          GoRoute(path: '/',                   builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/invoices',            builder: (_, __) => const InvoiceListScreen()),
          GoRoute(path: '/invoices/new',        builder: (_, __) => const InvoiceFormScreen()),
          GoRoute(path: '/invoices/:id',        builder: (_, s) => InvoiceViewScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/invoices/:id/edit',   builder: (_, s) => InvoiceFormScreen(id: s.pathParameters['id'])),
          GoRoute(path: '/clients',             builder: (_, __) => const ClientListScreen()),
          GoRoute(path: '/clients/new',         builder: (_, __) => const ClientFormScreen()),
          GoRoute(path: '/clients/:id/edit',    builder: (_, s) => ClientFormScreen(id: s.pathParameters['id'])),
          GoRoute(path: '/workers',             builder: (_, __) => const WorkerListScreen()),
          GoRoute(path: '/workers/new',         builder: (_, __) => const WorkerFormScreen()),
          GoRoute(path: '/workers/:id/edit',    builder: (_, s) => WorkerFormScreen(id: s.pathParameters['id'])),
          GoRoute(path: '/cars',                builder: (_, __) => const CarListScreen()),
          GoRoute(path: '/cars/new',            builder: (_, __) => const CarFormScreen()),
          GoRoute(path: '/cars/:id/edit',       builder: (_, s) => CarFormScreen(id: s.pathParameters['id'])),
          GoRoute(path: '/vendors',             builder: (_, __) => const VendorListScreen()),
          GoRoute(path: '/vendors/new',         builder: (_, __) => const VendorFormScreen()),
          GoRoute(path: '/vendors/:id/edit',    builder: (_, s) => VendorFormScreen(id: s.pathParameters['id'])),
          GoRoute(path: '/borrows',             builder: (_, __) => const BorrowListScreen()),
          GoRoute(path: '/borrows/new',         builder: (_, __) => const BorrowFormScreen()),
          GoRoute(path: '/settings',            builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
}

// ─── Navigation items ─────────────────────────────────────────────────────────

const _navItems = [
  _NavItem(icon: Icons.grid_view_rounded,         activeIcon: Icons.grid_view_rounded,        label: 'Home',     path: '/'),
  _NavItem(icon: Icons.receipt_long_outlined,      activeIcon: Icons.receipt_long,             label: 'Invoices', path: '/invoices'),
  _NavItem(icon: Icons.people_outline,             activeIcon: Icons.people_rounded,           label: 'Clients',  path: '/clients'),
  _NavItem(icon: Icons.engineering_outlined,       activeIcon: Icons.engineering,              label: 'Workers',  path: '/workers'),
  _NavItem(icon: Icons.local_shipping_outlined,    activeIcon: Icons.local_shipping,           label: 'Cars',     path: '/cars'),
  _NavItem(icon: Icons.store_outlined,             activeIcon: Icons.store,                    label: 'Vendors',  path: '/vendors'),
  _NavItem(icon: Icons.swap_horiz_outlined,        activeIcon: Icons.swap_horiz,               label: 'Borrows',  path: '/borrows'),
  _NavItem(icon: Icons.settings_outlined,          activeIcon: Icons.settings,                 label: 'Settings', path: '/settings'),
];

// ─── App Shell ────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  int _idx() {
    for (int i = 0; i < _navItems.length; i++) {
      final p = _navItems[i].path;
      if (p == '/' ? location == '/' : location.startsWith(p)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final wide  = MediaQuery.of(context).size.width >= 720;
    final wider = MediaQuery.of(context).size.width >= 960;
    final idx   = _idx();

    if (wide) {
      return _DesktopShell(idx: idx, child: child, wider: wider);
    } else {
      return _MobileShell(idx: idx, child: child, location: location);
    }
  }
}

// ── Desktop shell ──────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final int idx;
  final Widget child;
  final bool wider;

  const _DesktopShell({required this.idx, required this.child, required this.wider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) => Scaffold(
        body: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────────────────
            Container(
              width: wider ? 220 : 72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    height: 64,
                    padding: EdgeInsets.symmetric(
                      horizontal: wider ? 16 : 0,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                    ),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: const _BrickMiniPainter(),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: wider
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Center(
                                    child: Text('🧱',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                if (wider) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Panha',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Brick Factory',
                                          style: GoogleFonts.inter(
                                            color:
                                                Colors.white.withAlpha(170),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nav items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: _navItems.asMap().entries.map((e) {
                          final i    = e.key;
                          final item = e.value;
                          final sel  = i == idx;
                          return _SidebarItem(
                            item: item,
                            selected: sel,
                            expanded: wider,
                            label: _navLabel(item.path, provider),
                            onTap: () => context.go(item.path),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Language + divider
                  const Divider(height: 1),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: _SidebarItem(
                      item: const _NavItem(
                        icon: Icons.language_outlined,
                        activeIcon: Icons.language,
                        label: 'Language',
                        path: '',
                      ),
                      selected: false,
                      expanded: wider,
                      label: provider.isKh ? 'ខ្មែរ / EN' : 'EN / KH',
                      onTap: provider.toggleLanguage,
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ───────────────────────────────────────────────────
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool expanded;
  final String label;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.pale : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 0,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: selected ? AppColors.forest : AppColors.muted,
                  size: 20,
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: selected ? AppColors.forest : AppColors.slate,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile shell ───────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final int idx;
  final Widget child;
  final String location;

  const _MobileShell(
      {required this.idx, required this.child, required this.location});

  // Bottom nav shows first 4 items + "More" (drawer)
  static const _bottomItems = [
    _NavItem(icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view_rounded,  label: 'Home',     path: '/'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,      label: 'Invoices', path: '/invoices'),
    _NavItem(icon: Icons.people_outline,        activeIcon: Icons.people_rounded,    label: 'Clients',  path: '/clients'),
    _NavItem(icon: Icons.engineering_outlined,  activeIcon: Icons.engineering,       label: 'Workers',  path: '/workers'),
  ];

  int _bottomIdx() {
    for (int i = 0; i < _bottomItems.length; i++) {
      final p = _bottomItems[i].path;
      if (p == '/' ? location == '/' : location.startsWith(p)) return i;
    }
    return -1; // "More" is selected
  }

  @override
  Widget build(BuildContext context) {
    final bIdx = _bottomIdx();

    return Consumer<AppProvider>(
      builder: (ctx, provider, _) => Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  ..._bottomItems.asMap().entries.map((e) {
                    final i    = e.key;
                    final item = e.value;
                    final sel  = i == bIdx;
                    return Expanded(
                      child: _BottomTab(
                        icon: item.icon,
                        activeIcon: item.activeIcon,
                        label: _navLabel(item.path, provider),
                        selected: sel,
                        onTap: () => context.go(item.path),
                      ),
                    );
                  }),
                  // More tab
                  Expanded(
                    child: _BottomTab(
                      icon: Icons.more_horiz,
                      activeIcon: Icons.more_horiz,
                      label: 'More',
                      selected: bIdx == -1,
                      onTap: () => _showMoreSheet(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'More',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              _navItems[4], // Cars
              _navItems[5], // Vendors
              _navItems[6], // Borrows
              _navItems[7], // Settings
            ].map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.pale,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon,
                        color: AppColors.forest, size: 18),
                  ),
                  title: Text(
                    _navLabel(item.path, provider),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.muted, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go(item.path);
                  },
                )),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.pale,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.language,
                    color: AppColors.forest, size: 18),
              ),
              title: Text(
                provider.isKh ? 'Switch to English' : 'ប្តូរទៅភាសាខ្មែរ',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(ctx);
                provider.toggleLanguage();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.pale : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.forest : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.forest : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _navLabel(String path, AppProvider p) {
  final s = p.s;
  return switch (path) {
    '/'         => s.dashboard,
    '/invoices' => s.invoices,
    '/clients'  => s.clients,
    '/workers'  => s.workers,
    '/cars'     => s.cars,
    '/vendors'  => s.vendors,
    '/borrows'  => s.borrows,
    '/settings' => s.settings,
    _           => 'More',
  };
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

// Tiny brick painter just for the sidebar logo area
class _BrickMiniPainter extends CustomPainter {
  const _BrickMiniPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..style = PaintingStyle.fill;
    const bW = 20.0, bH = 8.0, gH = 1.5, gV = 1.5;
    final rows = (size.height / (bH + gV)).ceil() + 1;
    final cols = (size.width  / (bW + gH)).ceil() + 2;
    for (int r = 0; r < rows; r++) {
      final off = r.isOdd ? (bW + gH) / 2 : 0.0;
      for (int c = -1; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * (bW + gH) - off, r * (bH + gV), bW, bH),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

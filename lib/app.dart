import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invoices/invoice_list_screen.dart';
import 'screens/invoices/invoice_form_screen.dart';
import 'screens/clients/client_list_screen.dart';
import 'screens/clients/client_form_screen.dart';
import 'screens/invoices/monthly_export_screen.dart';
import 'screens/settings_screen.dart';

// Notifies GoRouter to re-evaluate redirects whenever Supabase auth state changes.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

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

  static Page<dynamic> _fade(GoRouterState state, Widget child) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  static GoRouter get router => _router;
  static final _authNotifier = _AuthNotifier();
  static final _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin)  return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, s) => _fade(s, const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(path: '/',                   pageBuilder: (_, s) => _fade(s, const HomeScreen())),
          GoRoute(path: '/invoices',           pageBuilder: (_, s) => _fade(s, const InvoiceListScreen())),
          GoRoute(path: '/invoices/new',       pageBuilder: (_, s) => _fade(s, const InvoiceFormScreen())),
          GoRoute(path: '/invoices/:id/edit',  pageBuilder: (_, s) => _fade(s, InvoiceFormScreen(id: s.pathParameters['id']))),
          GoRoute(path: '/clients',            pageBuilder: (_, s) => _fade(s, const ClientListScreen())),
          GoRoute(path: '/clients/new',        pageBuilder: (_, s) => _fade(s, const ClientFormScreen())),
          GoRoute(path: '/clients/:id/edit',   pageBuilder: (_, s) => _fade(s, ClientFormScreen(id: s.pathParameters['id']))),
          GoRoute(path: '/export',             pageBuilder: (_, s) => _fade(s, const MonthlyExportScreen())),
          GoRoute(path: '/settings',           pageBuilder: (_, s) => _fade(s, const SettingsScreen())),
        ],
      ),
    ],
  );
}

// ─── Navigation items ─────────────────────────────────────────────────────────

const _navItems = [
  _NavItem(icon: Icons.grid_view_rounded,        activeIcon: Icons.grid_view_rounded,     label: 'Home',    path: '/'),
  _NavItem(icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,           label: 'Invoices', path: '/invoices'),
  _NavItem(icon: Icons.file_download_outlined,   activeIcon: Icons.file_download_rounded,  label: 'Export',  path: '/export'),
  _NavItem(icon: Icons.settings_outlined,        activeIcon: Icons.settings,               label: 'Settings', path: '/settings'),
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
    final wide  = MediaQuery.of(context).size.width >= 960;
    final idx   = _idx();

    if (wide) {
      return _DesktopShell(idx: idx, wider: true, child: child);
    } else {
      return _MobileShell(idx: idx, location: location, child: child);
    }
  }
}

// ── Desktop shell ──────────────────────────────────────────────────────────────

const _kSidebarBg   = Color(0xFF0B2218);
const _kSidebarText = Color(0xFFB0CFC2);
const _kSidebarHead = Color(0xFF4A7A62);

class _DesktopShell extends StatelessWidget {
  final int idx;
  final Widget child;
  final bool wider;

  const _DesktopShell(
      {required this.idx, required this.child, required this.wider});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) => Scaffold(
        body: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────────────────
            Container(
              width: wider ? 240 : 72,
              color: _kSidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          wider ? 24 : 12, 20, wider ? 24 : 12, 0),
                      child: Center(
                        child: Image.asset(
                          'assets/invoice-image/logo.png',
                          width: wider ? 120 : 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (wider)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                      child: Text(
                        'MAIN MENU',
                        style: GoogleFonts.inter(
                          color: _kSidebarHead,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  _DarkNavItem(
                    item: _navItems[0],
                    selected: idx == 0,
                    expanded: wider,
                    label: _navLabel(_navItems[0].path, provider),
                    onTap: () => context.go(_navItems[0].path),
                  ),
                  _DarkNavItem(
                    item: _navItems[1],
                    selected: idx == 1,
                    expanded: wider,
                    label: _navLabel(_navItems[1].path, provider),
                    onTap: () => context.go(_navItems[1].path),
                  ),
                  _DarkNavItem(
                    item: _navItems[2],
                    selected: idx == 2,
                    expanded: wider,
                    label: _navLabel(_navItems[2].path, provider),
                    onTap: () => context.go(_navItems[2].path),
                  ),
                  const SizedBox(height: 8),
                  if (wider)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Text(
                        'SETTINGS',
                        style: GoogleFonts.inter(
                          color: _kSidebarHead,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  _DarkNavItem(
                    item: _navItems[3],
                    selected: idx == 3,
                    expanded: wider,
                    label: _navLabel(_navItems[3].path, provider),
                    onTap: () => context.go(_navItems[3].path),
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Material(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: provider.toggleLanguage,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: wider ? 14 : 0,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: wider
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.language_outlined,
                                  color: _kSidebarText, size: 18),
                              if (wider) ...[
                                const SizedBox(width: 10),
                                Text(
                                  provider.isKh ? 'ខ្មែរ / EN' : 'EN / KH',
                                  style: GoogleFonts.inter(
                                    color: _kSidebarText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Material(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _confirmSignOut(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: wider ? 14 : 0,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: wider
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded,
                                  color: _kSidebarText, size: 18),
                              if (wider) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'Sign out',
                                  style: GoogleFonts.inter(
                                    color: _kSidebarText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

class _DarkNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool expanded;
  final String label;
  final VoidCallback onTap;

  const _DarkNavItem({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withAlpha(20),
          highlightColor: Colors.white.withAlpha(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 14 : 0,
              vertical: 11,
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: selected ? _kSidebarBg : _kSidebarText,
                  size: 18,
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: selected ? _kSidebarBg : _kSidebarText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

  int _bottomIdx() {
    for (int i = 0; i < _navItems.length; i++) {
      final p = _navItems[i].path;
      if (p == '/' ? location == '/' : location.startsWith(p)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bIdx = _bottomIdx();

    return Consumer<AppProvider>(
      builder: (ctx, provider, _) => Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: _kSidebarBg,
            border: Border(top: BorderSide(color: Color(0xFF162E21))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: _navItems.asMap().entries.map((e) {
                  final sel = e.key == bIdx;
                  return Expanded(
                    child: _BottomTab(
                      icon: e.value.icon,
                      activeIcon: e.value.activeIcon,
                      label: _navLabel(e.value.path, provider),
                      selected: sel,
                      onTap: () => context.go(e.value.path),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: selected ? Colors.white : _kSidebarText,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : _kSidebarText,
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
    '/export'   => s.monthlyExport,
    '/settings' => s.settings,
    _           => '',
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

Future<void> _confirmSignOut(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You will need to sign in again to use the app.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await Supabase.instance.client.auth.signOut();
  }
}

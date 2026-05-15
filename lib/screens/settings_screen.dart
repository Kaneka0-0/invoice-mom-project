import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey        = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _currencySymCtrl;
  late TextEditingController _invoicePhone1Ctrl;
  late TextEditingController _invoicePhone2Ctrl;
  bool _saving = false;
  bool _init   = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final s      = context.read<AppProvider>().settings;
      _nameCtrl          = TextEditingController(text: s.companyName);
      _addressCtrl       = TextEditingController(text: s.address);
      _phoneCtrl         = TextEditingController(text: s.phone);
      _emailCtrl         = TextEditingController(text: s.email);
      _priceCtrl         = TextEditingController(text: s.brickPriceDefault.toString());
      _capacityCtrl      = TextEditingController(text: s.carCapacity.toString());
      _currencySymCtrl   = TextEditingController(text: s.currencySymbol);
      _invoicePhone1Ctrl = TextEditingController(text: s.invoicePhone1);
      _invoicePhone2Ctrl = TextEditingController(text: s.invoicePhone2);
      _init = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _currencySymCtrl.dispose();
    _invoicePhone1Ctrl.dispose();
    _invoicePhone2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // ── Page header ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.settings,
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D1F17),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Company & invoice configuration',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Language ────────────────────────────────────
                      _SettingsCard(
                        icon: Icons.language_rounded,
                        title: s.language,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.isKh
                                        ? 'ភាសាខ្មែរ (Khmer)'
                                        : 'English',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D1F17),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to switch language',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: provider.isKh,
                              activeColor: const Color(0xFF0B2218),
                              onChanged: (_) => provider.toggleLanguage(),
                            ),
                            Text(
                              provider.isKh ? 'ខ្មែរ' : 'EN',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B2218)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Company info ────────────────────────────────
                      _SettingsCard(
                        icon: Icons.business_outlined,
                        title: s.companyInfo,
                        child: Column(
                          children: [
                            _Field(
                              controller: _nameCtrl,
                              label: '${s.companyName} *',
                              icon: Icons.store_outlined,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _addressCtrl,
                              label: s.address,
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Invoice defaults ─────────────────────────────
                      _SettingsCard(
                        icon: Icons.tune_rounded,
                        title: 'Invoice Defaults',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _priceCtrl,
                              decoration: InputDecoration(
                                labelText: s.defaultBrickPrice,
                                prefixText: '\$',
                                helperText: 'Default price per brick',
                                isDense: true,
                                prefixIcon: const Icon(
                                    Icons.monetization_on_outlined,
                                    size: 18,
                                    color: AppColors.muted),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'))
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _currencySymCtrl,
                              decoration: InputDecoration(
                                labelText: s.currency,
                                helperText: 'e.g.  \$  or  ៛',
                                isDense: true,
                                prefixIcon: const Icon(
                                    Icons.attach_money_rounded,
                                    size: 18,
                                    color: AppColors.muted),
                              ),
                              maxLength: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Monthly Invoice template ──────────────────────
                      _SettingsCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Monthly Invoice',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller contact shown on the PDF',
                              style: TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _invoicePhone1Ctrl,
                              label: 'Phone Number 1',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _invoicePhone2Ctrl,
                              label: 'Phone Number 2',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Save ─────────────────────────────────────────
                      FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _save(context, provider),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          s.save,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0B2218),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Sign out ──────────────────────────────────────
                      OutlinedButton.icon(
                        onPressed: () => _confirmSignOutDialog(context),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                              color: AppColors.danger.withAlpha(120)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = AppSettings(
        companyName:       _nameCtrl.text.trim(),
        address:           _addressCtrl.text.trim(),
        phone:             _phoneCtrl.text.trim(),
        email:             _emailCtrl.text.trim(),
        brickPriceDefault: double.tryParse(_priceCtrl.text) ?? 0.10,
        carCapacity:       int.tryParse(_capacityCtrl.text) ?? 30000,
        currencySymbol:    _currencySymCtrl.text.trim(),
        currency:          provider.settings.currency,
        nextInvoiceNum:    provider.settings.nextInvoiceNum,
        invoicePhone1:     _invoicePhone1Ctrl.text.trim(),
        invoicePhone2:     _invoicePhone2Ctrl.text.trim(),
      );
      await provider.saveSettings(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                provider.isKh ? 'រក្សាទុករួចហើយ' : 'Settings saved'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
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
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
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
                    color: const Color(0xFF0B2218).withAlpha(14),
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

// ── Reusable form field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines > 1
            ? Padding(
                padding: EdgeInsets.only(bottom: (maxLines - 1) * 20.0),
                child: Icon(icon, size: 18, color: AppColors.muted),
              )
            : Icon(icon, size: 18, color: AppColors.muted),
      ),
    );
  }
}

Future<void> _confirmSignOutDialog(BuildContext context) async {
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

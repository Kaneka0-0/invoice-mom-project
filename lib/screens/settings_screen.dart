import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _currencySymCtrl;
  bool _saving = false;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final s = context.read<AppProvider>().settings;
      _nameCtrl = TextEditingController(text: s.companyName);
      _addressCtrl = TextEditingController(text: s.address);
      _phoneCtrl = TextEditingController(text: s.phone);
      _emailCtrl = TextEditingController(text: s.email);
      _priceCtrl =
          TextEditingController(text: s.brickPriceDefault.toString());
      _capacityCtrl =
          TextEditingController(text: s.carCapacity.toString());
      _currencySymCtrl = TextEditingController(text: s.currencySymbol);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.settings),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: provider.isKh
                    ? 'Switch to English'
                    : 'ប្តូរទៅភាសាខ្មែរ',
                onPressed: provider.toggleLanguage,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Language toggle ─────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.language,
                            color: AppColors.forest),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.language,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                provider.isKh
                                    ? 'ភាសាខ្មែរ (Khmer)'
                                    : 'English',
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isKh,
                          activeThumbColor: AppColors.forest,
                          onChanged: (_) => provider.toggleLanguage(),
                        ),
                        Text(
                          provider.isKh ? 'ខ្មែរ' : 'KH',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Company info ────────────────────────────────────
                FormSection(
                  title: s.companyInfo,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          InputDecoration(labelText: '${s.companyName} *'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(labelText: s.address),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                          labelText: s.phone,
                          prefixIcon: const Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon:
                              const Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Invoice defaults ────────────────────────────────
                FormSection(
                  title:
                      'Invoice Defaults  •  ការកំណត់លំនាំដើម',
                  children: [
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: InputDecoration(
                        labelText: s.defaultBrickPrice,
                        prefixText: '\$',
                        helperText: 'Default price per brick',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _capacityCtrl,
                      decoration: InputDecoration(
                        labelText: s.carCapacity,
                        suffixText: 'bricks',
                        helperText: 'Bricks per delivery car',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _currencySymCtrl,
                      decoration: InputDecoration(
                        labelText: s.currency,
                        helperText: 'e.g.  \$  or  ៛',
                      ),
                      maxLength: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        _saving ? null : () => _save(context, provider),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(s.save),
                  ),
                ),
                const SizedBox(height: 32),

                // ── App info ────────────────────────────────────────
                const Divider(),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.pale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            color: AppColors.forest, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Panha Invoice v1.0',
                        style: const TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Brick Factory Management',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
        companyName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        brickPriceDefault:
            double.tryParse(_priceCtrl.text) ?? 0.10,
        carCapacity:
            int.tryParse(_capacityCtrl.text) ?? 30000,
        currencySymbol: _currencySymCtrl.text.trim(),
        currency: provider.settings.currency,
        nextInvoiceNum: provider.settings.nextInvoiceNum,
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

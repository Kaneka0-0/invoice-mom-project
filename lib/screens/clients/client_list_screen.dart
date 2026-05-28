import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  String _search = '';
  late final Stream<List<Client>> _clientsStream;

  @override
  void initState() {
    super.initState();
    _clientsStream = SupabaseSync.clientsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        return StreamBuilder<List<Client>>(
          stream: _clientsStream,
          builder: (context, snapshot) {
            // Merge stream + local provider so changes are instant:
            // delete: local removes first → filtered out immediately
            // add: local adds first → visible before stream catches up
            final List<Client> allClients;
            if (!snapshot.hasData) {
              allClients = provider.clients;
            } else {
              final streamList = snapshot.data!;
              final providerIds = {for (final c in provider.clients) c.id};
              allClients = [
                for (final sc in streamList)
                  if (providerIds.contains(sc.id)) sc,
                for (final lc in provider.clients)
                  if (!streamList.any((sc) => sc.id == lc.id)) lc,
              ];
            }

            final filtered = allClients
                .where((c) =>
                    _search.isEmpty ||
                    c.name.toLowerCase().contains(_search.toLowerCase()) ||
                    c.phone.contains(_search))
                .toList();

            return Scaffold(
          backgroundColor: const Color(0xFFF4F4F5),
          body: Column(
            children: [
              // ── Page header ──────────────────────────────────────────
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.clients,
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D1F17),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage your clients',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => showClientSheet(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B2218),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_add_outlined,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          decoration: InputDecoration(
                            hintText: s.search,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            fillColor: const Color(0xFFF4F4F5),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── List ────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.people_outlined,
                          message: s.noClients,
                          actionLabel: '${s.add} ${s.clients}',
                          onAction: () => showClientSheet(context),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = filtered[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF0B2218).withAlpha(14),
                                child: Text(
                                  c.name.isNotEmpty
                                      ? c.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Color(0xFF0B2218),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D1F17))),
                              subtitle: Builder(builder: (ctx) {
                                final locs = provider.locationsForClient(c.id);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (c.phone.isNotEmpty)
                                      Text(c.phone,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted)),
                                    if (locs.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: locs.map((l) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0B2218).withAlpha(10),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.location_on_outlined,
                                                    size: 10,
                                                    color: Color(0xFF0B2218)),
                                                const SizedBox(width: 3),
                                                Text(l.name,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF0B2218))),
                                              ],
                                            ),
                                          )).toList(),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                              isThreeLine: false,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Color(0xFF0B2218)),
                                    onPressed: () => showClientSheet(
                                        context,
                                        id: c.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.danger),
                                    onPressed: () => _handleDelete(context, provider, c),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showClientSheet(context),
            backgroundColor: const Color(0xFF0B2218),
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_add),
          ),
        );
          },
        );
      },
    );
  }

  Future<void> _handleDelete(
      BuildContext context, AppProvider provider, Client c) async {
    final linked =
        provider.invoices.where((i) => i.clientId == c.id).toList();

    if (linked.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => _LinkedInvoicesDialog(client: c),
      );
      return;
    }

    final ok = await showDeleteDialog(context, itemName: 'Client');
    if (!ok || !context.mounted) return;
    try {
      await provider.deleteClient(c.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete client. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Dialog shown when client has linked invoices ──────────────────────────────

class _LinkedInvoicesDialog extends StatefulWidget {
  final Client client;
  const _LinkedInvoicesDialog({required this.client});

  @override
  State<_LinkedInvoicesDialog> createState() => _LinkedInvoicesDialogState();
}

class _LinkedInvoicesDialogState extends State<_LinkedInvoicesDialog> {
  bool _deleting = false;

  static const _dark   = Color(0xFF0B2218);
  static const _danger = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final invoices = provider.invoices
            .where((i) => i.clientId == widget.client.id)
            .toList();

        // All invoices cleared — show a "now delete client" state
        if (invoices.isEmpty) {
          return AlertDialog(
            title: const Text('All invoices deleted'),
            content: Text(
                'All invoices for ${widget.client.name} have been removed.\n'
                'You can now delete the client.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _danger, foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    await provider.deleteClient(widget.client.id);
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Failed to delete client. Try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete Client'),
              ),
            ],
          );
        }

        return AlertDialog(
          titlePadding:
              const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding:
              const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: _danger, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.client.name} has '
                  '${invoices.length} invoice'
                  '${invoices.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete the invoices below first, or tap "Delete All" to remove everything at once.',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final inv = invoices[i];
                      final label = inv.number.isNotEmpty
                          ? inv.number
                          : 'No number';
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _dark.withAlpha(12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                              Icons.receipt_outlined,
                              size: 16,
                              color: _dark),
                        ),
                        title: Text(label,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(inv.date,
                            style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: _danger, size: 18),
                          tooltip: 'Delete invoice',
                          onPressed: () async {
                            await provider.deleteInvoice(inv.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: _deleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_sweep_outlined, size: 16),
              label: Text(_deleting
                  ? 'Deleting…'
                  : 'Delete All (${invoices.length}) & Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _deleting
                  ? null
                  : () async {
                      setState(() => _deleting = true);
                      try {
                        for (final inv in List.of(invoices)) {
                          await provider.deleteInvoice(inv.id);
                        }
                        await provider.deleteClient(widget.client.id);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        setState(() => _deleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to delete. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}

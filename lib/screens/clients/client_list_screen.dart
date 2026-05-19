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
            final filtered = (snapshot.data ?? provider.clients)
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
                                    onPressed: () async {
                                      final ok = await showDeleteDialog(
                                          context,
                                          itemName: 'Client');
                                      if (ok && context.mounted) {
                                        await provider.deleteClient(c.id);
                                      }
                                    },
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
}

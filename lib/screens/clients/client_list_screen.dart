import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final filtered = provider.clients
            .where((c) =>
                _search.isEmpty ||
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                c.phone.contains(_search))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(s.clients),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => context.push('/clients/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outlined,
                        message: s.noClients,
                        actionLabel: '${s.add} ${s.clients}',
                        onAction: () => context.push('/clients/new'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (ctx, i) {
                          final c = filtered[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.pale,
                                child: Text(
                                  c.name.isNotEmpty
                                      ? c.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.forest,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (c.phone.isNotEmpty)
                                    Text(c.phone,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted)),
                                  if (c.address.isNotEmpty)
                                    Text(c.address,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () => context.push(
                                        '/clients/${c.id}/edit'),
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
            onPressed: () => context.push('/clients/new'),
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }
}

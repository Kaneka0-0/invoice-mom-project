import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../models/models.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class WorkerListScreen extends StatelessWidget {
  const WorkerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final workers = provider.workers;

        IconData roleIcon(WorkerRole role) => switch (role) {
              WorkerRole.driver => Icons.drive_eta,
              WorkerRole.loader => Icons.person_outline,
              WorkerRole.supervisor => Icons.manage_accounts,
              WorkerRole.other => Icons.engineering,
            };

        return Scaffold(
          appBar: AppBar(
            title: Text(s.workers),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => context.push('/workers/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: workers.isEmpty
              ? EmptyState(
                  icon: Icons.engineering_outlined,
                  message: s.noWorkers,
                  actionLabel: '${s.add} ${s.workers}',
                  onAction: () => context.push('/workers/new'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final w = workers[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.pale,
                          child: Icon(roleIcon(w.role),
                              color: AppColors.forest, size: 20),
                        ),
                        title: Text(w.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.role.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted),
                            ),
                            if (w.phone.isNotEmpty)
                              Text(w.phone,
                                  style: const TextStyle(
                                      fontSize: 12,
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
                              onPressed: () =>
                                  context.push('/workers/${w.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () async {
                                final ok = await showDeleteDialog(
                                    context,
                                    itemName: 'Worker');
                                if (ok && context.mounted) {
                                  await provider.deleteWorker(w.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/workers/new'),
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }
}

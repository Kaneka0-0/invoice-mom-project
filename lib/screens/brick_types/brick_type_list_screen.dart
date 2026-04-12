import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class BrickTypeListScreen extends StatelessWidget {
  const BrickTypeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final types = provider.brickTypes;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Brick Types'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/brick-types/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: types.isEmpty
              ? EmptyState(
                  icon: Icons.category_outlined,
                  message: 'No brick types yet',
                  actionLabel: 'Add Brick Type',
                  onAction: () => context.push('/brick-types/new'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: types.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final bt = types[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.pale,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.category,
                              color: AppColors.forest, size: 20),
                        ),
                        title: Text(bt.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: bt.description.isNotEmpty
                            ? Text(bt.description,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  context.push('/brick-types/${bt.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () async {
                                final ok = await showDeleteDialog(context,
                                    itemName: 'Brick Type');
                                if (ok && context.mounted) {
                                  await provider.deleteBrickType(bt.id);
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
            onPressed: () => context.push('/brick-types/new'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

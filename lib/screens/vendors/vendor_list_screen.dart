import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class VendorListScreen extends StatelessWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final vendors = provider.vendors;
        final fmt = NumberFormat('#,##0.00');

        return Scaffold(
          appBar: AppBar(
            title: Text(s.vendors),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/vendors/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: vendors.isEmpty
              ? EmptyState(
                  icon: Icons.store_outlined,
                  message: s.noVendors,
                  actionLabel: '${s.add} ${s.vendors}',
                  onAction: () => context.push('/vendors/new'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: vendors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final v = vendors[i];
                    final owed = provider.store.totalOwedToVendor(v.id);
                    final brickCount =
                        provider.store.totalBricksOwedToVendor(v.id);
                    final intFmt = NumberFormat('#,###');

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: owed > 0
                              ? const Color(0xFFFFFBEB)
                              : AppColors.pale,
                          child: Icon(
                            Icons.store,
                            color: owed > 0
                                ? AppColors.warning
                                : AppColors.forest,
                            size: 20,
                          ),
                        ),
                        title: Text(v.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (v.phone.isNotEmpty)
                              Text(v.phone,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted)),
                            if (owed > 0)
                              Text(
                                'Owed: \$${fmt.format(owed)}  (${intFmt.format(brickCount)} bricks)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                                  context.push('/vendors/${v.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () async {
                                final ok = await showDeleteDialog(
                                    context, itemName: 'Vendor');
                                if (ok && context.mounted) {
                                  await provider.deleteVendor(v.id);
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
            onPressed: () => context.push('/vendors/new'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

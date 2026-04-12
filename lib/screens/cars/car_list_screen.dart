import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme.dart';
import '../../../widgets/common_widgets.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final s = provider.s;
        final cars = provider.cars;
        final intFmt = NumberFormat('#,###');

        return Scaffold(
          appBar: AppBar(
            title: Text(s.cars),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/cars/new'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: cars.isEmpty
              ? EmptyState(
                  icon: Icons.local_shipping_outlined,
                  message: s.noCars,
                  actionLabel: '${s.add} ${s.cars}',
                  onAction: () => context.push('/cars/new'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cars.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final car = cars[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.pale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.local_shipping,
                                color: AppColors.forest, size: 22),
                          ),
                        ),
                        title: Text(car.plateNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.capacity}: ${intFmt.format(car.capacity)} bricks',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                            if (car.description.isNotEmpty)
                              Text(car.description,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted)),
                          ],
                        ),
                        isThreeLine: car.description.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18),
                              onPressed: () =>
                                  context.push('/cars/${car.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () async {
                                final ok = await showDeleteDialog(
                                    context, itemName: 'Car');
                                if (ok && context.mounted) {
                                  await provider.deleteCar(car.id);
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
            onPressed: () => context.push('/cars/new'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

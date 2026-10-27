import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/promotion_viewmodel.dart';

import '../shared/app_drawer.dart';
import 'promotion_form_screen.dart';

class PromotionManagementScreen extends ConsumerWidget {
  const PromotionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promotionViewModelProvider);
    final vm = ref.read(promotionViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khuyến mãi'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: vm.loadPromotions,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.promotions.isEmpty
                ? const Center(child: Text('Chưa có mã khuyến mãi nào.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.promotions.length,
                    itemBuilder: (context, index) {
                      final p = state.promotions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('-${p.discountPercent}%'),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.description != null && p.description!.isNotEmpty)
                                Text(p.description!),
                              Text('Tối đa: ${Formatters.currency(p.maxDiscount)} | Số lượng còn: ${p.quantity}'),
                              Text('Áp dụng: ${Formatters.dateString(p.startDate)} - ${Formatters.dateString(p.endDate)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: p.isActive,
                                onChanged: (_) => vm.toggleActive(p.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PromotionFormScreen(promo: p),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PromotionFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

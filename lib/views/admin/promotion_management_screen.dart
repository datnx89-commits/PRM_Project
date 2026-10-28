import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/promotion_viewmodel.dart';

import '../shared/app_drawer.dart';
import 'promotion_form_screen.dart';

class PromotionManagementScreen extends ConsumerWidget {
  const PromotionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promotionViewModelProvider);
    final vm = ref.read(promotionViewModelProvider.notifier);
    final currentUser = ref.watch(authViewModelProvider).user;
    final isAdmin = currentUser?.role == 'Admin' || currentUser?.role == 'SuperAdmin';
    final isOwnerOrStaff = currentUser?.role == 'Owner' || currentUser?.role == 'Staff';

    // Lọc danh sách khuyến mãi:
    // Admin thấy tất cả.
    // Owner/Staff thấy mã của sân mình + mã toàn hệ thống.
    final displayedPromos = state.promotions.where((p) {
      if (isAdmin) return true;
      if (isOwnerOrStaff) {
        return p.ownerId == currentUser?.id || p.ownerId == null || p.ownerId!.isEmpty;
      }
      return p.ownerId == null || p.ownerId!.isEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Quản lý khuyến mãi hệ thống' : 'Khuyến mãi & Ưu đãi sân'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: vm.loadPromotions,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayedPromos.isEmpty
                ? const Center(child: Text('Chưa có mã khuyến mãi nào.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayedPromos.length,
                    itemBuilder: (context, index) {
                      final p = displayedPromos[index];
                      final isOwnerPromo = p.ownerId == currentUser?.id;
                      final isSystemPromo = p.ownerId == null || p.ownerId!.isEmpty;
                      final canEdit = isAdmin || isOwnerPromo;

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
                              const SizedBox(width: 6),
                              if (isSystemPromo)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Hệ thống',
                                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else if (isOwnerPromo)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Sân của bạn',
                                    style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Chủ sân',
                                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                                  ),
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
                                onChanged: canEdit ? (_) => vm.toggleActive(p.id) : null,
                              ),
                              if (canEdit)
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

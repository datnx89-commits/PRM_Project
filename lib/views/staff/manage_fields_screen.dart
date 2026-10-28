import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/field_manage_viewmodel.dart';
import '../shared/app_drawer.dart';
import 'field_form_screen.dart';
import 'field_pricing_screen.dart';

class ManageFieldsScreen extends ConsumerWidget {
  const ManageFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldManageViewModelProvider);
    final vm = ref.read(fieldManageViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sân bóng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: vm.loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: vm.loadData,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.fields.isEmpty
                ? const Center(child: Text('Chưa có sân nào được tạo.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.fields.length,
                    itemBuilder: (context, index) {
                      final f = state.fields[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: f.status == FieldStatus.maintenance
                                ? Colors.deepOrange.shade300
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      f.fieldName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  _buildStatusChip(f.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${f.address}, ${f.district}, ${f.city}', style: TextStyle(color: Colors.grey.shade700)),
                              const SizedBox(height: 2),
                              Text(
                                'Giá thường: ${Formatters.currency(f.pricePerHour)}/h | Cao điểm: ${Formatters.currency(f.peakPricePerHour)}/h',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: f.acceptWalletPayment ? Colors.teal.shade50 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      f.acceptWalletPayment ? 'Ví điện tử: Nhận' : 'Ví điện tử: Tắt',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: f.acceptWalletPayment ? Colors.teal.shade800 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  if (f.cashbackPercent > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Cashback: ${f.cashbackPercent.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.price_change_outlined, color: Colors.teal),
                                    label: const Text('Giá & Khung giờ', style: TextStyle(color: Colors.teal)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FieldPricingScreen(field: f),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Sửa thông tin sân',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FieldFormScreen(field: f),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Xóa sân',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Xác nhận'),
                                          content: const Text('Bạn có muốn xóa hoặc đóng sân này?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final (ok, msg) = await vm.deleteOrClose(f.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FieldFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case FieldStatus.active:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Đang hoạt động';
        break;
      case FieldStatus.maintenance:
        bg = Colors.deepOrange.shade50;
        fg = Colors.deepOrange.shade800;
        label = 'Bảo trì';
        break;
      case FieldStatus.closed:
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = 'Đóng sân';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

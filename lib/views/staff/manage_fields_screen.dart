import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/field_manage_viewmodel.dart';

import '../shared/app_drawer.dart';
import 'field_form_screen.dart';

class ManageFieldsScreen extends ConsumerWidget {
  const ManageFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldManageViewModelProvider);
    final vm = ref.read(fieldManageViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sân bóng'),
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
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(f.fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${f.address}, ${f.district}, ${f.city}'),
                              Text('Giá thường: ${Formatters.currency(f.pricePerHour)}/h | Cao điểm: ${Formatters.currency(f.peakPricePerHour)}/h'),
                              Text('Trạng thái: ${f.status}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
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
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
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
}

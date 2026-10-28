import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/field_list_viewmodel.dart';
import '../shared/app_drawer.dart';
import 'field_detail_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldListViewModelProvider);
    final vm = ref.read(fieldListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống đặt sân SportsBook'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên sân, địa chỉ...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: vm.setKeyword,
                        onSubmitted: (_) => vm.search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: vm.search,
                      child: const Text('Tìm'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Loại sân',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: state.selectedFieldTypeId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả loại sân')),
                          ...state.fieldTypes.map(
                            (t) => DropdownMenuItem(value: t.id, child: Text(t.typeName)),
                          ),
                        ],
                        onChanged: vm.setFieldType,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Thành phố',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: state.selectedCity,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả TP')),
                          ...state.cities.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: vm.setCity,
                      ),
                    ),
                  ],
                ),
                if (state.keyword.isNotEmpty ||
                    state.selectedFieldTypeId != null ||
                    state.selectedCity != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _searchController.clear();
                        vm.resetFilters();
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.fields.isEmpty
                    ? const Center(child: Text('Không tìm thấy sân nào.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: state.fields.length,
                        itemBuilder: (context, index) {
                          final f = state.fields[index];
                          final isMaintenance = f.status == FieldStatus.maintenance;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isMaintenance ? Colors.deepOrange.shade300 : Colors.grey.shade200,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FieldDetailScreen(fieldId: f.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMaintenance)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Bảo trì',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${f.address}, ${f.district}, ${f.city}', style: TextStyle(color: Colors.grey.shade700)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (f.acceptWalletPayment)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Nhận Ví',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
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
                                              'Hoàn ${f.cashbackPercent.toInt()}%',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(f.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Từ ${Formatters.currency(f.pricePerHour)}/h',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const Row(
                                          children: [
                                            Text('Chi tiết', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                            Icon(Icons.chevron_right, size: 18, color: Colors.teal),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Hệ thống đặt sân'),
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
                        itemCount: state.fields.length,
                        itemBuilder: (context, index) {
                          final f = state.fields[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                f.fieldName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${f.address}, ${f.district}, ${f.city}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Từ ${Formatters.currency(f.pricePerHour)}/h',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(f.averageRating.toStringAsFixed(1)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FieldDetailScreen(fieldId: f.id),
                                  ),
                                );
                              },
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

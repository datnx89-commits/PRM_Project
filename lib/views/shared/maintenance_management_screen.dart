import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/field_model.dart';
import '../../data/models/maintenance_request_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'app_drawer.dart';

class MaintenanceManagementScreen extends ConsumerStatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  ConsumerState<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends ConsumerState<MaintenanceManagementScreen> {
  List<MaintenanceRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final maintRepo = ref.read(maintenanceRepositoryProvider);
    final isAdmin = user.role == UserRole.admin;

    final list = isAdmin
        ? await maintRepo.getAllForAdmin()
        : await maintRepo.getByOwner(user.id);

    if (mounted) {
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateRequestDialog() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final fieldRepo = ref.read(fieldRepositoryProvider);
    final allFields = await fieldRepo.searchFields();
    final myFields = allFields.where((f) => f.ownerId == user.id).toList();

    if (myFields.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa có sân bóng nào để yêu cầu bảo trì.')),
        );
      }
      return;
    }

    FieldModel selectedField = myFields.first;
    final reasonController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 3));

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
            final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

            return AlertDialog(
              title: const Text('Yêu cầu bảo trì sân'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn sân bóng:'),
                    DropdownButton<FieldModel>(
                      isExpanded: true,
                      value: selectedField,
                      items: myFields.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.fieldName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedField = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Lý do bảo trì:'),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: 'VD: Thay mặt cỏ nhân tạo, nâng cấp dàn đèn',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Từ ngày: $startStr'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) endDate = startDate;
                              });
                            }
                          },
                          child: const Text('Chọn'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đến ngày: $endStr'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setModalState(() => endDate = picked);
                            }
                          },
                          child: const Text('Chọn'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập lý do bảo trì')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final (ok, msg) = await ref.read(maintenanceRepositoryProvider).createRequest(
                          ownerId: user.id,
                          ownerName: user.fullName,
                          fieldId: selectedField.id,
                          fieldName: selectedField.fieldName,
                          reason: reasonController.text.trim(),
                          startDate: startStr,
                          endDate: endStr,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      _loadData();
                    }
                  },
                  child: const Text('Gửi yêu cầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processRequest(MaintenanceRequestModel req, bool isApprove) async {
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isApprove ? 'Duyệt yêu cầu bảo trì' : 'Từ chối yêu cầu bảo trì'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? 'LƯU Ý: Duyệt bảo trì sẽ tự động hủy toàn bộ đơn đặt trùng lịch trong khoảng ${req.startDate} đến ${req.endDate} và hoàn tiền lại cho khách hàng.'
                    : 'Nhập lý do từ chối yêu cầu:',
                style: TextStyle(
                  color: isApprove ? Colors.orange.shade900 : Colors.black87,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú của Admin',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final maintRepo = ref.read(maintenanceRepositoryProvider);
                final (ok, msg) = isApprove
                    ? await maintRepo.approveRequest(req.id, noteController.text.trim())
                    : await maintRepo.rejectRequest(req.id, noteController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  _loadData();
                }
              },
              child: Text(isApprove ? 'Xác nhận duyệt' : 'Xác nhận từ chối'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Duyệt bảo trì sân' : 'Yêu cầu bảo trì sân'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCreateRequestDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yêu cầu bảo trì'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Chưa có yêu cầu bảo trì nào.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final req = _requests[i];
                      Color statusColor = Colors.orange;
                      if (req.isApproved) statusColor = Colors.green;
                      if (req.isRejected) statusColor = Colors.red;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    req.fieldName ?? 'Sân bóng',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Thời gian: Từ ${req.startDate} đến ${req.endDate}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Lý do: ${req.reason}'),
                              if (req.ownerName != null) ...[
                                const SizedBox(height: 4),
                                Text('Chủ sân: ${req.ownerName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                              if (req.adminNote != null && req.adminNote!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Ghi chú Admin: ${req.adminNote}', style: const TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic, fontSize: 12)),
                              ],
                              if (isAdmin && req.isPending) ...[
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => _processRequest(req, false),
                                      child: const Text('Từ chối'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      onPressed: () => _processRequest(req, true),
                                      child: const Text('Duyệt bảo trì'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

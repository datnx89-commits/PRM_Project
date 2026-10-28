import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_manage_viewmodel.dart';
import '../shared/app_drawer.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Future<void> _openAdjustWalletDialog(UserModel user) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isAdd = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('Điều chỉnh ví: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số dư hiện tại: ${_currencyFormat.format(user.walletBalance)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('+ Cộng tiền'),
                      selected: isAdd,
                      onSelected: (val) => setDState(() => isAdd = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('- Trừ tiền'),
                      selected: !isAdd,
                      onSelected: (val) => setDState(() => isAdd = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do điều chỉnh (bắt buộc) *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isAdd ? Colors.teal : Colors.red),
              onPressed: () {
                if (amountCtrl.text.trim().isEmpty || reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ số tiền và lý do.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(isAdd ? 'Xác nhận cộng' : 'Xác nhận trừ'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
      final finalAmount = isAdd ? amount : -amount;
      final vm = ref.read(userManageViewModelProvider.notifier);
      final (ok, msg) = await vm.adjustWallet(
        userId: user.id,
        amount: finalAmount,
        reason: reasonCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAdjustPointsDialog(UserModel user) async {
    final pointsCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isAdd = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('Điều chỉnh điểm: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm hiện có: ${user.points} | Trọn đời: ${user.lifetimePoints}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('+ Cộng điểm'),
                      selected: isAdd,
                      onSelected: (val) => setDState(() => isAdd = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('- Trừ điểm'),
                      selected: !isAdd,
                      onSelected: (val) => setDState(() => isAdd = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số điểm *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do điều chỉnh (bắt buộc) *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isAdd ? Colors.amber.shade700 : Colors.red),
              onPressed: () {
                if (pointsCtrl.text.trim().isEmpty || reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đủ số điểm và lý do.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(isAdd ? 'Xác nhận cộng' : 'Xác nhận trừ'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
      final finalPts = isAdd ? pts : -pts;
      final vm = ref.read(userManageViewModelProvider.notifier);
      final (ok, msg) = await vm.adjustPoints(
        userId: user.id,
        points: finalPts,
        reason: reasonCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManageViewModelProvider);
    final vm = ref.read(userManageViewModelProvider.notifier);
    final currentUser = ref.watch(authViewModelProvider).user;
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuperAdmin ? 'Cứu hộ hệ thống (Super Admin)' : 'Quản lý người dùng'),
        backgroundColor: isSuperAdmin ? Colors.deepOrange.shade800 : null,
        foregroundColor: isSuperAdmin ? Colors.white : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.loadUsers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (isSuperAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.shade100,
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.deepOrange, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chế độ cứu hộ khẩn cấp: Khôi phục quyền Admin, mở khóa tài khoản hoặc điều chỉnh số dư ví/điểm.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.loadUsers,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.users.isEmpty
                      ? const Center(child: Text('Không có người dùng nào.'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final u = state.users[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: u.isActive ? Colors.grey.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: u.isActive ? Colors.teal : Colors.grey,
                                    foregroundColor: Colors.white,
                                    child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                u.tier,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(u.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        if (u.phone != null && u.phone!.isNotEmpty)
                                          Text('SĐT: ${u.phone}', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: u.isActive,
                                    activeThumbColor: Colors.teal,
                                    inactiveThumbColor: Colors.red,
                                    onChanged: (_) => vm.toggleActive(u.id),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ví: ${_currencyFormat.format(u.walletBalance)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
                                        Text('Điểm: ${u.points} (Trọn đời: ${u.lifetimePoints})', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: (u.role == UserRole.owner || u.role == UserRole.staff)
                                        ? UserRole.owner
                                        : (u.role == UserRole.admin || u.role == UserRole.superAdmin)
                                            ? UserRole.admin
                                            : UserRole.customer,
                                    items: const [
                                      DropdownMenuItem(value: UserRole.customer, child: Text('Khách hàng')),
                                      DropdownMenuItem(value: UserRole.owner, child: Text('Chủ sân (Owner)')),
                                      DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                                    ],
                                    onChanged: (newRole) {
                                      if (newRole != null && newRole != u.role) {
                                        vm.changeRole(u.id, newRole);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.account_balance_wallet, size: 16, color: Colors.teal),
                                    label: const Text('Sửa Ví', style: TextStyle(color: Colors.teal, fontSize: 12)),
                                    onPressed: () => _openAdjustWalletDialog(u),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.stars, size: 16, color: Colors.amber),
                                    label: const Text('Sửa Điểm', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                    onPressed: () => _openAdjustPointsDialog(u),
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
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/user_manage_viewmodel.dart';

import '../shared/app_drawer.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userManageViewModelProvider);
    final vm = ref.read(userManageViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
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
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(u.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (u.phone != null)
                                      Text('SĐT: ${u.phone}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              DropdownButton<String>(
                                value: u.role,
                                items: const [
                                  DropdownMenuItem(value: UserRole.customer, child: Text('Customer')),
                                  DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
                                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                                ],
                                onChanged: (newRole) {
                                  if (newRole != null && newRole != u.role) {
                                    vm.changeRole(u.id, newRole);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: u.isActive,
                                onChanged: (_) => vm.toggleActive(u.id),
                              ),
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

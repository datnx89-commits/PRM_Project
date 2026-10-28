import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../admin/admin_reports_screen.dart';
import '../admin/promotion_management_screen.dart';
import '../admin/refund_management_screen.dart';
import '../admin/user_management_screen.dart';
import '../auth/login_screen.dart';
import '../customer/customer_home_screen.dart';
import '../customer/my_bookings_screen.dart';
import '../customer/notifications_screen.dart';
import '../customer/wallet_screen.dart';
import '../shared/maintenance_management_screen.dart';
import '../staff/manage_fields_screen.dart';
import '../staff/staff_bookings_screen.dart';
import '../../seed_main.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final isOwnerOrStaff = user != null &&
        (user.role == UserRole.owner ||
            user.role == UserRole.staff ||
            user.role == UserRole.admin ||
            user.role == UserRole.superAdmin);

    final isAdmin = user != null &&
        (user.role == UserRole.admin || user.role == UserRole.superAdmin);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Row(
              children: [
                Flexible(
                  child: Text(
                    user?.fullName ?? 'Chưa đăng nhập',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user?.tier != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      user!.tier,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user?.email ?? ''} (${user?.role ?? ''})'),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Ví: ${currencyFormat.format(user.walletBalance)} | Điểm: ${user.points}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user != null && user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ),
          ),

          // Trang chủ & Đặt sân
          ListTile(
            leading: const Icon(Icons.sports_soccer, color: Colors.teal),
            title: const Text('Danh sách sân bóng'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              );
            },
          ),

          // Cho tất cả người dùng đăng nhập
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Lịch sử đặt sân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
              title: const Text('Ví & Điểm thưởng'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.amber),
              title: const Text('Hộp thư thông báo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
          ],

          // Phân quyền Owner / Staff
          if (isOwnerOrStaff) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'QUẢN LÝ DÀNH CHO CHỦ SÂN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.indigo),
              title: const Text('Quản lý đơn đặt sân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StaffBookingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.stadium, color: Colors.green),
              title: const Text('Quản lý sân bóng'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageFieldsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('Báo cáo doanh thu sân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.pink),
              title: const Text('Quản lý khuyến mãi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PromotionManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_circle, color: Colors.deepOrange),
              title: const Text('Lịch bảo trì sân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaintenanceManagementScreen()),
                );
              },
            ),
          ],

          // Phân quyền Admin
          if (isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'QUẢN TRỊ HỆ THỐNG (ADMIN)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('Báo cáo doanh thu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blueAccent),
              title: const Text('Quản lý người dùng'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.pink),
              title: const Text('Quản lý khuyến mãi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PromotionManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange, color: Colors.redAccent),
              title: const Text('Quản lý hoàn tiền STK'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RefundManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined, color: Colors.purple),
              title: const Text('Khởi tạo dữ liệu mẫu (Seeder)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SeedRunnerScreen()),
                );
              },
            ),
          ],

          const Divider(),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất'),
              onTap: () async {
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Colors.teal),
              title: const Text('Đăng nhập'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}

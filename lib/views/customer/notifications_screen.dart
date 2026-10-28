import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../customer/my_bookings_screen.dart';
import '../customer/wallet_screen.dart';
import '../shared/app_drawer.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Vui lòng đăng nhập để xem thông báo.')),
      );
    }

    final notifRepo = ref.watch(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộp thư thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await notifRepo.markAllAsRead(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc.')),
                );
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: notifRepo.getNotificationsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào.'));
          }

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final notif = list[i];
              return ListTile(
                tileColor: notif.isRead ? null : Colors.blue.shade50,
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                  child: Icon(
                    Icons.notifications,
                    color: notif.isRead ? Colors.grey : Colors.blue.shade800,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif.message),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.dateTimeString(notif.createdAt.toIso8601String()),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () async {
                  if (!notif.isRead) {
                    await notifRepo.markAsRead(notif.id);
                  }
                  if (!context.mounted) return;
                  if (notif.url == '/my-bookings') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                  } else if (notif.url == '/wallet') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

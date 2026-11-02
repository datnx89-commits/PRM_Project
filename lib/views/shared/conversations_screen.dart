import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/chat_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../customer/chat_screen.dart';
import 'app_drawer.dart';

/// Danh sách hội thoại của user hiện tại (dùng chung cho Khách hàng và Chủ sân).
/// Chủ sân vào đây để thấy và trả lời tin nhắn khách gửi từ màn Chi tiết sân.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  String _timeText(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    return sameDay ? DateFormat('HH:mm').format(t) : DateFormat('dd/MM').format(t);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tin nhắn')),
        drawer: const AppDrawer(),
        body: const Center(child: Text('Vui lòng đăng nhập để xem tin nhắn.')),
      );
    }

    final repo = ref.watch(chatRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<ChatConversationModel>>(
        stream: repo.getConversationsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải tin nhắn: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có cuộc trò chuyện nào.\nKhách hàng bấm "Nhắn tin chủ sân" ở trang Chi tiết sân để bắt đầu.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final conv = list[i];
              final isCustomer = conv.customerId == user.id;
              final otherName =
                  (isCustomer ? conv.ownerName : conv.customerName) ?? 'Người dùng';
              final roleLabel = isCustomer ? 'Chủ sân' : 'Khách hàng';
              final time = conv.lastMessageAt ?? conv.createdAt;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$roleLabel${conv.fieldName != null ? ' • ${conv.fieldName}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                    ),
                    Text(
                      conv.lastMessage ?? 'Chưa có tin nhắn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Text(
                  _timeText(time),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

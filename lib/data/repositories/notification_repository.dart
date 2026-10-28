import '../models/app_notification_model.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  final FirebaseService _firebase;

  NotificationRepository(this._firebase);

  /// Lắng nghe stream thông báo theo thời gian thực của người dùng
  Stream<List<AppNotificationModel>> getNotificationsStream(String userId) {
    return _firebase.notificationsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => AppNotificationModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Lấy danh sách thông báo một lần
  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    final snapshot = await _firebase.notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final list = snapshot.docs
        .map((d) => AppNotificationModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Đếm số lượng thông báo chưa đọc
  Stream<int> getUnreadCountStream(String userId) {
    return _firebase.notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _firebase.notificationsCollection.doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Đánh dấu tất cả thông báo của người dùng là đã đọc
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firebase.notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firebase.firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Gửi thông báo đến một người dùng
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? url,
  }) async {
    final docRef = _firebase.notificationsCollection.doc();
    final notif = AppNotificationModel(
      id: docRef.id,
      userId: userId,
      title: title,
      message: message,
      url: url,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await docRef.set(notif.toMap());
  }
}

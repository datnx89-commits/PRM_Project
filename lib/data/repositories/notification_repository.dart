import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../models/app_notification_model.dart';
import '../models/booking_model.dart';
import '../services/firebase_service.dart';

class NotificationRepository {
  /// Nhắc giờ đá trước tối đa bao lâu
  static const Duration matchReminderWindow = Duration(hours: 24);

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

  /// Giờ bắt đầu trận của booking; null nếu thiếu ngày/giờ hoặc sai định dạng
  static DateTime? matchStartOf(BookingModel booking) {
    final date = DateTime.tryParse(booking.effectiveBookingDate);
    final parts = (booking.startTime ?? '').split(':');
    if (date == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Booking đã xác nhận và sắp đá trong [matchReminderWindow] thì cần nhắc
  static bool shouldRemindMatch(BookingModel booking, DateTime now) {
    if (booking.status != BookingStatus.confirmed) return false;
    final start = matchStartOf(booking);
    if (start == null || !start.isAfter(now)) return false;
    return start.difference(now) <= matchReminderWindow;
  }

  /// Tạo thông báo nhắc giờ đá cho các booking sắp diễn ra của người dùng.
  /// Dùng id cố định `reminder_<bookingId>` nên mỗi booking chỉ nhắc một lần.
  Future<void> createMatchReminders(String userId) async {
    final snapshot = await _firebase.bookingsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: BookingStatus.confirmed)
        .get();

    final now = DateTime.now();
    final due = snapshot.docs
        .map((d) => BookingModel.fromMap(d.data(), d.id))
        .where((b) => shouldRemindMatch(b, now))
        .toList();
    if (due.isEmpty) return;

    final existing = await _firebase.notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();
    final existingIds = existing.docs.map((d) => d.id).toSet();

    for (final booking in due) {
      final id = 'reminder_${booking.id}';
      if (existingIds.contains(id)) continue;
      final notif = AppNotificationModel(
        id: id,
        userId: userId,
        title: 'Sắp đến giờ đá',
        message: 'Bạn có lịch đá tại ${booking.effectiveFieldName} lúc ${booking.startTime} ngày ${Formatters.dateString(booking.effectiveBookingDate)}.',
        url: '/my-bookings',
        createdAt: now,
      );
      await _firebase.notificationsCollection.doc(id).set(notif.toMap());
    }
  }
}

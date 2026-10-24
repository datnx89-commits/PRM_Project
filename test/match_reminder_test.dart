import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/data/models/booking_model.dart';
import 'package:sportsbook_36vn/data/repositories/notification_repository.dart';

void main() {
  final now = DateTime(2026, 11, 8, 18, 0);

  BookingModel booking({
    String status = 'Confirmed',
    String date = '2026-11-09',
    String? start = '17:00',
  }) =>
      BookingModel(
        id: 'b1',
        userId: 'u1',
        status: status,
        bookingDate: date,
        startTime: start,
        totalAmount: 100000,
        createdAt: now,
      );

  test('Doc dung gio bat dau tu ngay va gio cua booking', () {
    expect(NotificationRepository.matchStartOf(booking()), DateTime(2026, 11, 9, 17, 0));
  });

  test('Booking da xac nhan trong 24 gio toi thi can nhac', () {
    expect(NotificationRepository.shouldRemindMatch(booking(), now), isTrue);
    expect(NotificationRepository.shouldRemindMatch(booking(start: '18:00'), now), isTrue);
  });

  test('Con hon 24 gio thi chua nhac', () {
    expect(NotificationRepository.shouldRemindMatch(booking(start: '18:01'), now), isFalse);
    expect(NotificationRepository.shouldRemindMatch(booking(date: '2026-11-12'), now), isFalse);
  });

  test('Da qua gio da thi khong nhac', () {
    expect(NotificationRepository.shouldRemindMatch(booking(date: '2026-11-08', start: '18:00'), now), isFalse);
    expect(NotificationRepository.shouldRemindMatch(booking(date: '2026-11-07'), now), isFalse);
  });

  test('Booking chua xac nhan hoac da huy thi khong nhac', () {
    expect(NotificationRepository.shouldRemindMatch(booking(status: 'Pending'), now), isFalse);
    expect(NotificationRepository.shouldRemindMatch(booking(status: 'Cancelled'), now), isFalse);
  });

  test('Thieu gio hoac sai dinh dang thi khong nhac', () {
    expect(NotificationRepository.shouldRemindMatch(booking(start: null), now), isFalse);
    expect(NotificationRepository.shouldRemindMatch(booking(start: 'abc'), now), isFalse);
    expect(NotificationRepository.shouldRemindMatch(booking(date: 'abc'), now), isFalse);
  });
}

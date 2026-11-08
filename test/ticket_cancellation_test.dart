import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/core/constants/app_constants.dart';
import 'package:sportsbook_36vn/data/models/booking_detail_model.dart';
import 'package:sportsbook_36vn/data/models/booking_model.dart';

void main() {
  group('Digital Ticket Parsing Tests', () {
    test('ticketCode duoc sinh dong nhat tu id cua booking', () {
      final b1 = BookingModel(
        id: '6c8f12a3-9876-4321',
        userId: 'u1',
        totalAmount: 100000,
        createdAt: DateTime(2026, 11, 1),
      );

      final b2 = BookingModel(
        id: 'short1',
        userId: 'u2',
        totalAmount: 50000,
        createdAt: DateTime(2026, 11, 1),
      );

      expect(b1.ticketCode, 'TICKET-6C8F12A3');
      expect(b2.ticketCode, 'TICKET-SHORT100');
    });

    test('startDateTime fallback doc tu details neu booking khong co fieldId truc tiep', () {
      final detail = BookingDetailModel(
        id: 'bd1',
        bookingId: 'b1',
        fieldId: 'f1',
        timeSlotId: 'ts1',
        fieldName: 'San Co Nhan Tao',
        bookingDate: '2026-11-08',
        slotTime: '16:00 - 17:30',
        price: 150000,
      );

      final booking = BookingModel(
        id: 'b1',
        userId: 'u1',
        totalAmount: 150000,
        createdAt: DateTime(2026, 11, 1),
        details: [detail],
      );

      expect(booking.effectiveFieldName, 'San Co Nhan Tao');
      expect(booking.effectiveBookingDate, '2026-11-08');
      expect(booking.slotTimeText, '16:00 - 17:30');

      final start = booking.startDateTime;
      expect(start, isNotNull);
      expect(start!.year, 2026);
      expect(start.month, 11);
      expect(start.day, 8);
      expect(start.hour, 16);
      expect(start.minute, 0);
    });
  });

  group('2-Hour Cancellation Policy Tests', () {
    final sampleBooking = BookingModel(
      id: 'b-cancel-test',
      userId: 'u1',
      status: BookingStatus.confirmed,
      bookingDate: '2026-11-08',
      startTime: '18:00',
      endTime: '19:30',
      totalAmount: 120000,
      createdAt: DateTime(2026, 11, 1),
    );

    test('Cho phep huy khi con 2 tieng 1 phut truoc tran dau', () {
      // Tran bat dau luc 18:00 -> Luc 15:59 la con 121 phut (> 120 phut)
      final timeAllowed = DateTime(2026, 11, 8, 15, 59);
      expect(sampleBooking.isCancellableWithPolicy(minHoursBefore: 2, now: timeAllowed), isTrue);
    });

    test('Cho phep huy khi con dung tron 2 tieng (120 phut)', () {
      final timeExact = DateTime(2026, 11, 8, 16, 0);
      expect(sampleBooking.isCancellableWithPolicy(minHoursBefore: 2, now: timeExact), isTrue);
    });

    test('Tu choi huy khi con 1 tieng 59 phut (duoi 2 tieng)', () {
      final timeTooLate = DateTime(2026, 11, 8, 16, 1);
      expect(sampleBooking.isCancellableWithPolicy(minHoursBefore: 2, now: timeTooLate), isFalse);
    });

    test('Khong cho phep huy don da Completed hoac da Cancelled', () {
      final safeTime = DateTime(2026, 11, 8, 10, 0);

      final completed = sampleBooking.copyWith(status: BookingStatus.completed);
      expect(completed.isCancellableWithPolicy(minHoursBefore: 2, now: safeTime), isFalse);

      final cancelled = sampleBooking.copyWith(status: BookingStatus.cancelled);
      expect(cancelled.isCancellableWithPolicy(minHoursBefore: 2, now: safeTime), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/data/models/booking_model.dart';
import 'package:sportsbook_36vn/data/models/field_model.dart';
import 'package:sportsbook_36vn/data/models/time_slot_model.dart';
import 'package:sportsbook_36vn/data/models/user_model.dart';
import 'package:sportsbook_36vn/viewmodels/booking_viewmodel.dart';

void main() {
  group('BookingModel Unit Tests', () {
    test('ticketCode tao ma ve chuan voi prefix TICKET-', () {
      final booking = BookingModel(
        id: 'bk-12345678-abcd',
        userId: 'user1',
        totalAmount: 200000,
        createdAt: DateTime(2026, 10, 20),
      );
      expect(booking.ticketCode, startsWith('TICKET-'));
      expect(booking.ticketCode.length, greaterThanOrEqualTo(15));
    });

    test('startDateTime va endDateTime doc dung gio tu ngay va khung gio', () {
      final booking = BookingModel(
        id: 'bk1',
        userId: 'u1',
        bookingDate: '2026-10-25',
        startTime: '17:30',
        endTime: '19:00',
        totalAmount: 150000,
        createdAt: DateTime(2026, 10, 20),
      );

      final start = booking.startDateTime;
      final end = booking.endDateTime;

      expect(start, isNotNull);
      expect(start!.year, 2026);
      expect(start.month, 10);
      expect(start.day, 25);
      expect(start.hour, 17);
      expect(start.minute, 30);

      expect(end, isNotNull);
      expect(end!.hour, 19);
      expect(end.minute, 0);
    });

    test('isCancellableWithPolicy chi cho phep huy truoc gio bat dau it nhat 2 tieng', () {
      final booking = BookingModel(
        id: 'bk1',
        userId: 'u1',
        status: 'Confirmed',
        bookingDate: '2026-10-25',
        startTime: '18:00',
        totalAmount: 200000,
        createdAt: DateTime(2026, 10, 20),
      );

      // Truoc 3 tieng (15:00) -> Cho phep huy
      final nowSafe = DateTime(2026, 10, 25, 15, 0);
      expect(booking.isCancellableWithPolicy(minHoursBefore: 2, now: nowSafe), isTrue);

      // Truoc 1 tieng (17:00) -> Khong cho phep huy
      final nowTooLate = DateTime(2026, 10, 25, 17, 0);
      expect(booking.isCancellableWithPolicy(minHoursBefore: 2, now: nowTooLate), isFalse);

      // Don da huy thi khong duoc huy nua
      final cancelledBooking = booking.copyWith(status: 'Cancelled');
      expect(cancelledBooking.isCancellableWithPolicy(minHoursBefore: 2, now: nowSafe), isFalse);
    });
  });

  group('BookingProcessState Unit Tests', () {
    test('isSlotPast phat hien slot da qua gio khi chon ngay hom nay', () {
      const today = '2026-10-25';
      final state = BookingProcessState(selectedDate: today);

      final pastSlot = TimeSlotModel(id: 's1', fieldId: 'f1', startTime: '08:00', endTime: '09:00');
      final futureSlot = TimeSlotModel(id: 's2', fieldId: 'f1', startTime: '20:00', endTime: '21:00');

      final simulatedNow = DateTime(2026, 10, 25, 14, 0);
      expect(state.isSlotPast(pastSlot, simulatedNow), isTrue);
      expect(state.isSlotPast(futureSlot, simulatedNow), isFalse);
    });

    test('isSlotPast khong chan slot cua ngay mai trong tuong lai', () {
      final state = BookingProcessState(selectedDate: '2026-10-26');
      final earlySlot = TimeSlotModel(id: 's1', fieldId: 'f1', startTime: '06:00', endTime: '07:00');
      final simulatedNow = DateTime(2026, 10, 25, 14, 0);

      expect(state.isSlotPast(earlySlot, simulatedNow), isFalse);
    });

    test('totalSelectedHours tinh tong thoi gian cua nhieu slot duoc chon', () {
      final slot1 = TimeSlotModel(id: 's1', fieldId: 'f1', startTime: '17:00', endTime: '18:30');
      final slot2 = TimeSlotModel(id: 's2', fieldId: 'f1', startTime: '18:30', endTime: '20:00');

      final state = BookingProcessState(
        selectedDate: '2026-10-25',
        selectedSlots: [slot1, slot2],
      );

      expect(state.totalSelectedHours, 3.0);
    });

    test('getBreakdown boc tach day du subtotal va discount cho nguoi dung', () {
      final field = FieldModel(
        id: 'f1',
        ownerId: 'owner1',
        fieldName: 'San bong A',
        fieldTypeId: 'ft1',
        address: '123 Duong A, Ha Noi',
        pricePerHour: 100000,
        peakPricePerHour: 150000,
        createdAt: DateTime.now(),
      );

      final slot = TimeSlotModel(id: 's1', fieldId: 'f1', startTime: '08:00', endTime: '09:00');
      final state = BookingProcessState(
        selectedDate: '2026-10-25',
        selectedSlots: [slot],
      );

      final user = UserModel(
        id: 'u1',
        email: 'test@gmail.com',
        fullName: 'Nguyen Van A',
        role: 'Customer',
        lifetimePoints: 2500,
        points: 50,
        createdAt: DateTime.now(),
      );

      final breakdown = state.getBreakdown(field, user);
      expect(breakdown.subtotal, 100000.0);
      expect(breakdown.tierDiscount, greaterThan(0));
      expect(breakdown.finalAmount, lessThan(100000.0));
      expect(breakdown.estimatedPoints, greaterThanOrEqualTo(5));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/core/constants/app_constants.dart';
import 'package:sportsbook_36vn/data/models/booking_model.dart';
import 'package:sportsbook_36vn/data/models/refund_request_model.dart';

void main() {
  group('Refund & Booking status tests', () {
    test('RefundRequestModel isPending and status getters', () {
      final req = RefundRequestModel(
        id: 'ref_1',
        bookingId: 'bk_1',
        userId: 'user_1',
        amount: 150000,
        reason: 'Khách yêu cầu hủy',
        status: RefundStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(req.isPending, isTrue);
      expect(req.statusText, 'Chờ xử lý');

      final completedReq = req.copyWith(status: RefundStatus.completed);
      expect(completedReq.isPending, isFalse);
      expect(completedReq.statusText, 'Đã hoàn tiền');
    });

    test('BookingModel refunded status and payment method', () {
      final booking = BookingModel(
        id: 'bk_100',
        fieldId: 'f_1',
        userId: 'u_1',
        bookingDate: '2026-11-09',
        startTime: '18:00',
        endTime: '19:00',
        totalAmount: 180000,
        status: BookingStatus.cancelled,
        paymentStatus: PaymentStatus.refunded,
        paymentMethod: PaymentMethod.wallet,
        createdAt: DateTime.now(),
      );

      expect(booking.paymentStatus, PaymentStatus.refunded);
      expect(booking.paymentMethod, PaymentMethod.wallet);
      expect(booking.status, BookingStatus.cancelled);
    });
  });
}

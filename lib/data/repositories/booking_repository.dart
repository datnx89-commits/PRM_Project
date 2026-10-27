import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/booking_detail_model.dart';
import '../models/booking_model.dart';
import '../models/field_model.dart';
import '../models/payment_model.dart';
import '../models/promotion_model.dart';
import '../models/review_model.dart';
import '../models/time_slot_model.dart';
import '../services/firebase_service.dart';

class BookingRepository {
  final FirebaseService _firebaseService;
  final AppConfig _appConfig;

  BookingRepository(this._firebaseService, this._appConfig);

  Future<List<String>> getBookedSlotIds(String fieldId, String yyyyMmDd) async {
    final snapshot = await _firebaseService.bookingDetailsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('bookingDate', isEqualTo: yyyyMmDd)
        .where('status', isEqualTo: 'Active')
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['timeSlotId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<(bool, String, String?)> createBooking({
    required String userId,
    required String userEmail,
    required String userFullName,
    required FieldModel field,
    required String bookingDate,
    required List<TimeSlotModel> selectedSlots,
    PromotionModel? promo,
    String? note,
  }) async {
    if (selectedSlots.isEmpty) {
      return (false, 'Vui lòng chọn ít nhất một khung giờ.', null);
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (bookingDate.compareTo(todayStr) < 0) {
      return (false, 'Không thể đặt sân cho ngày trong quá khứ.', null);
    }

    final maxDays = _appConfig.maxAdvanceBookingDays;
    final maxDate = today.add(Duration(days: maxDays));
    final maxDateStr = '${maxDate.year}-${maxDate.month.toString().padLeft(2, '0')}-${maxDate.day.toString().padLeft(2, '0')}';
    if (bookingDate.compareTo(maxDateStr) > 0) {
      return (false, 'Chỉ được đặt trước tối đa $maxDays ngày.', null);
    }

    if (bookingDate == todayStr) {
      final currentHour = today.hour;
      for (var slot in selectedSlots) {
        final slotHour = int.tryParse(slot.startTime.split(':')[0]) ?? 0;
        if (slotHour <= currentHour) {
          return (false, 'Khung giờ ${slot.startTime} đã qua, vui lòng chọn khung giờ khác.', null);
        }
      }
    }

    double totalAmount = 0.0;
    final List<BookingDetailModel> details = [];
    final bookingDocRef = _firebaseService.bookingsCollection.doc();

    for (var slot in selectedSlots) {
      final price = slot.isPeak ? field.peakPricePerHour : field.pricePerHour;
      totalAmount += price;
      details.add(BookingDetailModel(
        id: _firebaseService.bookingDetailsCollection.doc().id,
        bookingId: bookingDocRef.id,
        fieldId: field.id,
        fieldName: field.fieldName,
        timeSlotId: slot.id,
        slotTime: '${slot.startTime} - ${slot.endTime}',
        bookingDate: bookingDate,
        price: price,
        status: 'Active',
      ));
    }

    if (promo != null) {
      if (!promo.isValidForDate(bookingDate)) {
        return (false, 'Mã giảm giá không hợp lệ hoặc đã hết hạn.', null);
      }
      final discount = promo.calculateDiscount(totalAmount);
      totalAmount -= discount;
    }

    try {
      final result = await _firebaseService.firestore.runTransaction<bool>((tx) async {
        for (var slot in selectedSlots) {
          final query = await _firebaseService.bookingDetailsCollection
              .where('fieldId', isEqualTo: field.id)
              .where('bookingDate', isEqualTo: bookingDate)
              .where('timeSlotId', isEqualTo: slot.id)
              .where('status', isEqualTo: 'Active')
              .get();

          if (query.docs.isNotEmpty) {
            return false;
          }
        }

        final booking = BookingModel(
          id: bookingDocRef.id,
          userId: userId,
          userEmail: userEmail,
          userFullName: userFullName,
          promotionId: promo?.id,
          promotionCode: promo?.code,
          status: BookingStatus.pending,
          totalAmount: totalAmount,
          note: note,
          createdAt: DateTime.now(),
        );

        tx.set(bookingDocRef, booking.toMap());

        for (var d in details) {
          final dRef = _firebaseService.bookingDetailsCollection.doc(d.id);
          tx.set(dRef, d.toMap());
        }

        if (promo != null) {
          final promoRef = _firebaseService.promotionsCollection.doc(promo.id);
          tx.update(promoRef, {'quantity': promo.quantity - 1});
        }

        return true;
      });

      if (!result) {
        return (false, 'Một hoặc nhiều khung giờ vừa được người khác đặt trước. Vui lòng chọn lại.', null);
      }

      return (true, 'Đặt sân thành công! Vui lòng thanh toán để xác nhận.', bookingDocRef.id);
    } catch (_) {
      return (false, 'Đã xảy ra lỗi khi tạo đơn đặt sân.', null);
    }
  }

  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    final snapshot = await _firebaseService.bookingsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final List<BookingModel> bookings = [];
    for (var doc in snapshot.docs) {
      final b = BookingModel.fromMap(doc.data(), doc.id);
      final details = await _getDetailsForBooking(b.id);
      final payment = await _getPaymentForBooking(b.id);
      final review = await _getReviewForBooking(b.id);
      bookings.add(b.copyWith(details: details, payment: payment, review: review));
    }

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<BookingModel?> getBookingDetail(String bookingId) async {
    final doc = await _firebaseService.bookingsCollection.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;

    final b = BookingModel.fromMap(doc.data()!, doc.id);
    final details = await _getDetailsForBooking(b.id);
    final payment = await _getPaymentForBooking(b.id);
    final review = await _getReviewForBooking(b.id);
    return b.copyWith(details: details, payment: payment, review: review);
  }

  Future<List<BookingModel>> getBookingsForStaff({String? ownerId, String? status}) async {
    Query<Map<String, dynamic>> query = _firebaseService.bookingsCollection;
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    List<BookingModel> bookings = [];

    for (var doc in snapshot.docs) {
      final b = BookingModel.fromMap(doc.data(), doc.id);
      final details = await _getDetailsForBooking(b.id);
      final payment = await _getPaymentForBooking(b.id);
      bookings.add(b.copyWith(details: details, payment: payment));
    }

    if (ownerId != null && ownerId.isNotEmpty) {
      final ownerFieldsSnapshot = await _firebaseService.fieldsCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();
      final ownerFieldIds = ownerFieldsSnapshot.docs.map((d) => d.id).toSet();

      bookings = bookings.where((b) {
        return b.details.any((d) => ownerFieldIds.contains(d.fieldId));
      }).toList();
    }

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<(bool, String)> cancelBooking({
    required String bookingId,
    required String userId,
    required bool isStaff,
  }) async {
    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');

    if (!isStaff && booking.userId != userId) {
      return (false, 'Bạn không có quyền hủy booking này.');
    }

    if (booking.status == BookingStatus.cancelled || booking.status == BookingStatus.completed) {
      return (false, 'Booking không thể hủy.');
    }

    if (!isStaff) {
      final limit = _appConfig.cancelBeforeHours;
      DateTime? earliestTime;
      for (var d in booking.details.where((x) => x.status == 'Active')) {
        final slotHour = int.tryParse(d.slotTime?.split(':')[0] ?? '0') ?? 0;
        final parts = d.bookingDate.split('-');
        if (parts.length == 3) {
          final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), slotHour);
          if (earliestTime == null || dt.isBefore(earliestTime)) {
            earliestTime = dt;
          }
        }
      }

      if (earliestTime != null) {
        final deadline = DateTime.now().add(Duration(hours: limit));
        if (earliestTime.isBefore(deadline)) {
          return (false, 'Chỉ được hủy trước giờ đá ít nhất $limit giờ.');
        }
      }
    }

    await _firebaseService.bookingsCollection.doc(bookingId).update({'status': BookingStatus.cancelled});

    final detailsSnapshot = await _firebaseService.bookingDetailsCollection
        .where('bookingId', isEqualTo: bookingId)
        .get();

    final batch = _firebaseService.firestore.batch();
    for (var doc in detailsSnapshot.docs) {
      batch.update(doc.reference, {'status': 'Cancelled'});
    }

    if (booking.promotionId != null && booking.promotionId!.isNotEmpty) {
      final promoDoc = await _firebaseService.promotionsCollection.doc(booking.promotionId).get();
      if (promoDoc.exists && promoDoc.data() != null) {
        final currentQty = (promoDoc.data()!['quantity'] as num?)?.toInt() ?? 0;
        batch.update(promoDoc.reference, {'quantity': currentQty + 1});
      }
    }

    if (booking.payment != null && booking.payment!.status == PaymentStatus.paid) {
      final paymentDoc = _firebaseService.paymentsCollection.doc(booking.payment!.id);
      batch.update(paymentDoc, {'status': PaymentStatus.refunded});
    }

    await batch.commit();

    final refundMsg = booking.payment?.status == PaymentStatus.paid
        ? ' Tiền sẽ được hoàn trong 3-5 ngày làm việc.'
        : '';
    return (true, 'Đã hủy booking thành công.$refundMsg');
  }

  Future<(bool, String)> confirmBooking(String bookingId) async {
    final doc = await _firebaseService.bookingsCollection.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return (false, 'Không tìm thấy booking.');
    final status = doc.data()!['status'] as String? ?? '';
    if (status != BookingStatus.pending) {
      return (false, 'Chỉ xác nhận được booking đang ở trạng thái chờ.');
    }

    await _firebaseService.bookingsCollection.doc(bookingId).update({'status': BookingStatus.confirmed});
    return (true, 'Đã xác nhận booking.');
  }

  Future<(bool, String)> payBooking({
    required String bookingId,
    required String userId,
    required String method,
  }) async {
    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');
    if (booking.userId != userId) return (false, 'Không có quyền thao tác.');
    if (booking.status == BookingStatus.cancelled) return (false, 'Booking đã bị hủy.');
    if (booking.status == BookingStatus.completed) return (false, 'Booking đã hoàn thành.');
    if (booking.payment != null && booking.payment!.status == PaymentStatus.paid) {
      return (false, 'Booking đã được thanh toán.');
    }

    final paymentDocRef = _firebaseService.paymentsCollection.doc();
    final payment = PaymentModel(
      id: paymentDocRef.id,
      bookingId: bookingId,
      amount: booking.totalAmount,
      method: method,
      status: PaymentStatus.paid,
      transactionCode: '${method.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
      paidAt: DateTime.now(),
    );

    final batch = _firebaseService.firestore.batch();
    batch.set(paymentDocRef, payment.toMap());

    if (booking.status == BookingStatus.pending) {
      batch.update(_firebaseService.bookingsCollection.doc(bookingId), {
        'status': BookingStatus.confirmed,
      });
    }

    await batch.commit();
    return (true, 'Thanh toán $method thành công! Booking đã được xác nhận.');
  }

  Future<(bool, String)> addReview({
    required String bookingId,
    required String userId,
    required String userFullName,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) return (false, 'Điểm đánh giá phải từ 1 đến 5 sao.');

    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');
    if (booking.userId != userId) return (false, 'Không có quyền đánh giá.');
    if (booking.status != BookingStatus.completed) {
      return (false, 'Chỉ đánh giá được sau khi đã hoàn thành sử dụng sân.');
    }
    if (booking.review != null) {
      return (false, 'Bạn đã đánh giá booking này rồi.');
    }
    if (booking.details.isEmpty) {
      return (false, 'Không tìm thấy chi tiết sân.');
    }

    final fieldId = booking.details.first.fieldId;
    final reviewDoc = _firebaseService.reviewsCollection.doc();
    final review = ReviewModel(
      id: reviewDoc.id,
      fieldId: fieldId,
      userId: userId,
      userFullName: userFullName,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await reviewDoc.set(review.toMap());

    final reviewsSnapshot = await _firebaseService.reviewsCollection
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final reviews = reviewsSnapshot.docs
        .map((d) => ReviewModel.fromMap(d.data(), d.id))
        .toList();

    if (reviews.isNotEmpty) {
      final avg = reviews.fold<num>(0, (acc, r) => acc + r.rating) / reviews.length;
      await _firebaseService.fieldsCollection.doc(fieldId).update({
        'averageRating': double.parse(avg.toStringAsFixed(1)),
      });
    }


    return (true, 'Cảm ơn bạn đã đánh giá!');
  }

  Future<void> completePastBookings() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final snapshot = await _firebaseService.bookingsCollection
        .where('status', isEqualTo: BookingStatus.confirmed)
        .get();

    final batch = _firebaseService.firestore.batch();
    bool hasUpdates = false;

    for (var doc in snapshot.docs) {
      final details = await _getDetailsForBooking(doc.id);
      final allPast = details.isNotEmpty && details.every((d) => d.bookingDate.compareTo(todayStr) < 0);
      if (allPast) {
        batch.update(doc.reference, {'status': BookingStatus.completed});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<List<BookingDetailModel>> _getDetailsForBooking(String bookingId) async {
    final snapshot = await _firebaseService.bookingDetailsCollection
        .where('bookingId', isEqualTo: bookingId)
        .get();

    return snapshot.docs
        .map((doc) => BookingDetailModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<PaymentModel?> _getPaymentForBooking(String bookingId) async {
    final snapshot = await _firebaseService.paymentsCollection
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PaymentModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<ReviewModel?> _getReviewForBooking(String bookingId) async {
    final snapshot = await _firebaseService.reviewsCollection
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ReviewModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }
}

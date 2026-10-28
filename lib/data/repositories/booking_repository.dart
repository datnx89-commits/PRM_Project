import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/pricing/pricing_engine.dart';
import '../models/booking_model.dart';
import '../models/field_model.dart';
import '../models/payment_model.dart';
import '../models/promotion_model.dart';
import '../models/refund_request_model.dart';
import '../models/review_model.dart';
import '../models/time_slot_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'notification_repository.dart';
import 'point_repository.dart';
import 'pricing_repository.dart';
import 'refund_repository.dart';
import 'wallet_repository.dart';

class BookingRepository {
  final FirebaseService _firebaseService;
  final AppConfig _appConfig;
  final PricingRepository _pricingRepo;
  final WalletRepository _walletRepo;
  final PointRepository _pointRepo;
  final NotificationRepository _notifRepo;
  final RefundRepository _refundRepo;

  RefundRepository get refundRepository => _refundRepo;

  BookingRepository(
    this._firebaseService,
    this._appConfig,
    this._pricingRepo,
    this._walletRepo,
    this._pointRepo,
    this._notifRepo,
    this._refundRepo,
  );

  /// Lấy danh sách timeSlotId đã có người đặt trong ngày cụ thể (status != Cancelled)
  Future<List<String>> getBookedSlotIds(String fieldId, String yyyyMmDd) async {
    // 1. Kiểm tra từ bảng Bookings trực tiếp (chuẩn hóa mới)
    final snapshot = await _firebaseService.bookingsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('bookingDate', isEqualTo: yyyyMmDd)
        .get();

    final bookedFromBookings = snapshot.docs
        .map((doc) => doc.data())
        .where((data) => data['status'] != BookingStatus.cancelled)
        .map((data) => data['timeSlotId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // 2. Kiểm tra thêm booking_details cũ (nếu có dữ liệu cũ)
    final legacySnapshot = await _firebaseService.bookingDetailsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('bookingDate', isEqualTo: yyyyMmDd)
        .where('status', isEqualTo: 'Active')
        .get();

    final bookedFromLegacy = legacySnapshot.docs
        .map((doc) => doc.data()['timeSlotId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    return {...bookedFromBookings, ...bookedFromLegacy}.toList();
  }

  /// Tạo đặt sân: Mỗi khung giờ được chọn = 1 Booking độc lập (ĐÃ BỎ BookingDetail)
  Future<(bool, String, List<String>)> createBooking({
    required String userId,
    required String userEmail,
    required String userFullName,
    String? userPhone,
    required FieldModel field,
    required String bookingDate,
    required List<TimeSlotModel> selectedSlots,
    PromotionModel? promo,
    String? note,
    String? createdById,
    int userLifetimePoints = 0,
  }) async {
    final List<String> none = [];
    if (selectedSlots.isEmpty) {
      return (false, 'Vui lòng chọn ít nhất một khung giờ.', none);
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (bookingDate.compareTo(todayStr) < 0) {
      return (false, 'Không thể đặt sân cho ngày trong quá khứ.', none);
    }

    final maxDays = _appConfig.maxAdvanceBookingDays;
    final maxDate = today.add(Duration(days: maxDays));
    final maxDateStr = '${maxDate.year}-${maxDate.month.toString().padLeft(2, '0')}-${maxDate.day.toString().padLeft(2, '0')}';
    if (bookingDate.compareTo(maxDateStr) > 0) {
      return (false, 'Chỉ được đặt trước tối đa $maxDays ngày.', none);
    }

    // Kiểm tra giờ đã qua nếu là ngày hôm nay
    if (bookingDate == todayStr) {
      final currentHour = today.hour;
      final currentMinute = today.minute;
      for (var slot in selectedSlots) {
        final parts = slot.startTime.split(':');
        final slotH = int.tryParse(parts[0]) ?? 0;
        final slotM = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (slotH < currentHour || (slotH == currentHour && slotM <= currentMinute)) {
          return (false, 'Khung giờ ${slot.startTime} đã qua, vui lòng chọn khung giờ khác.', none);
        }
      }
    }

    // Kiểm tra sân có đang trong khoảng bảo trì đã duyệt hay không
    final inMaintenance = (await _firebaseService.maintenanceRequestsCollection
            .where('fieldId', isEqualTo: field.id)
            .where('status', isEqualTo: MaintenanceStatus.approved)
            .where('startDate', isLessThanOrEqualTo: bookingDate)
            .get())
        .docs
        .any((d) => (d.data()['endDate'] as String? ?? '').compareTo(bookingDate) >= 0);

    if (inMaintenance) {
      return (false, 'Sân đang bảo trì trong ngày này, vui lòng chọn ngày khác.', none);
    }

    // Lấy thông tin ngày vàng và bảng giá đa cấp của sân
    final dateObj = DateTime.tryParse(bookingDate) ?? today;
    final golden = await _pricingRepo.getGoldenDay(field.id, bookingDate);
    final rules = await _pricingRepo.getRules(field.id);

    // Kiểm tra mã khuyến mãi
    if (promo != null) {
      if (!promo.isValidForDate(bookingDate)) {
        return (false, 'Mã giảm giá không hợp lệ hoặc đã hết hạn cho ngày này.', none);
      }
      if (promo.quantity < selectedSlots.length) {
        return (false, 'Mã giảm giá không đủ số lượng áp dụng cho tất cả khung giờ.', none);
      }
      if (!promo.isValidForField(field.ownerId)) {
        return (false, 'Mã giảm giá này không áp dụng cho sân bạn chọn.', none);
      }
    }

    // Tính mức giảm giá theo Hạng thành viên của khách
    final tier = AppConfig.getMembershipTier(userLifetimePoints);

    // Chuẩn bị danh sách BookingModel độc lập cho từng slot
    final List<BookingModel> bookingsToCreate = [];
    double grandTotal = 0.0;

    for (var slot in selectedSlots) {
      // 1. Giá theo PricingEngine (Rule + Ngày vàng)
      final unitPrice = PricingEngine.calculateSlotFinalPrice(
        field: field,
        slot: slot,
        date: dateObj,
        rules: rules,
        goldenDay: golden,
      );

      // 2. Giảm giá mã khuyến mãi
      double promoDiscount = 0.0;
      if (promo != null) {
        promoDiscount = promo.calculateDiscount(unitPrice);
      }

      // 3. Giảm giá theo hạng thành viên (% trên phần còn lại)
      double tierDiscount = 0.0;
      if (tier.discountPercent > 0) {
        tierDiscount = ((unitPrice - promoDiscount) * tier.discountPercent / 100.0).roundToDouble();
      }

      final totalDiscount = promoDiscount + tierDiscount;
      final totalAmount = (unitPrice - totalDiscount).clamp(0.0, double.infinity);
      grandTotal += totalAmount;

      final docRef = _firebaseService.bookingsCollection.doc();
      bookingsToCreate.add(BookingModel(
        id: docRef.id,
        userId: userId,
        userEmail: userEmail,
        userFullName: userFullName,
        userPhone: userPhone,
        fieldId: field.id,
        fieldName: field.fieldName,
        fieldAddress: field.fullAddress,
        fieldImage: field.primaryImageUrl,
        ownerId: field.ownerId,
        timeSlotId: slot.id,
        startTime: slot.startTime,
        endTime: slot.endTime,
        bookingDate: bookingDate,
        promotionId: promo?.id,
        promotionCode: promo?.code,
        status: BookingStatus.pending,
        unitPrice: unitPrice,
        discountAmount: totalDiscount,
        pointsUsed: 0,
        totalAmount: totalAmount,
        note: note,
        createdById: createdById,
        createdAt: DateTime.now(),
      ));
    }

    // Chống trùng lịch bằng Firestore Transaction
    try {
      final success = await _firebaseService.firestore.runTransaction<bool>((tx) async {
        for (var b in bookingsToCreate) {
          final conflictQuery = await _firebaseService.bookingsCollection
              .where('fieldId', isEqualTo: b.fieldId)
              .where('bookingDate', isEqualTo: b.bookingDate)
              .where('timeSlotId', isEqualTo: b.timeSlotId)
              .get();

          final hasConflict = conflictQuery.docs
              .any((d) => d.data()['status'] != BookingStatus.cancelled);

          if (hasConflict) return false;
        }

        // Lưu từng booking độc lập
        for (var b in bookingsToCreate) {
          final bRef = _firebaseService.bookingsCollection.doc(b.id);
          tx.set(bRef, b.toMap());
        }

        // Cập nhật số lượng mã khuyến mãi nếu có
        if (promo != null) {
          final promoRef = _firebaseService.promotionsCollection.doc(promo.id);
          tx.update(promoRef, {'quantity': promo.quantity - selectedSlots.length});
        }

        return true;
      });

      if (!success) {
        return (false, 'Một hoặc nhiều khung giờ vừa được người khác đặt trước. Vui lòng chọn lại.', none);
      }

      final bookingIds = bookingsToCreate.map((b) => b.id).toList();

      // Thông báo cho Chủ sân nếu không phải tự chủ sân đặt
      if (field.ownerId != userId && field.ownerId != createdById) {
        final slotTimes = selectedSlots.map((s) => '${s.startTime}-${s.endTime}').join(', ');
        await _notifRepo.sendNotification(
          userId: field.ownerId,
          title: 'Đặt sân mới',
          message: '$userFullName vừa đặt sân ${field.fieldName} ngày $bookingDate ($slotTimes), tổng ${grandTotal.toInt()}đ.',
          url: '/staff-bookings',
        );
      }

      final goldenNote = golden != null ? ' (Ngày vàng: ${golden.name})' : '';
      final tierNote = tier.discountPercent > 0 ? ' Hạng ${tier.name} giảm ${tier.discountPercent}%.' : '';

      return (
        true,
        'Đặt sân thành công (${selectedSlots.length} khung giờ, tổng ${grandTotal.toInt()}đ)$goldenNote.$tierNote Vui lòng thanh toán để xác nhận.',
        bookingIds
      );
    } catch (_) {
      return (false, 'Đã xảy ra lỗi khi tạo đơn đặt sân. Vui lòng thử lại.', none);
    }
  }

  /// Lấy danh sách booking của một User
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    await completePastBookings();

    final snapshot = await _firebaseService.bookingsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList();

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  /// Lấy chi tiết 1 booking (kèm review nếu có)
  Future<BookingModel?> getBookingDetail(String bookingId) async {
    final doc = await _firebaseService.bookingsCollection.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;

    final review = await _getReviewForBooking(bookingId);
    return BookingModel.fromMap(doc.data()!, doc.id, review: review);
  }

  /// Lấy danh sách booking cho Chủ sân / Quản trị viên
  Future<List<BookingModel>> getBookingsForStaff({String? ownerId, String? status}) async {
    await completePastBookings();

    Query query = _firebaseService.bookingsCollection;
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    final snapshot = await query.get();
    final bookings = snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  /// Hủy booking (Khách tự hủy hoặc Chủ sân/Admin hủy)
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

    // Kiểm tra quy định hủy: trước giờ đá >= cancelBeforeHours (mặc định 2 tiếng)
    if (!isStaff) {
      final limit = _appConfig.cancelBeforeHours;
      DateTime? startTime;
      final parts = booking.effectiveBookingDate.split('-');
      final hourPart = int.tryParse(booking.startTime?.split(':')[0] ?? '0') ?? 0;
      if (parts.length == 3) {
        startTime = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), hourPart);
      }

      if (startTime != null) {
        final deadline = DateTime.now().add(Duration(hours: limit));
        if (startTime.isBefore(deadline)) {
          return (false, 'Chỉ được hủy trước giờ đá ít nhất $limit giờ.');
        }
      }
    }

    // 1. Cập nhật trạng thái booking thành Cancelled
    await _firebaseService.bookingsCollection.doc(bookingId).update({
      'status': BookingStatus.cancelled,
      'paymentStatus': booking.isPaid ? PaymentStatus.refunded : booking.paymentStatus,
    });

    // Cập nhật trạng thái thanh toán trong paymentsCollection sang Refunded nếu đã thanh toán
    if (booking.isPaid) {
      final paymentsSnap = await _firebaseService.paymentsCollection
          .where('bookingId', isEqualTo: bookingId)
          .where('status', isEqualTo: PaymentStatus.paid)
          .get();
      for (var pDoc in paymentsSnap.docs) {
        await pDoc.reference.update({'status': PaymentStatus.refunded});
      }
    }

    // 2. Hoàn lại lượt mã khuyến mãi nếu có
    if (booking.promotionId != null && booking.promotionId!.isNotEmpty) {
      final promoDoc = await _firebaseService.promotionsCollection.doc(booking.promotionId).get();
      if (promoDoc.exists && promoDoc.data() != null) {
        final currentQty = (promoDoc.data()!['quantity'] as num?)?.toInt() ?? 0;
        await _firebaseService.promotionsCollection.doc(booking.promotionId).update({
          'quantity': currentQty + 1,
        });
      }
    }

    // 3. Hoàn lại điểm đã dùng
    await _pointRepo.returnUsedPoints(booking, 'hủy booking');

    // 4. Xử lý hoàn tiền nếu booking đã thanh toán
    String refundText = '';
    if (booking.isPaid && booking.totalAmount > 0) {
      // Kiểm tra sân có nhận ví không
      final fieldDoc = await _firebaseService.fieldsCollection.doc(booking.fieldId).get();
      final acceptWallet = fieldDoc.exists ? (fieldDoc.data()?['acceptWalletPayment'] as bool? ?? false) : false;
      final toWallet = booking.paymentMethod == PaymentMethod.wallet || acceptWallet;

      if (toWallet) {
        await _walletRepo.refund(
          userId: booking.userId,
          amount: booking.totalAmount,
          bookingId: booking.id,
          description: 'Hoàn tiền hủy booking #${booking.id}',
        );
        refundText = ' Số tiền ${booking.totalAmount.toInt()}đ đã được hoàn ngay vào ví của bạn.';
      } else {
        // Tạo yêu cầu chuyển khoản STK ngân hàng
        final userDoc = await _firebaseService.usersCollection.doc(booking.userId).get();
        UserModel? user;
        if (userDoc.exists && userDoc.data() != null) {
          user = UserModel.fromMap(userDoc.data()!, userDoc.id);
        }

        final refundRef = _firebaseService.refundRequestsCollection.doc();
        final refundReq = RefundRequestModel(
          id: refundRef.id,
          bookingId: booking.id,
          userId: booking.userId,
          userName: booking.userFullName,
          amount: booking.totalAmount,
          reason: isStaff ? 'Chủ sân/Admin hủy' : 'Khách tự hủy',
          status: RefundStatus.pending,
          bankName: user?.bankName,
          bankAccountNumber: user?.bankAccountNumber,
          bankAccountHolder: user?.bankAccountHolder,
          createdAt: DateTime.now(),
        );
        await refundRef.set(refundReq.toMap());
        refundText = ' Yêu cầu hoàn ${booking.totalAmount.toInt()}đ về tài khoản ngân hàng đang được xử lý.';
      }
    }

    // 5. Gửi thông báo
    if (isStaff && booking.userId != userId) {
      await _notifRepo.sendNotification(
        userId: booking.userId,
        title: 'Booking bị hủy',
        message: 'Booking sân ${booking.effectiveFieldName} ngày ${booking.effectiveBookingDate} (${booking.slotTimeText}) đã bị chủ sân hủy.$refundText',
        url: '/my-bookings',
      );
    } else if (!isStaff && booking.ownerId != null && booking.ownerId!.isNotEmpty) {
      await _notifRepo.sendNotification(
        userId: booking.ownerId!,
        title: 'Khách hủy booking',
        message: '${booking.userFullName ?? "Khách"} đã hủy booking #${booking.id} (${booking.effectiveFieldName}, ${booking.effectiveBookingDate}). Khung giờ đã trống trở lại.',
        url: '/staff-bookings',
      );
    }

    return (true, 'Đã hủy booking thành công.$refundText');
  }

  /// Thanh toán 1 hoặc nhiều booking cùng 1 phương thức (khớp nghiệp vụ ApiPaymentsController.Pay của C#)
  Future<(bool, String)> payBookings({
    required List<String> bookingIds,
    required String userId,
    required String method,
    int pointsToUse = 0,
  }) async {
    final uniqueIds = bookingIds.toSet().toList();
    if (uniqueIds.isEmpty) return (false, 'Chưa chọn booking.');

    final bookings = <BookingModel>[];
    for (var id in uniqueIds) {
      final b = await getBookingDetail(id);
      if (b == null) return (false, 'Không tìm thấy booking #$id.');
      if (b.userId != userId) return (false, 'Bạn không có quyền thanh toán booking #$id.');
      if (b.status == BookingStatus.cancelled) return (false, 'Booking #$id đã bị hủy.');
      if (b.status == BookingStatus.completed) return (false, 'Booking #$id đã hoàn thành.');
      if (b.isPaid) return (false, 'Booking #$id đã được thanh toán trước đó.');
      bookings.add(b);
    }

    // Kiểm tra sân có nhận ví không nếu phương thức là Wallet
    if (method == PaymentMethod.wallet) {
      for (var b in bookings) {
        final fieldDoc = await _firebaseService.fieldsCollection.doc(b.fieldId).get();
        final acceptWallet = fieldDoc.exists ? (fieldDoc.data()?['acceptWalletPayment'] as bool? ?? false) : false;
        if (!acceptWallet) {
          return (false, 'Sân "${b.effectiveFieldName}" không chấp nhận thanh toán bằng ví tiền ảo.');
        }
      }
    }

    // 1. THANH TOÁN TIỀN MẶT
    if (method == PaymentMethod.cash) {
      if (pointsToUse > 0) {
        return (false, 'Thanh toán tiền mặt không hỗ trợ dùng điểm trừ tiền.');
      }

      for (var booking in bookings) {
        await _firebaseService.bookingsCollection.doc(booking.id).update({
          'paymentMethod': PaymentMethod.cash,
          'paymentStatus': PaymentStatus.pending,
        });

        final paymentRef = _firebaseService.paymentsCollection.doc();
        final payment = PaymentModel(
          id: paymentRef.id,
          bookingId: booking.id,
          amount: booking.totalAmount,
          method: PaymentMethod.cash,
          status: PaymentStatus.pending,
          transactionCode: 'CASH-${DateTime.now().millisecondsSinceEpoch}',
          paidAt: null,
        );
        await paymentRef.set(payment.toMap());

        if (booking.ownerId != null && booking.ownerId!.isNotEmpty) {
          await _notifRepo.sendNotification(
            userId: booking.ownerId!,
            title: 'Yêu cầu trả tiền mặt',
            message: 'Khách đăng ký trả tiền mặt ${booking.totalAmount.toInt()}đ cho booking #${booking.id} (${booking.effectiveFieldName}, ${booking.effectiveBookingDate}) — chờ bạn xác nhận thu tiền.',
            url: '/staff-bookings',
          );
        }
      }

      final totalSum = bookings.fold<double>(0.0, (acc, b) => acc + b.totalAmount);
      return (
        true,
        'Đã ghi nhận yêu cầu trả tiền mặt ${totalSum.toInt()}đ cho ${bookings.length} khung giờ. Vui lòng thanh toán tại sân để chủ sân xác nhận.'
      );
    }

    // 2. DỰ TOÁN ĐIỂM THƯỞNG PHÂN BỔ & KIỂM TRA SỐ DƯ VÍ
    var remainingPoints = pointsToUse > 0 ? pointsToUse : 0;
    final pointsPlan = <String, int>{};
    final discountPlan = <String, double>{};
    final payablePlan = <String, double>{};
    double grandTotalPayable = 0.0;

    for (var b in bookings) {
      var use = 0;
      if (remainingPoints > 0) {
        final maxPts = await _pointRepo.getMaxRedeemable(userId, b.totalAmount);
        use = remainingPoints < maxPts ? remainingPoints : maxPts;
      }
      pointsPlan[b.id] = use;
      final disc = use * 100.0;
      discountPlan[b.id] = disc;
      final payable = (b.totalAmount - disc).clamp(0.0, double.infinity);
      payablePlan[b.id] = payable;
      grandTotalPayable += payable;
      remainingPoints -= use;
    }

    if (method == PaymentMethod.wallet) {
      final wallet = await _walletRepo.getOrCreateWallet(userId);
      if (wallet.isLocked) {
        return (false, 'Ví của bạn đang bị khóa.');
      }
      if (wallet.balance < grandTotalPayable) {
        return (false, 'Số dư ví không đủ. Cần ${grandTotalPayable.toInt()}đ, hiện có ${wallet.balance.toInt()}đ.');
      }
    }

    // 3. THỰC HIỆN THANH TOÁN CHO TỪNG BOOKING
    int totalPointsDeducted = 0;
    for (var booking in bookings) {
      final pointsForThis = pointsPlan[booking.id] ?? 0;
      final pointDiscount = discountPlan[booking.id] ?? 0.0;
      final finalAmount = payablePlan[booking.id] ?? booking.totalAmount;

      if (pointsForThis > 0) {
        final (ok, msg, _) = await _pointRepo.redeem(userId, pointsForThis, booking.id);
        if (!ok) return (false, msg);
        totalPointsDeducted += pointsForThis;
      }

      if (method == PaymentMethod.wallet) {
        final (ok, msg) = await _walletRepo.charge(
          userId: userId,
          amount: finalAmount,
          bookingId: booking.id,
          description: 'Thanh toán booking #${booking.id} - ${booking.effectiveFieldName}',
        );
        if (!ok) return (false, msg);

        final fieldDoc = await _firebaseService.fieldsCollection.doc(booking.fieldId).get();
        final cashbackPercent = fieldDoc.exists ? ((fieldDoc.data()?['cashbackPercent'] as num?)?.toInt() ?? 0) : 0;
        if (cashbackPercent > 0 && finalAmount > 0) {
          final cashbackAmount = ((finalAmount * cashbackPercent) / 100.0).roundToDouble();
          await _walletRepo.cashback(
            userId: userId,
            amount: cashbackAmount,
            bookingId: booking.id,
            description: 'Cashback $cashbackPercent% booking #${booking.id}',
          );
        }
      }

      final now = DateTime.now();
      await _firebaseService.bookingsCollection.doc(booking.id).update({
        'status': BookingStatus.confirmed,
        'paymentMethod': method,
        'paymentStatus': PaymentStatus.paid,
        'paidAt': now.toIso8601String(),
        'pointsUsed': booking.pointsUsed + pointsForThis,
        'discountAmount': booking.discountAmount + pointDiscount,
        'totalAmount': finalAmount,
      });

      final paymentDocRef = _firebaseService.paymentsCollection.doc();
      final paymentRecord = PaymentModel(
        id: paymentDocRef.id,
        bookingId: booking.id,
        amount: finalAmount,
        method: method,
        status: PaymentStatus.paid,
        transactionCode: '${method.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
        paidAt: now,
      );
      await paymentDocRef.set(paymentRecord.toMap());

      if (booking.ownerId != null && booking.ownerId!.isNotEmpty && booking.ownerId != userId) {
        await _notifRepo.sendNotification(
          userId: booking.ownerId!,
          title: 'Booking đã thanh toán',
          message: 'Booking #${booking.id} (${booking.effectiveFieldName}, ${booking.effectiveBookingDate}) đã được thanh toán ${finalAmount.toInt()}đ qua $method.',
          url: '/staff-bookings',
        );
      }
    }

    final pointsMsg = totalPointsDeducted > 0 ? ' (đã dùng $totalPointsDeducted điểm)' : '';
    return (
      true,
      bookings.length == 1
          ? 'Thanh toán $method thành công$pointsMsg! Booking đã được xác nhận.'
          : 'Thanh toán $method thành công cho ${bookings.length} khung giờ$pointsMsg! Các booking đã được xác nhận.'
    );
  }

  /// Thanh toán 1 booking (tiện ích tương thích gọi payBookings)
  Future<(bool, String)> payBooking({
    required String bookingId,
    required String userId,
    required String method,
    int pointsToUse = 0,
  }) async {
    return payBookings(
      bookingIds: [bookingId],
      userId: userId,
      method: method,
      pointsToUse: pointsToUse,
    );
  }

  /// Xác nhận đơn đặt (Chủ sân / Admin)
  Future<(bool, String)> confirmBooking(String bookingId) async {
    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');
    await _firebaseService.bookingsCollection.doc(bookingId).update({
      'status': BookingStatus.confirmed,
    });
    return (true, 'Đã xác nhận đơn đặt #$bookingId.');
  }

  /// Chủ sân / Admin xác nhận đã thu tiền mặt tại quầy
  Future<(bool, String)> confirmCashPayment(String bookingId, String confirmedById) async {
    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');
    if (booking.status == BookingStatus.cancelled) return (false, 'Booking đã bị hủy.');
    if (booking.isPaid) return (false, 'Booking này đã được thanh toán trước đó.');

    final now = DateTime.now();
    await _firebaseService.bookingsCollection.doc(bookingId).update({
      'status': BookingStatus.confirmed,
      'paymentMethod': PaymentMethod.cash,
      'paymentStatus': PaymentStatus.paid,
      'paidAt': now.toIso8601String(),
    });

    // Cập nhật hoặc ghi nhận giao dịch Paid trong paymentsCollection
    final cashPaymentsSnap = await _firebaseService.paymentsCollection
        .where('bookingId', isEqualTo: bookingId)
        .where('method', isEqualTo: PaymentMethod.cash)
        .where('status', isEqualTo: PaymentStatus.pending)
        .limit(1)
        .get();

    if (cashPaymentsSnap.docs.isNotEmpty) {
      await cashPaymentsSnap.docs.first.reference.update({
        'status': PaymentStatus.paid,
        'paidAt': now.toIso8601String(),
        'transactionCode': 'CASH-${DateTime.now().millisecondsSinceEpoch}-BY-$confirmedById',
      });
    } else {
      final pRef = _firebaseService.paymentsCollection.doc();
      final pModel = PaymentModel(
        id: pRef.id,
        bookingId: bookingId,
        amount: booking.totalAmount,
        method: PaymentMethod.cash,
        status: PaymentStatus.paid,
        transactionCode: 'CASH-${DateTime.now().millisecondsSinceEpoch}-BY-$confirmedById',
        paidAt: now,
      );
      await pRef.set(pModel.toMap());
    }

    // Thông báo cho khách hàng
    if (booking.userId != confirmedById) {
      await _notifRepo.sendNotification(
        userId: booking.userId,
        title: 'Đã xác nhận thanh toán tiền mặt',
        message: 'Chủ sân đã xác nhận thu ${booking.totalAmount.toInt()}đ tiền mặt cho booking #$bookingId (${booking.effectiveFieldName}). Booking đã được xác nhận.',
        url: '/my-bookings',
      );
    }

    return (true, 'Đã xác nhận thu ${booking.totalAmount.toInt()}đ tiền mặt. Booking #$bookingId đã được xác nhận.');
  }

  /// Chủ sân từ chối yêu cầu trả tiền mặt (khách không đến)
  Future<(bool, String)> rejectCashPayment(String bookingId, String rejectedById) async {
    final booking = await getBookingDetail(bookingId);
    if (booking == null) return (false, 'Không tìm thấy booking.');

    await _firebaseService.bookingsCollection.doc(bookingId).update({
      'paymentStatus': PaymentStatus.failed,
    });

    // Cập nhật payment trong paymentsCollection thành Failed
    final rejectSnap = await _firebaseService.paymentsCollection
        .where('bookingId', isEqualTo: bookingId)
        .where('method', isEqualTo: PaymentMethod.cash)
        .where('status', isEqualTo: PaymentStatus.pending)
        .get();
    for (var doc in rejectSnap.docs) {
      await doc.reference.update({'status': PaymentStatus.failed});
    }

    if (booking.userId != rejectedById) {
      await _notifRepo.sendNotification(
        userId: booking.userId,
        title: 'Yêu cầu trả tiền mặt bị từ chối',
        message: 'Chủ sân đã từ chối yêu cầu trả tiền mặt cho booking #$bookingId. Vui lòng chọn phương thức thanh toán khác để giữ chỗ.',
        url: '/my-bookings',
      );
    }

    return (true, 'Đã từ chối yêu cầu trả tiền mặt của booking #$bookingId.');
  }

  /// Đặt hộ khách (Walk-in) tại quầy hoặc qua điện thoại
  Future<(bool, String, List<String>)> walkInBooking({
    required String customerId,
    required String customerName,
    String? customerPhone,
    required FieldModel field,
    required String bookingDate,
    required List<TimeSlotModel> selectedSlots,
    PromotionModel? promo,
    String? note,
    required bool cashPaid,
    required String createdById,
  }) async {
    final noteFull = note != null && note.isNotEmpty ? 'Đặt hộ: $note' : 'Đặt hộ tại quầy';

    final (ok, msg, ids) = await createBooking(
      userId: customerId,
      userEmail: '',
      userFullName: customerName,
      userPhone: customerPhone,
      field: field,
      bookingDate: bookingDate,
      selectedSlots: selectedSlots,
      promo: promo,
      note: noteFull,
      createdById: createdById,
    );

    if (!ok) return (false, msg, ids);

    // Nếu đã thu tiền mặt ngay tại quầy
    if (cashPaid) {
      for (var id in ids) {
        await confirmCashPayment(id, createdById);
      }
    }

    final cashMsg = cashPaid ? ' Đã ghi nhận thu tiền mặt.' : '';
    return (true, 'Đặt hộ thành công cho khách $customerName.$cashMsg', ids);
  }

  /// Wrapper cho ViewModel gọi đặt hộ khách
  Future<(bool, String)> createWalkInBooking({
    required String fieldId,
    required String timeSlotId,
    required DateTime bookingDate,
    required String customerName,
    required String customerPhone,
    required double price,
    bool isPaidCash = true,
    required String staffId,
    String? note,
  }) async {
    final dateStr =
        '${bookingDate.year.toString().padLeft(4, '0')}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
    final fieldDoc = await _firebaseService.fieldsCollection.doc(fieldId).get();
    if (!fieldDoc.exists || fieldDoc.data() == null) {
      return (false, 'Không tìm thấy sân bóng.');
    }
    final field = FieldModel.fromMap(fieldDoc.data()!, fieldDoc.id);

    final slotDoc = await _firebaseService.timeSlotsCollection.doc(timeSlotId).get();
    TimeSlotModel slot;
    if (slotDoc.exists && slotDoc.data() != null) {
      slot = TimeSlotModel.fromMap(slotDoc.data()!, slotDoc.id);
    } else {
      slot = TimeSlotModel(id: timeSlotId, fieldId: fieldId, startTime: '08:00', endTime: '09:00', price: price);
    }

    final (ok, msg, _) = await walkInBooking(
      customerId: 'walkin_${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      customerPhone: customerPhone,
      field: field,
      bookingDate: dateStr,
      selectedSlots: [slot],
      cashPaid: isPaidCash,
      createdById: staffId,
      note: note,
    );
    return (ok, msg);
  }

  /// Đánh giá sân sau khi hoàn thành sử dụng (thưởng 10 điểm)
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

    final reviewDoc = _firebaseService.reviewsCollection.doc();
    final review = ReviewModel(
      id: reviewDoc.id,
      fieldId: booking.fieldId,
      userId: userId,
      userFullName: userFullName,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await reviewDoc.set(review.toMap());

    // Thưởng 10 điểm khi review
    await _pointRepo.earnForReview(userId, bookingId);

    // Cập nhật rating trung bình của sân
    final reviewsSnapshot = await _firebaseService.reviewsCollection
        .where('fieldId', isEqualTo: booking.fieldId)
        .get();

    final reviews = reviewsSnapshot.docs
        .map((d) => ReviewModel.fromMap(d.data(), d.id))
        .toList();

    if (reviews.isNotEmpty) {
      final avg = reviews.fold<num>(0, (acc, r) => acc + r.rating) / reviews.length;
      await _firebaseService.fieldsCollection.doc(booking.fieldId).update({
        'averageRating': double.parse(avg.toStringAsFixed(1)),
      });
    }

    // Thông báo cho chủ sân
    if (booking.ownerId != null && booking.ownerId!.isNotEmpty && booking.ownerId != userId) {
      await _notifRepo.sendNotification(
        userId: booking.ownerId!,
        title: 'Đánh giá mới',
        message: '$userFullName vừa đánh giá sân ${booking.effectiveFieldName}: $rating sao.',
        url: '/staff-bookings',
      );
    }

    return (true, 'Cảm ơn bạn đã đánh giá! Bạn được cộng ${_appConfig.reviewBonusPoints} điểm thưởng.');
  }

  /// Tự động chuyển booking đã qua ngày thành Completed và tích điểm cho khách
  Future<void> completePastBookings() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final snapshot = await _firebaseService.bookingsCollection
        .where('status', isEqualTo: BookingStatus.confirmed)
        .get();

    for (var doc in snapshot.docs) {
      final b = BookingModel.fromMap(doc.data(), doc.id);
      if (b.effectiveBookingDate.compareTo(todayStr) < 0) {
        await _firebaseService.bookingsCollection.doc(b.id).update({
          'status': BookingStatus.completed,
        });

        // Nếu đã thanh toán thì tự động tích điểm cho khách
        if (b.isPaid) {
          final golden = await _pricingRepo.getGoldenDay(b.fieldId, b.effectiveBookingDate);
          await _pointRepo.earnForBooking(b, golden);
        }
      }
    }
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

import 'dart:math';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/golden_day_model.dart';
import '../models/point_transaction_model.dart';
import '../models/promotion_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class PointRepository {
  final FirebaseService _firebase;
  final AppConfig _appConfig;

  PointRepository(this._firebase, this._appConfig);

  /// Lấy lịch sử biến động điểm của người dùng
  Future<List<PointTransactionModel>> getHistory(String userId) async {
    final snapshot = await _firebase.pointTransactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final list = snapshot.docs
        .map((d) => PointTransactionModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Thêm giao dịch điểm và cập nhật số dư điểm của user
  Future<void> _addTransaction({
    required UserModel user,
    required String type,
    required int points,
    String? description,
    String? bookingId,
  }) async {
    final newPoints = user.points + points;
    // LifetimePoints chỉ tăng khi cộng điểm (tiêu điểm không tụt hạng thành viên)
    final newLifetimePoints = points > 0 ? user.lifetimePoints + points : user.lifetimePoints;

    final txDocRef = _firebase.pointTransactionsCollection.doc();
    final tx = PointTransactionModel(
      id: txDocRef.id,
      userId: user.id,
      type: type,
      points: points,
      description: description,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );

    final batch = _firebase.firestore.batch();
    batch.set(txDocRef, tx.toMap());
    batch.update(_firebase.usersCollection.doc(user.id), {
      'points': newPoints,
      'lifetimePoints': newLifetimePoints,
    });

    await batch.commit();
  }

  /// Tích điểm khi booking hoàn thành: 10.000đ = 1 điểm, nhân ngày vàng, thưởng lần đầu và thưởng tháng
  Future<void> earnForBooking(BookingModel booking, GoldenDayModel? goldenDay) async {
    final basePoints = (booking.totalAmount / _appConfig.vndPerPoint).floor();
    if (basePoints <= 0) return;

    final multiplier = (goldenDay != null && goldenDay.isActive) ? goldenDay.pointsMultiplier : 1;
    final earnedPoints = basePoints * multiplier;

    final userDoc = await _firebase.usersCollection.doc(booking.userId).get();
    if (!userDoc.exists || userDoc.data() == null) return;
    var user = UserModel.fromMap(userDoc.data()!, userDoc.id);

    final goldenText = goldenDay != null ? ' (x$multiplier ${goldenDay.name})' : '';
    await _addTransaction(
      user: user,
      type: PointTxType.earn,
      points: earnedPoints,
      description: 'Tích điểm booking #${booking.id}$goldenText',
      bookingId: booking.id,
    );

    // Cập nhật lại user sau giao dịch
    final uDoc2 = await _firebase.usersCollection.doc(booking.userId).get();
    if (uDoc2.exists && uDoc2.data() != null) {
      user = UserModel.fromMap(uDoc2.data()!, uDoc2.id);
    }

    // 1. Thưởng lần đặt đầu tiên (+20 điểm)
    const firstBonusDesc = 'Thưởng hoàn thành booking đầu tiên';
    final hadFirstBonus = (await _firebase.pointTransactionsCollection
            .where('userId', isEqualTo: user.id)
            .where('description', isEqualTo: firstBonusDesc)
            .limit(1)
            .get())
        .docs
        .isNotEmpty;

    if (!hadFirstBonus) {
      final completedCount = (await _firebase.bookingsCollection
              .where('userId', isEqualTo: user.id)
              .where('status', isEqualTo: BookingStatus.completed)
              .get())
          .docs
          .length;

      if (completedCount <= 1) {
        await _addTransaction(
          user: user,
          type: PointTxType.earn,
          points: _appConfig.firstBookingBonusPoints,
          description: firstBonusDesc,
          bookingId: booking.id,
        );
        // Refresh user
        final uDoc3 = await _firebase.usersCollection.doc(booking.userId).get();
        if (uDoc3.exists && uDoc3.data() != null) {
          user = UserModel.fromMap(uDoc3.data()!, uDoc3.id);
        }
      }
    }

    // 2. Thưởng hoàn thành đủ 5 booking trong tháng (+50 điểm)
    final dateParts = booking.bookingDate.split('-');
    if (dateParts.length == 3) {
      final yearMonth = '${dateParts[0]}-${dateParts[1]}';
      final monthlyDesc = 'Thưởng hoàn thành đủ ${_appConfig.monthlyBookingTarget} booking trong tháng $yearMonth';
      final hadMonthlyBonus = (await _firebase.pointTransactionsCollection
              .where('userId', isEqualTo: user.id)
              .where('description', isEqualTo: monthlyDesc)
              .limit(1)
              .get())
          .docs
          .isNotEmpty;

      if (!hadMonthlyBonus) {
        final monthStart = '$yearMonth-01';
        final monthEnd = '$yearMonth-31';
        final monthCompletedBookings = (await _firebase.bookingsCollection
                .where('userId', isEqualTo: user.id)
                .where('status', isEqualTo: BookingStatus.completed)
                .where('bookingDate', isGreaterThanOrEqualTo: monthStart)
                .where('bookingDate', isLessThanOrEqualTo: monthEnd)
                .get())
            .docs
            .length;

        if (monthCompletedBookings >= _appConfig.monthlyBookingTarget) {
          await _addTransaction(
            user: user,
            type: PointTxType.earn,
            points: _appConfig.monthlyBookingBonusPoints,
            description: monthlyDesc,
            bookingId: booking.id,
          );
        }
      }
    }
  }

  /// Thưởng điểm khi viết đánh giá sân (+10 điểm)
  Future<void> earnForReview(String userId, String bookingId) async {
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) return;
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);

    await _addTransaction(
      user: user,
      type: PointTxType.reviewBonus,
      points: _appConfig.reviewBonusPoints,
      description: 'Thưởng đánh giá booking #$bookingId',
      bookingId: bookingId,
    );
  }

  /// Tính số điểm tối đa được phép dùng cho booking
  Future<int> getMaxRedeemable(String userId, double totalAmount) async {
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) return 0;
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
    if (user.points <= 0) return 0;

    // Trần tiền = totalAmount * maxRedeemPercent / 100
    final capValue = totalAmount * _appConfig.maxRedeemPercent / 100.0;
    final capPoints = (capValue / _appConfig.pointValueVnd).floor();
    return min(user.points, capPoints);
  }

  /// Trừ điểm để giảm giá khi thanh toán
  Future<(bool, String, double)> redeem(String userId, int points, String bookingId) async {
    if (points <= 0) return (true, '', 0.0);

    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) {
      return (false, 'Không tìm thấy người dùng.', 0.0);
    }
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
    if (user.points < points) {
      return (false, 'Không đủ điểm (hiện có ${user.points} điểm).', 0.0);
    }

    final discountValue = points * _appConfig.pointValueVnd;
    await _addTransaction(
      user: user,
      type: PointTxType.redeem,
      points: -points,
      description: 'Dùng $points điểm trừ ${discountValue.toInt()}đ cho booking #$bookingId',
      bookingId: bookingId,
    );

    return (true, 'Đã dùng $points điểm (giảm ${discountValue.toInt()}đ).', discountValue);
  }

  /// Hoàn lại điểm đã dùng khi booking bị hủy
  Future<void> returnUsedPoints(BookingModel booking, String reason) async {
    if (booking.pointsUsed <= 0) return;

    final userDoc = await _firebase.usersCollection.doc(booking.userId).get();
    if (!userDoc.exists || userDoc.data() == null) return;
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);

    // Hoàn điểm: cộng lại số dư nhưng không cộng vào LifetimePoints
    final newPoints = user.points + booking.pointsUsed;
    final txDocRef = _firebase.pointTransactionsCollection.doc();
    final tx = PointTransactionModel(
      id: txDocRef.id,
      userId: user.id,
      type: PointTxType.revoke,
      points: booking.pointsUsed,
      description: 'Hoàn ${booking.pointsUsed} điểm ($reason) - booking #${booking.id}',
      bookingId: booking.id,
      createdAt: DateTime.now(),
    );

    final batch = _firebase.firestore.batch();
    batch.set(txDocRef, tx.toMap());
    batch.update(_firebase.usersCollection.doc(user.id), {
      'points': newPoints,
    });
    await batch.commit();
  }

  /// Đổi điểm lấy voucher giảm giá (sinh mã Promotion dùng 1 lần)
  Future<(bool, String, String?)> redeemVoucher(String userId, int optionIndex) async {
    final options = _appConfig.voucherOptions;
    if (optionIndex < 0 || optionIndex >= options.length) {
      return (false, 'Gói voucher không hợp lệ.', null);
    }
    final opt = options[optionIndex];

    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) {
      return (false, 'Không tìm thấy người dùng.', null);
    }
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
    if (user.points < opt.pointCost) {
      return (
        false,
        'Không đủ điểm để đổi voucher này (cần ${opt.pointCost}, hiện có ${user.points}).',
        null
      );
    }

    // Sinh mã voucher duy nhất (VC + 8 ký tự hex ngẫu nhiên)
    final rand = Random();
    final codeSuffix = List.generate(8, (_) => rand.nextInt(16).toRadixString(16)).join().toUpperCase();
    final code = 'VC$codeSuffix';

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final expiry = now.add(Duration(days: opt.validityDays));
    final expiryStr = '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';

    final promoDocRef = _firebase.promotionsCollection.doc();
    final promo = PromotionModel(
      id: promoDocRef.id,
      code: code,
      description: 'Voucher đổi ${opt.pointCost} điểm - ${user.fullName}',
      discountPercent: opt.discountPercent,
      maxDiscount: opt.maxDiscount,
      startDate: todayStr,
      endDate: expiryStr,
      quantity: 1, // Dùng 1 lần
      isActive: true,
      ownerId: null, // Áp dụng mọi sân
    );

    final batch = _firebase.firestore.batch();
    batch.set(promoDocRef, promo.toMap());

    // Trừ điểm user
    final newPoints = user.points - opt.pointCost;
    final txDocRef = _firebase.pointTransactionsCollection.doc();
    final tx = PointTransactionModel(
      id: txDocRef.id,
      userId: user.id,
      type: PointTxType.redeem,
      points: -opt.pointCost,
      description: 'Đổi ${opt.pointCost} điểm lấy voucher $code (giảm ${opt.discountPercent}%, tối đa ${opt.maxDiscount.toInt()}đ)',
      createdAt: now,
    );
    batch.set(txDocRef, tx.toMap());
    batch.update(_firebase.usersCollection.doc(user.id), {
      'points': newPoints,
    });

    await batch.commit();

    return (
      true,
      'Đổi voucher thành công! Mã của bạn là $code (giảm ${opt.discountPercent}%, HSD: $expiryStr).',
      code
    );
  }

  /// Admin điều chỉnh điểm thủ công
  Future<(bool, String)> adjust({
    required String userId,
    required int points,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      return (false, 'Cộng/trừ điểm thủ công bắt buộc phải ghi lý do.');
    }
    final userDoc = await _firebase.usersCollection.doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) {
      return (false, 'Không tìm thấy người dùng.');
    }
    final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
    if (user.points + points < 0) {
      return (false, 'Không thể trừ quá số điểm hiện có của người dùng.');
    }

    await _addTransaction(
      user: user,
      type: PointTxType.adjust,
      points: points,
      description: 'Admin điều chỉnh: $reason',
    );

    return (true, 'Đã điều chỉnh điểm.');
  }

  /// Alias cho admin điều chỉnh điểm
  Future<(bool, String)> adminAdjustPoints({
    required String userId,
    required int points,
    required String reason,
    required String adminId,
  }) => adjust(userId: userId, points: points, reason: reason);
}

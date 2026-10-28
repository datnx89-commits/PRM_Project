import 'package:shared_preferences/shared_preferences.dart';

class DepositBonusTier {
  final double minAmount;
  final double bonusAmount;

  const DepositBonusTier({
    required this.minAmount,
    required this.bonusAmount,
  });
}

class VoucherOption {
  final int pointCost;
  final int discountPercent;
  final double maxDiscount;
  final int validityDays;

  const VoucherOption({
    required this.pointCost,
    required this.discountPercent,
    required this.maxDiscount,
    required this.validityDays,
  });
}

class MembershipTier {
  final String name;
  final int minLifetimePoints;
  final int discountPercent;

  const MembershipTier({
    required this.name,
    required this.minLifetimePoints,
    required this.discountPercent,
  });
}

class AppConfig {
  static const String _keyCancelBeforeHours = 'cancel_before_hours';
  static const String _keyMaxAdvanceDays = 'max_advance_days';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';

  final SharedPreferences _prefs;

  AppConfig(this._prefs);

  // Quy định hủy và đặt trước
  int get cancelBeforeHours => _prefs.getInt(_keyCancelBeforeHours) ?? 2;
  Future<void> setCancelBeforeHours(int hours) => _prefs.setInt(_keyCancelBeforeHours, hours);

  int get maxAdvanceBookingDays => _prefs.getInt(_keyMaxAdvanceDays) ?? 30;
  Future<void> setMaxAdvanceBookingDays(int days) => _prefs.setInt(_keyMaxAdvanceDays, days);

  // Cấu hình tích điểm và tiêu điểm
  double get vndPerPoint => 10000.0; // 10.000đ = 1 điểm
  double get pointValueVnd => 100.0; // 1 điểm = 100đ khi tiêu
  int get maxRedeemPercent => 50; // Tối đa 50% tổng giá trị booking
  int get reviewBonusPoints => 10;
  int get firstBookingBonusPoints => 20;
  int get monthlyBookingTarget => 5;
  int get monthlyBookingBonusPoints => 50;

  // Cấu hình ví tiền ảo
  double get minDepositAmount => 10000.0; // Nạp tối thiểu 10.000đ

  List<DepositBonusTier> get depositBonusTiers => const [
    DepositBonusTier(minAmount: 500000.0, bonusAmount: 50000.0),
    DepositBonusTier(minAmount: 200000.0, bonusAmount: 15000.0),
  ];

  DepositBonusTier? getDepositBonus(double amount) {
    for (var tier in depositBonusTiers) {
      if (amount >= tier.minAmount) return tier;
    }
    return null;
  }

  // Các gói đổi điểm lấy voucher
  List<VoucherOption> get voucherOptions => const [
    VoucherOption(pointCost: 100, discountPercent: 5, maxDiscount: 20000.0, validityDays: 30),
    VoucherOption(pointCost: 200, discountPercent: 10, maxDiscount: 50000.0, validityDays: 30),
    VoucherOption(pointCost: 500, discountPercent: 15, maxDiscount: 150000.0, validityDays: 60),
  ];

  // Hạng thành viên tính theo điểm trọn đời
  static const List<MembershipTier> membershipTiers = [
    MembershipTier(name: 'Kim cương', minLifetimePoints: 5000, discountPercent: 10),
    MembershipTier(name: 'Vàng', minLifetimePoints: 2000, discountPercent: 5),
    MembershipTier(name: 'Bạc', minLifetimePoints: 500, discountPercent: 3),
    MembershipTier(name: 'Thường', minLifetimePoints: 0, discountPercent: 0),
  ];

  static MembershipTier getMembershipTier(int lifetimePoints) {
    for (var tier in membershipTiers) {
      if (lifetimePoints >= tier.minLifetimePoints) return tier;
    }
    return membershipTiers.last;
  }

  // User session
  String? get userId => _prefs.getString(_keyUserId);
  String? get userEmail => _prefs.getString(_keyUserEmail);
  String? get userName => _prefs.getString(_keyUserName);
  String? get userRole => _prefs.getString(_keyUserRole);

  Future<void> saveUserSession({
    required String id,
    required String email,
    required String name,
    required String role,
  }) async {
    await _prefs.setString(_keyUserId, id);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserRole, role);
  }

  Future<void> clearUserSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserRole);
  }
}

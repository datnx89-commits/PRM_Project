class UserRole {
  static const String admin = 'Admin';
  static const String owner = 'Owner';
  static const String staff = 'Staff'; // Giữ tương thích ngược với Owner
  static const String customer = 'Customer';
  static const String superAdmin = 'SuperAdmin';
}

class BookingStatus {
  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String cancelled = 'Cancelled';
  static const String completed = 'Completed';
}

class PaymentMethod {
  static const String vnpay = 'VNPay';
  static const String momo = 'Momo';
  static const String cash = 'Cash';
  static const String wallet = 'Wallet';
}

class PaymentStatus {
  static const String pending = 'Pending';
  static const String paid = 'Paid';
  static const String refunded = 'Refunded';
  static const String failed = 'Failed';
}

class FieldStatus {
  static const String active = 'Active';
  static const String maintenance = 'Maintenance';
  static const String closed = 'Closed';
}

class WalletTxType {
  static const String deposit = 'Deposit';
  static const String payment = 'Payment';
  static const String refund = 'Refund';
  static const String cashback = 'Cashback';
  static const String bonus = 'Bonus';
  static const String adjust = 'Adjust';
}

class PointTxType {
  static const String earn = 'Earn';
  static const String redeem = 'Redeem';
  static const String reviewBonus = 'ReviewBonus';
  static const String revoke = 'Revoke';
  static const String adjust = 'Adjust';
}

class MaintenanceStatus {
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
}

class RefundStatus {
  static const String pending = 'Pending';
  static const String completed = 'Completed';
  static const String rejected = 'Rejected';
}

class PricingDayType {
  static const String all = 'All';
  static const String weekday = 'Weekday';
  static const String weekend = 'Weekend';
}

class SuperAccountConstants {
  static const String emailHash = '27cbfffc12a8cf6ebfeb875859ef17e04feb0965cd208affff7d2de2b43a9292';
  static const String passwordHash = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';
  static const String superAdminId = 'super_admin';
}

class UserRole {
  static const String admin = 'Admin';
  static const String staff = 'Staff';
  static const String customer = 'Customer';
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
}

class PaymentStatus {
  static const String pending = 'Pending';
  static const String paid = 'Paid';
  static const String refunded = 'Refunded';
}

class FieldStatus {
  static const String active = 'Active';
  static const String closed = 'Closed';
}

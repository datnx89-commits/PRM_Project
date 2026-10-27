class PaymentModel {
  final String id;
  final String bookingId;
  final double amount;
  final String method;
  final String status;
  final String? transactionCode;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    this.status = 'Pending',
    this.transactionCode,
    this.paidAt,
  });

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    double? amount,
    String? method,
    String? status,
    String? transactionCode,
    DateTime? paidAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionCode: transactionCode ?? this.transactionCode,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'method': method,
      'status': status,
      'transactionCode': transactionCode,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method'] ?? '',
      status: map['status'] ?? 'Pending',
      transactionCode: map['transactionCode'],
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt']) : null,
    );
  }
}

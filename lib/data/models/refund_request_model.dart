class RefundRequestModel {
  final String id;
  final String bookingId;
  final String userId;
  final String? userName;
  final double amount;
  final String reason;
  final String status; // Pending | Completed | Rejected
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? processedNote;
  final String? processedById;
  final DateTime? processedAt;
  final DateTime createdAt;

  RefundRequestModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.userName,
    required this.amount,
    required this.reason,
    this.status = 'Pending',
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.processedNote,
    this.processedById,
    this.processedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';

  String get statusText {
    switch (status) {
      case 'Completed':
        return 'Đã hoàn tiền';
      case 'Rejected':
        return 'Từ chối';
      case 'Pending':
      default:
        return 'Chờ xử lý';
    }
  }

  RefundRequestModel copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? userName,
    double? amount,
    String? reason,
    String? status,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    String? processedNote,
    String? processedById,
    DateTime? processedAt,
    DateTime? createdAt,
  }) {
    return RefundRequestModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      processedNote: processedNote ?? this.processedNote,
      processedById: processedById ?? this.processedById,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'reason': reason,
      'status': status,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolder': bankAccountHolder,
      'processedNote': processedNote,
      'processedById': processedById,
      'processedAt': processedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RefundRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RefundRequestModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending',
      bankName: map['bankName'],
      bankAccountNumber: map['bankAccountNumber'],
      bankAccountHolder: map['bankAccountHolder'],
      processedNote: map['processedNote'],
      processedById: map['processedById'],
      processedAt: map['processedAt'] != null
          ? DateTime.tryParse(map['processedAt'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

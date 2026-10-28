class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final bool isLocked;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.isLocked = false,
    required this.updatedAt,
  });

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    bool? isLocked,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      isLocked: isLocked ?? this.isLocked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'isLocked': isLocked,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletModel(
      id: id,
      userId: map['userId'] ?? id,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      isLocked: map['isLocked'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletTransactionModel {
  final String id;
  final String walletId;
  final String type; // Deposit | Payment | Refund | Cashback | Bonus | Adjust
  final double amount; // Dương = cộng, Âm = trừ
  final double balanceAfter;
  final String? description;
  final String? bookingId;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.bookingId,
    required this.createdAt,
  });

  bool get isPositive => amount >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'type': type,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'description': description,
      'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransactionModel(
      id: id,
      walletId: map['walletId'] ?? '',
      type: map['type'] ?? 'Deposit',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      bookingId: map['bookingId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PointTransactionModel {
  final String id;
  final String userId;
  final String type; // Earn | Redeem | ReviewBonus | Revoke | Adjust
  final int points;  // Dương = cộng điểm, Âm = trừ điểm
  final String? description;
  final String? bookingId;
  final DateTime createdAt;

  PointTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    this.description,
    this.bookingId,
    required this.createdAt,
  });

  bool get isPositive => points >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'points': points,
      'description': description,
      'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PointTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return PointTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'Earn',
      points: (map['points'] as num?)?.toInt() ?? 0,
      description: map['description'],
      bookingId: map['bookingId'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

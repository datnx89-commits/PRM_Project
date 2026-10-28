class GoldenDayModel {
  final String id;
  final String? fieldId; // null = ngày vàng toàn hệ thống (Admin), có fieldId = riêng của sân
  final String date;     // "yyyy-MM-dd"
  final String name;
  final double priceMultiplier;  // 1.0 - 5.0
  final double pointMultiplier;  // Hệ số nhân điểm (VD: 2.0 = x2 điểm)
  final bool isActive;
  final DateTime? createdAt;

  GoldenDayModel({
    required this.id,
    this.fieldId,
    dynamic date,
    required this.name,
    this.priceMultiplier = 1.0,
    double? pointMultiplier,
    int? pointsMultiplier,
    this.isActive = true,
    this.createdAt,
  })  : date = date is DateTime
            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
            : (date?.toString() ?? ''),
        pointMultiplier = pointMultiplier ?? pointsMultiplier?.toDouble() ?? 2.0;

  int get pointsMultiplier => pointMultiplier.round();
  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();
  bool get isGlobal => fieldId == null || fieldId!.isEmpty;

  GoldenDayModel copyWith({
    String? id,
    String? fieldId,
    dynamic date,
    String? name,
    double? priceMultiplier,
    double? pointMultiplier,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GoldenDayModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      date: date ?? this.date,
      name: name ?? this.name,
      priceMultiplier: priceMultiplier ?? this.priceMultiplier,
      pointMultiplier: pointMultiplier ?? this.pointMultiplier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'date': date,
      'name': name,
      'priceMultiplier': priceMultiplier,
      'pointMultiplier': pointMultiplier,
      'pointsMultiplier': pointsMultiplier,
      'isActive': isActive,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory GoldenDayModel.fromMap(Map<String, dynamic> map, String id) {
    return GoldenDayModel(
      id: id,
      fieldId: map['fieldId'],
      date: map['date'] ?? '',
      name: map['name'] ?? '',
      priceMultiplier: (map['priceMultiplier'] as num?)?.toDouble() ?? 1.0,
      pointMultiplier: (map['pointMultiplier'] as num?)?.toDouble() ??
          (map['pointsMultiplier'] as num?)?.toDouble() ??
          2.0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }
}

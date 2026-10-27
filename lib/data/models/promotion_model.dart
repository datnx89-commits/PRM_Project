class PromotionModel {
  final String id;
  final String code;
  final String? description;
  final int discountPercent;
  final double maxDiscount;
  final String startDate;
  final String endDate;
  final int quantity;
  final bool isActive;

  PromotionModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountPercent,
    required this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    this.isActive = true,
  });

  PromotionModel copyWith({
    String? id,
    String? code,
    String? description,
    int? discountPercent,
    double? maxDiscount,
    String? startDate,
    String? endDate,
    int? quantity,
    bool? isActive,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantity: quantity ?? this.quantity,
      isActive: isActive ?? this.isActive,
    );
  }

  bool isValidForDate(String yyyyMmDd) {
    if (!isActive || quantity <= 0) return false;
    return yyyyMmDd.compareTo(startDate) >= 0 && yyyyMmDd.compareTo(endDate) <= 0;
  }

  double calculateDiscount(double subtotal) {
    double discount = subtotal * discountPercent / 100.0;
    if (maxDiscount > 0 && discount > maxDiscount) {
      discount = maxDiscount;
    }
    return discount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountPercent': discountPercent,
      'maxDiscount': maxDiscount,
      'startDate': startDate,
      'endDate': endDate,
      'quantity': quantity,
      'isActive': isActive,
    };
  }

  factory PromotionModel.fromMap(Map<String, dynamic> map, String id) {
    return PromotionModel(
      id: id,
      code: map['code'] ?? '',
      description: map['description'],
      discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}

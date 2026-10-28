class FieldPricingRuleModel {
  final String id;
  final String fieldId;
  final String name;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final String dayType;   // "All" | "Weekday" | "Weekend"
  final int? startMonth;  // 1 - 12
  final int? endMonth;    // 1 - 12
  final double price;     // Giá cố định hoặc base price
  final double priceMultiplier; // Hệ số giá (VD: 1.2, 0.8)
  final double? fixedPrice;
  final int priority;
  final bool isActive;
  final DateTime? createdAt;

  FieldPricingRuleModel({
    required this.id,
    required this.fieldId,
    String? name,
    String? ruleName,
    String? startTime,
    String? endTime,
    int? startHour,
    int? endHour,
    this.dayType = 'All',
    this.startMonth,
    this.endMonth,
    double? price,
    this.priceMultiplier = 1.0,
    this.fixedPrice,
    this.priority = 0,
    this.isActive = true,
    this.createdAt,
  })  : name = name ?? ruleName ?? 'Quy tắc định giá',
        startTime = startTime ?? (startHour != null ? '${startHour.toString().padLeft(2, '0')}:00' : '06:00'),
        endTime = endTime ?? (endHour != null ? '${endHour.toString().padLeft(2, '0')}:00' : '22:00'),
        price = price ?? fixedPrice ?? 0.0;

  String? get ruleName => name;
  int get startHour => int.tryParse(startTime.split(':')[0]) ?? 0;
  int get endHour => int.tryParse(endTime.split(':')[0]) ?? 23;

  FieldPricingRuleModel copyWith({
    String? id,
    String? fieldId,
    String? name,
    String? startTime,
    String? endTime,
    int? startHour,
    int? endHour,
    String? dayType,
    int? startMonth,
    int? endMonth,
    double? price,
    double? priceMultiplier,
    double? fixedPrice,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return FieldPricingRuleModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startHour: startHour,
      endHour: endHour,
      dayType: dayType ?? this.dayType,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
      price: price ?? this.price,
      priceMultiplier: priceMultiplier ?? this.priceMultiplier,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'name': name,
      'ruleName': name,
      'startTime': startTime,
      'endTime': endTime,
      'startHour': startHour,
      'endHour': endHour,
      'dayType': dayType,
      'startMonth': startMonth,
      'endMonth': endMonth,
      'price': price,
      'priceMultiplier': priceMultiplier,
      'fixedPrice': fixedPrice,
      'priority': priority,
      'isActive': isActive,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory FieldPricingRuleModel.fromMap(Map<String, dynamic> map, String id) {
    final sTime = map['startTime'] as String?;
    final sHour = (map['startHour'] as num?)?.toInt();
    final eTime = map['endTime'] as String?;
    final eHour = (map['endHour'] as num?)?.toInt();

    return FieldPricingRuleModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      name: map['name'] ?? map['ruleName'],
      startTime: sTime ?? (sHour != null ? '${sHour.toString().padLeft(2, '0')}:00' : '06:00'),
      endTime: eTime ?? (eHour != null ? '${eHour.toString().padLeft(2, '0')}:00' : '22:00'),
      dayType: map['dayType'] ?? 'All',
      startMonth: (map['startMonth'] as num?)?.toInt(),
      endMonth: (map['endMonth'] as num?)?.toInt(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      priceMultiplier: (map['priceMultiplier'] as num?)?.toDouble() ?? 1.0,
      fixedPrice: (map['fixedPrice'] as num?)?.toDouble(),
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }
}

class TimeSlotModel {
  final String id;
  final String fieldId;
  final String startTime;
  final String endTime;
  final double price;
  final bool isActive;

  TimeSlotModel({
    required this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    this.price = 0.0,
    this.isActive = true,
  });

  bool get isPeak {
    final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
    return hour >= 17 && hour < 21;
  }

  TimeSlotModel copyWith({
    String? id,
    String? fieldId,
    String? startTime,
    String? endTime,
    double? price,
    bool? isActive,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'isActive': isActive,
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map, String id) {
    return TimeSlotModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
    );
  }
}

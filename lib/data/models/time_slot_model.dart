class TimeSlotModel {
  final String id;
  final String fieldId;
  final String startTime;
  final String endTime;
  final bool isActive;

  TimeSlotModel({
    required this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  bool get isPeak {
    final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
    return hour >= 17 && hour < 21;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map, String id) {
    return TimeSlotModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

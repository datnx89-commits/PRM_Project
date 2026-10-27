class BookingDetailModel {
  final String id;
  final String bookingId;
  final String fieldId;
  final String? fieldName;
  final String timeSlotId;
  final String? slotTime;
  final String bookingDate;
  final double price;
  final String status;

  BookingDetailModel({
    required this.id,
    required this.bookingId,
    required this.fieldId,
    this.fieldName,
    required this.timeSlotId,
    this.slotTime,
    required this.bookingDate,
    required this.price,
    this.status = 'Active',
  });

  BookingDetailModel copyWith({
    String? id,
    String? bookingId,
    String? fieldId,
    String? fieldName,
    String? timeSlotId,
    String? slotTime,
    String? bookingDate,
    double? price,
    String? status,
  }) {
    return BookingDetailModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      slotTime: slotTime ?? this.slotTime,
      bookingDate: bookingDate ?? this.bookingDate,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'timeSlotId': timeSlotId,
      'slotTime': slotTime,
      'bookingDate': bookingDate,
      'price': price,
      'status': status,
    };
  }

  factory BookingDetailModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingDetailModel(
      id: id,
      bookingId: map['bookingId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      fieldName: map['fieldName'],
      timeSlotId: map['timeSlotId'] ?? '',
      slotTime: map['slotTime'],
      bookingDate: map['bookingDate'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
    );
  }
}

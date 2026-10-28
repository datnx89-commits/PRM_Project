import 'booking_detail_model.dart';
import 'payment_model.dart';
import 'review_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final String? userEmail;
  final String? userFullName;
  final String? userPhone;
  final String fieldId;
  final String? fieldName;
  final String? fieldAddress;
  final String? fieldImage;
  final String? ownerId;
  final String timeSlotId;
  final String? startTime;
  final String? endTime;
  final String bookingDate; // "yyyy-MM-dd"
  final String? promotionId;
  final String? promotionCode;
  final String status; // Pending | Confirmed | Completed | Cancelled
  final double unitPrice;
  final double discountAmount;
  final int pointsUsed;
  final int pointsEarned;
  final double totalAmount;
  final String? paymentMethod; // Wallet | VNPay | Momo | Cash
  final String? paymentStatus; // Pending | Paid | Refunded | Failed
  final DateTime? paidAt;
  final String? note;
  final String? createdById; // null = khách tự đặt; có id = Owner/Admin đặt hộ
  final DateTime createdAt;

  // Navigation / Aggregated properties
  final List<BookingDetailModel> details;
  final PaymentModel? payment;
  final ReviewModel? review;

  BookingModel({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.userPhone,
    this.fieldId = '',
    this.fieldName,
    this.fieldAddress,
    this.fieldImage,
    this.ownerId,
    this.timeSlotId = '',
    this.startTime,
    this.endTime,
    this.bookingDate = '',
    this.promotionId,
    this.promotionCode,
    this.status = 'Pending',
    this.unitPrice = 0.0,
    this.discountAmount = 0.0,
    this.pointsUsed = 0,
    this.pointsEarned = 0,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.paidAt,
    this.note,
    this.createdById,
    required this.createdAt,
    this.details = const [],
    this.payment,
    this.review,
  });

  String get slotTimeText {
    if (startTime != null && endTime != null && startTime!.isNotEmpty) {
      return '$startTime - $endTime';
    }
    if (details.isNotEmpty && details.first.slotTime != null) {
      return details.first.slotTime!;
    }
    return '';
  }

  String get effectiveFieldName {
    if (fieldName != null && fieldName!.isNotEmpty) return fieldName!;
    if (details.isNotEmpty && details.first.fieldName != null) return details.first.fieldName!;
    return 'Sân thể thao';
  }

  String get effectiveBookingDate {
    if (bookingDate.isNotEmpty) return bookingDate;
    if (details.isNotEmpty) return details.first.bookingDate;
    return '';
  }

  bool get isPaid => paymentStatus == 'Paid' || payment?.status == 'Paid';
  bool get isCashPending =>
      paymentMethod == 'Cash' &&
      (paymentStatus == 'Pending' || paymentStatus == null || payment?.status == 'Pending');

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userFullName,
    String? userPhone,
    String? fieldId,
    String? fieldName,
    String? fieldAddress,
    String? fieldImage,
    String? ownerId,
    String? timeSlotId,
    String? startTime,
    String? endTime,
    String? bookingDate,
    String? promotionId,
    String? promotionCode,
    String? status,
    double? unitPrice,
    double? discountAmount,
    int? pointsUsed,
    int? pointsEarned,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? paidAt,
    String? note,
    String? createdById,
    DateTime? createdAt,
    List<BookingDetailModel>? details,
    PaymentModel? payment,
    ReviewModel? review,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userFullName: userFullName ?? this.userFullName,
      userPhone: userPhone ?? this.userPhone,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      fieldAddress: fieldAddress ?? this.fieldAddress,
      fieldImage: fieldImage ?? this.fieldImage,
      ownerId: ownerId ?? this.ownerId,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bookingDate: bookingDate ?? this.bookingDate,
      promotionId: promotionId ?? this.promotionId,
      promotionCode: promotionCode ?? this.promotionCode,
      status: status ?? this.status,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      details: details ?? this.details,
      payment: payment ?? this.payment,
      review: review ?? this.review,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
      'userPhone': userPhone,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'fieldAddress': fieldAddress,
      'fieldImage': fieldImage,
      'ownerId': ownerId,
      'timeSlotId': timeSlotId,
      'startTime': startTime,
      'endTime': endTime,
      'bookingDate': bookingDate,
      'promotionId': promotionId,
      'promotionCode': promotionCode,
      'status': status,
      'unitPrice': unitPrice,
      'discountAmount': discountAmount,
      'pointsUsed': pointsUsed,
      'pointsEarned': pointsEarned,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paidAt': paidAt?.toIso8601String(),
      'note': note,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id, {
    List<BookingDetailModel> details = const [],
    PaymentModel? payment,
    ReviewModel? review,
  }) {
    // Nếu có details cũ, lấy fallback thông tin sân từ detail đầu tiên
    final dFirst = details.isNotEmpty ? details.first : null;
    final fId = (map['fieldId'] as String?)?.isNotEmpty == true
        ? map['fieldId'] as String
        : (dFirst?.fieldId ?? '');
    final fName = map['fieldName'] as String? ?? dFirst?.fieldName;
    final tId = (map['timeSlotId'] as String?)?.isNotEmpty == true
        ? map['timeSlotId'] as String
        : (dFirst?.timeSlotId ?? '');
    final bDate = (map['bookingDate'] as String?)?.isNotEmpty == true
        ? map['bookingDate'] as String
        : (dFirst?.bookingDate ?? '');

    String? sTime = map['startTime'];
    String? eTime = map['endTime'];
    if ((sTime == null || sTime.isEmpty) && dFirst?.slotTime != null) {
      final parts = dFirst!.slotTime!.split('-');
      if (parts.length == 2) {
        sTime = parts[0].trim();
        eTime = parts[1].trim();
      }
    }

    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      userFullName: map['userFullName'],
      userPhone: map['userPhone'],
      fieldId: fId,
      fieldName: fName,
      fieldAddress: map['fieldAddress'],
      fieldImage: map['fieldImage'],
      ownerId: map['ownerId'],
      timeSlotId: tId,
      startTime: sTime,
      endTime: eTime,
      bookingDate: bDate,
      promotionId: map['promotionId'],
      promotionCode: map['promotionCode'],
      status: map['status'] ?? 'Pending',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      pointsUsed: (map['pointsUsed'] as num?)?.toInt() ?? 0,
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? payment?.method,
      paymentStatus: map['paymentStatus'] ?? payment?.status,
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt']) : payment?.paidAt,
      note: map['note'],
      createdById: map['createdById'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      details: details,
      payment: payment,
      review: review,
    );
  }
}

import 'booking_detail_model.dart';
import 'payment_model.dart';
import 'review_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final String? userEmail;
  final String? userFullName;
  final String? promotionId;
  final String? promotionCode;
  final String status;
  final double totalAmount;
  final String? note;
  final DateTime createdAt;
  final List<BookingDetailModel> details;
  final PaymentModel? payment;
  final ReviewModel? review;

  BookingModel({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.promotionId,
    this.promotionCode,
    this.status = 'Pending',
    required this.totalAmount,
    this.note,
    required this.createdAt,
    this.details = const [],
    this.payment,
    this.review,
  });

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userFullName,
    String? promotionId,
    String? promotionCode,
    String? status,
    double? totalAmount,
    String? note,
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
      promotionId: promotionId ?? this.promotionId,
      promotionCode: promotionCode ?? this.promotionCode,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
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
      'promotionId': promotionId,
      'promotionCode': promotionCode,
      'status': status,
      'totalAmount': totalAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id, {
    List<BookingDetailModel> details = const [],
    PaymentModel? payment,
    ReviewModel? review,
  }) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      userFullName: map['userFullName'],
      promotionId: map['promotionId'],
      promotionCode: map['promotionCode'],
      status: map['status'] ?? 'Pending',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      details: details,
      payment: payment,
      review: review,
    );
  }
}

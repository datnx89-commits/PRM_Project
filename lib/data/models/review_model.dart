class ReviewModel {
  final String id;
  final String fieldId;
  final String userId;
  final String? userFullName;
  final String bookingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.fieldId,
    required this.userId,
    this.userFullName,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'userId': userId,
      'userFullName': userFullName,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      userId: map['userId'] ?? '',
      userFullName: map['userFullName'],
      bookingId: map['bookingId'] ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

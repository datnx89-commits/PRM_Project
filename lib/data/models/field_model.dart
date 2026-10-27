class FieldModel {
  final String id;
  final String fieldName;
  final String fieldTypeId;
  final String? fieldTypeName;
  final String ownerId;
  final String address;
  final String district;
  final String city;
  final double pricePerHour;
  final double peakPricePerHour;
  final String? description;
  final String status;
  final DateTime createdAt;
  final double averageRating;

  FieldModel({
    required this.id,
    required this.fieldName,
    required this.fieldTypeId,
    this.fieldTypeName,
    required this.ownerId,
    required this.address,
    required this.district,
    required this.city,
    required this.pricePerHour,
    required this.peakPricePerHour,
    this.description,
    this.status = 'Active',
    required this.createdAt,
    this.averageRating = 0.0,
  });

  FieldModel copyWith({
    String? id,
    String? fieldName,
    String? fieldTypeId,
    String? fieldTypeName,
    String? ownerId,
    String? address,
    String? district,
    String? city,
    double? pricePerHour,
    double? peakPricePerHour,
    String? description,
    String? status,
    DateTime? createdAt,
    double? averageRating,
  }) {
    return FieldModel(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      fieldTypeId: fieldTypeId ?? this.fieldTypeId,
      fieldTypeName: fieldTypeName ?? this.fieldTypeName,
      ownerId: ownerId ?? this.ownerId,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      peakPricePerHour: peakPricePerHour ?? this.peakPricePerHour,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldName': fieldName,
      'fieldTypeId': fieldTypeId,
      'fieldTypeName': fieldTypeName,
      'ownerId': ownerId,
      'address': address,
      'district': district,
      'city': city,
      'pricePerHour': pricePerHour,
      'peakPricePerHour': peakPricePerHour,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'averageRating': averageRating,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map, String id) {
    return FieldModel(
      id: id,
      fieldName: map['fieldName'] ?? '',
      fieldTypeId: map['fieldTypeId'] ?? '',
      fieldTypeName: map['fieldTypeName'],
      ownerId: map['ownerId'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? '',
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      peakPricePerHour: (map['peakPricePerHour'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

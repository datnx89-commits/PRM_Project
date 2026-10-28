class FieldModel {
  final String id;
  final String fieldName;
  final String fieldTypeId;
  final String? fieldTypeName;
  final String ownerId;
  final String address;
  final String ward;
  final String province;
  // district và city giữ tương thích ngược
  final String district;
  final String city;
  final double pricePerHour;
  final double peakPricePerHour;
  final bool acceptWalletPayment;
  final int cashbackPercent;
  final String? description;
  final String status; // Active | Maintenance | Closed
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final DateTime createdAt;
  final double averageRating;

  FieldModel({
    required this.id,
    required this.fieldName,
    required this.fieldTypeId,
    this.fieldTypeName,
    required this.ownerId,
    required this.address,
    this.ward = '',
    this.province = '',
    this.district = '',
    this.city = '',
    required this.pricePerHour,
    required this.peakPricePerHour,
    this.acceptWalletPayment = false,
    this.cashbackPercent = 0,
    this.description,
    this.status = 'Active',
    this.latitude,
    this.longitude,
    this.images = const [],
    required this.createdAt,
    this.averageRating = 0.0,
  });

  String get name => fieldName;

  String get fullAddress {
    final parts = [address, ward.isNotEmpty ? ward : district, province.isNotEmpty ? province : city]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String? get primaryImageUrl => images.isNotEmpty ? images.first : null;

  FieldModel copyWith({
    String? id,
    String? fieldName,
    String? fieldTypeId,
    String? fieldTypeName,
    String? ownerId,
    String? address,
    String? ward,
    String? province,
    String? district,
    String? city,
    double? pricePerHour,
    double? peakPricePerHour,
    bool? acceptWalletPayment,
    int? cashbackPercent,
    String? description,
    String? status,
    double? latitude,
    double? longitude,
    List<String>? images,
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
      ward: ward ?? this.ward,
      province: province ?? this.province,
      district: district ?? this.district,
      city: city ?? this.city,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      peakPricePerHour: peakPricePerHour ?? this.peakPricePerHour,
      acceptWalletPayment: acceptWalletPayment ?? this.acceptWalletPayment,
      cashbackPercent: cashbackPercent ?? this.cashbackPercent,
      description: description ?? this.description,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
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
      'ward': ward,
      'province': province,
      'district': district.isNotEmpty ? district : ward,
      'city': city.isNotEmpty ? city : province,
      'pricePerHour': pricePerHour,
      'peakPricePerHour': peakPricePerHour,
      'acceptWalletPayment': acceptWalletPayment,
      'cashbackPercent': cashbackPercent,
      'description': description,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'averageRating': averageRating,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map, String id) {
    final rawImages = map['images'];
    List<String> imgList = [];
    if (rawImages is List) {
      imgList = rawImages.map((e) => e.toString()).toList();
    }

    final pWard = map['ward'] as String? ?? '';
    final pProv = map['province'] as String? ?? '';
    final pDist = map['district'] as String? ?? '';
    final pCity = map['city'] as String? ?? '';

    return FieldModel(
      id: id,
      fieldName: map['fieldName'] ?? '',
      fieldTypeId: map['fieldTypeId'] ?? '',
      fieldTypeName: map['fieldTypeName'],
      ownerId: map['ownerId'] ?? '',
      address: map['address'] ?? '',
      ward: pWard.isNotEmpty ? pWard : pDist,
      province: pProv.isNotEmpty ? pProv : pCity,
      district: pDist.isNotEmpty ? pDist : pWard,
      city: pCity.isNotEmpty ? pCity : pProv,
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      peakPricePerHour: (map['peakPricePerHour'] as num?)?.toDouble() ?? 0.0,
      acceptWalletPayment: map['acceptWalletPayment'] as bool? ?? false,
      cashbackPercent: (map['cashbackPercent'] as num?)?.toInt() ?? 0,
      description: map['description'],
      status: map['status'] ?? 'Active',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      images: imgList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

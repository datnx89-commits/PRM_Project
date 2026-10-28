import '../../core/config/app_config.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final double walletBalance;
  final int points;
  final int lifetimePoints;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isActive = true,
    this.walletBalance = 0.0,
    this.points = 0,
    this.lifetimePoints = 0,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    required this.createdAt,
    String? tier, // Tương thích khi truyền tier vào constructor
  });

  String get tier => AppConfig.getMembershipTier(lifetimePoints).name;
  MembershipTier get membershipTier => AppConfig.getMembershipTier(lifetimePoints);

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
    double? walletBalance,
    int? points,
    int? lifetimePoints,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolder,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      walletBalance: walletBalance ?? this.walletBalance,
      points: points ?? this.points,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'walletBalance': walletBalance,
      'points': points,
      'lifetimePoints': lifetimePoints,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolder': bankAccountHolder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'Customer',
      isActive: map['isActive'] ?? true,
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      points: (map['points'] as num?)?.toInt() ?? 0,
      lifetimePoints: (map['lifetimePoints'] as num?)?.toInt() ?? 0,
      bankName: map['bankName'],
      bankAccountNumber: map['bankAccountNumber'],
      bankAccountHolder: map['bankAccountHolder'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

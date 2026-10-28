class MaintenanceRequestModel {
  final String id;
  final String fieldId;
  final String? fieldName;
  final String ownerId;
  final String? ownerName;
  final String reason;
  final String startDate; // "yyyy-MM-dd"
  final String endDate;   // "yyyy-MM-dd"
  final String status;    // Pending | Approved | Rejected
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  MaintenanceRequestModel({
    required this.id,
    required this.fieldId,
    this.fieldName,
    required this.ownerId,
    this.ownerName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.status = 'Pending',
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  MaintenanceRequestModel copyWith({
    String? id,
    String? fieldId,
    String? fieldName,
    String? ownerId,
    String? ownerName,
    String? reason,
    String? startDate,
    String? endDate,
    String? status,
    String? adminNote,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return MaintenanceRequestModel(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      fieldName: fieldName ?? this.fieldName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'reason': reason,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'adminNote': adminNote,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory MaintenanceRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceRequestModel(
      id: id,
      fieldId: map['fieldId'] ?? '',
      fieldName: map['fieldName'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'],
      reason: map['reason'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      status: map['status'] ?? 'Pending',
      adminNote: map['adminNote'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      processedAt: map['processedAt'] != null
          ? DateTime.tryParse(map['processedAt'])
          : null,
    );
  }
}

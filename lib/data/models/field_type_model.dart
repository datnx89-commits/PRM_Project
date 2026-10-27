class FieldTypeModel {
  final String id;
  final String typeName;

  FieldTypeModel({
    required this.id,
    required this.typeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'typeName': typeName,
    };
  }

  factory FieldTypeModel.fromMap(Map<String, dynamic> map, String id) {
    return FieldTypeModel(
      id: id,
      typeName: map['typeName'] ?? '',
    );
  }
}

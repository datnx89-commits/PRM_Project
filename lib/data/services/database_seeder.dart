import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../models/field_model.dart';
import '../models/field_type_model.dart';
import '../models/promotion_model.dart';
import '../models/time_slot_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class DatabaseSeeder {
  final FirebaseService _firebase = FirebaseService();

  Future<void> seedAll({void Function(String)? onProgress}) async {
    onProgress?.call('Bắt đầu khởi tạo tài khoản Auth...');
    final staffUid = await _seedUsers(onProgress);

    onProgress?.call('Khởi tạo loại sân...');
    final typeIds = await _seedFieldTypes(onProgress);

    onProgress?.call('Khởi tạo sân bóng và 16 khung giờ...');
    await _seedFieldsAndSlots(staffUid, typeIds, onProgress);

    onProgress?.call('Khởi tạo mã khuyến mãi...');
    await _seedPromotions(onProgress);

    try {
      await _firebase.auth.signOut();
    } catch (_) {}

    onProgress?.call('Hoàn thành toàn bộ quá trình nạp dữ liệu mẫu!');
  }

  Future<String> _seedUsers(void Function(String)? onProgress) async {
    final accounts = [
      ('admin@sfb.com', '123456', 'Quản trị viên', '0900000001', UserRole.admin),
      ('staff@sfb.com', '123456', 'Nguyễn Chủ Sân', '0900000002', UserRole.staff),
      ('customer@sfb.com', '123456', 'Trần Văn Khách', '0900000003', UserRole.customer),
      ('hoa@gmail.com', '123456', 'Lê Thị Hoa', '0900000004', UserRole.customer),
    ];

    String staffUid = '';

    for (var acc in accounts) {
      final email = acc.$1;
      final password = acc.$2;
      final fullName = acc.$3;
      final phone = acc.$4;
      final role = acc.$5;

      String uid = '';
      try {
        final credential = await _firebase.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = credential.user?.uid ?? '';
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            final credential = await _firebase.auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            uid = credential.user?.uid ?? '';
          } catch (_) {}
        }
      }

      if (uid.isNotEmpty) {
        if (role == UserRole.staff) {
          staffUid = uid;
        }

        final user = UserModel(
          id: uid,
          email: email,
          fullName: fullName,
          phone: phone,
          role: role,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await _firebase.usersCollection.doc(uid).set(user.toMap());
        onProgress?.call('Đã nạp user: $email ($role)');
      }
    }

    return staffUid;
  }

  Future<Map<String, String>> _seedFieldTypes(void Function(String)? onProgress) async {
    final types = [
      ('type_football', 'Bóng đá'),
      ('type_badminton', 'Cầu lông'),
      ('type_tennis', 'Tennis'),
      ('type_basketball', 'Bóng rổ'),
    ];

    final Map<String, String> result = {};

    for (var t in types) {
      final docId = t.$1;
      final typeName = t.$2;
      final model = FieldTypeModel(id: docId, typeName: typeName);
      await _firebase.fieldTypesCollection.doc(docId).set(model.toMap());
      result[typeName] = docId;
      onProgress?.call('Đã nạp loại sân: $typeName');
    }

    return result;
  }

  Future<void> _seedFieldsAndSlots(
    String staffUid,
    Map<String, String> typeIds,
    void Function(String)? onProgress,
  ) async {
    final fieldsData = [
      (
        'field_1',
        'Sân bóng Thống Nhất',
        typeIds['Bóng đá'] ?? 'type_football',
        'Bóng đá',
        '123 Lê Lợi',
        'Quận 1',
        'TP.HCM',
        300000.0,
        450000.0,
        'Sân cỏ nhân tạo 7 người, có đèn chiếu sáng',
      ),
      (
        'field_2',
        'Sân cầu lông Victory',
        typeIds['Cầu lông'] ?? 'type_badminton',
        'Cầu lông',
        '45 Nguyễn Huệ',
        'Quận 3',
        'TP.HCM',
        80000.0,
        120000.0,
        '4 sân thi đấu chuẩn, sàn gỗ',
      ),
      (
        'field_3',
        'Sân tennis Sao Mai',
        typeIds['Tennis'] ?? 'type_tennis',
        'Tennis',
        '78 Trần Hưng Đạo',
        'Cầu Giấy',
        'Hà Nội',
        200000.0,
        300000.0,
        'Sân cứng ngoài trời, có mái che',
      ),
      (
        'field_4',
        'Sân bóng rổ Phoenix',
        typeIds['Bóng rổ'] ?? 'type_basketball',
        'Bóng rổ',
        '12 Hai Bà Trưng',
        'Hoàn Kiếm',
        'Hà Nội',
        150000.0,
        220000.0,
        'Sân trong nhà, điều hòa',
      ),
    ];

    for (var f in fieldsData) {
      final fieldId = f.$1;
      final name = f.$2;
      final typeId = f.$3;
      final typeName = f.$4;
      final address = f.$5;
      final district = f.$6;
      final city = f.$7;
      final price = f.$8;
      final peakPrice = f.$9;
      final desc = f.$10;

      final field = FieldModel(
        id: fieldId,
        fieldName: name,
        fieldTypeId: typeId,
        fieldTypeName: typeName,
        ownerId: staffUid.isNotEmpty ? staffUid : 'owner_demo',
        address: address,
        district: district,
        city: city,
        pricePerHour: price,
        peakPricePerHour: peakPrice,
        description: desc,
        status: FieldStatus.active,
        createdAt: DateTime.now(),
        averageRating: 5.0,
      );

      await _firebase.fieldsCollection.doc(fieldId).set(field.toMap());

      final batch = _firebase.firestore.batch();
      for (int h = 6; h < 22; h++) {
        final slotId = '${fieldId}_slot_${h.toString().padLeft(2, '0')}';
        final startStr = '${h.toString().padLeft(2, '0')}:00';
        final endStr = '${(h + 1).toString().padLeft(2, '0')}:00';
        final slot = TimeSlotModel(
          id: slotId,
          fieldId: fieldId,
          startTime: startStr,
          endTime: endStr,
          isActive: true,
        );
        batch.set(_firebase.timeSlotsCollection.doc(slotId), slot.toMap());
      }
      await batch.commit();

      onProgress?.call('Đã nạp sân: $name kèm 16 khung giờ (06:00-22:00)');
    }
  }

  Future<void> _seedPromotions(void Function(String)? onProgress) async {
    final promos = [
      PromotionModel(
        id: 'promo_summer',
        code: 'SUMMER26',
        description: 'Giảm 20% mùa hè',
        discountPercent: 20,
        maxDiscount: 100000,
        startDate: '2026-01-01',
        endDate: '2026-12-31',
        quantity: 100,
        isActive: true,
      ),
      PromotionModel(
        id: 'promo_newbie',
        code: 'NEWBIE10',
        description: 'Giảm 10% khách hàng mới',
        discountPercent: 10,
        maxDiscount: 50000,
        startDate: '2026-01-01',
        endDate: '2026-12-31',
        quantity: 500,
        isActive: true,
      ),
    ];

    for (var p in promos) {
      await _firebase.promotionsCollection.doc(p.id).set(p.toMap());
      onProgress?.call('Đã nạp voucher: ${p.code} (-${p.discountPercent}%)');
    }
  }
}

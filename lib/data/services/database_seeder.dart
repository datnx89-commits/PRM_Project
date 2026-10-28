import 'package:firebase_auth/firebase_auth.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/field_model.dart';
import '../models/field_pricing_rule_model.dart';
import '../models/field_type_model.dart';
import '../models/golden_day_model.dart';
import '../models/point_transaction_model.dart';
import '../models/promotion_model.dart';
import '../models/time_slot_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import 'firebase_service.dart';

class DatabaseSeeder {
  final FirebaseService _firebase = FirebaseService();

  Future<void> seedAll({void Function(String)? onProgress}) async {
    onProgress?.call('Bắt đầu khởi tạo tài khoản Auth & Ví...');
    final uids = await _seedUsers(onProgress);

    onProgress?.call('Khởi tạo loại sân thể thao...');
    final typeIds = await _seedFieldTypes(onProgress);

    final ownerUid = uids['owner@sfb.com'] ?? uids['staff@sfb.com'] ?? '';
    onProgress?.call('Khởi tạo sân bóng, 16 khung giờ & quy tắc định giá...');
    await _seedFieldsAndSlots(ownerUid, typeIds, onProgress);

    onProgress?.call('Khởi tạo quy tắc giá & Ngày Vàng mẫu...');
    await _seedPricingRulesAndGoldenDays(onProgress);

    onProgress?.call('Khởi tạo mã khuyến mãi...');
    await _seedPromotions(onProgress);

    try {
      await _firebase.auth.signOut();
    } catch (_) {}

    onProgress?.call('Hoàn thành toàn bộ quá trình nạp dữ liệu mẫu!');
  }

  Future<Map<String, String>> _seedUsers(void Function(String)? onProgress) async {
    final accounts = [
      ('admin@sfb.com', '123456', 'Quản trị viên Hệ thống', '0900000001', UserRole.admin, 2000000.0, 1000, 1000),
      ('owner@sfb.com', '123456', 'Nguyễn Chủ Sân', '0900000002', UserRole.owner, 1000000.0, 500, 500),
      ('staff@sfb.com', '123456', 'Trần Quản Lý Sân', '0900000003', UserRole.owner, 500000.0, 200, 200),
      ('customer@sfb.com', '123456', 'Lê Khách Hàng VIP', '0900000004', UserRole.customer, 650000.0, 650, 650),
      ('hoa@gmail.com', '123456', 'Vũ Thị Hoa', '0900000005', UserRole.customer, 200000.0, 80, 80),
    ];

    final Map<String, String> uids = {};

    for (var acc in accounts) {
      final email = acc.$1;
      final password = acc.$2;
      final fullName = acc.$3;
      final phone = acc.$4;
      final role = acc.$5;
      final initialBalance = acc.$6;
      final points = acc.$7;
      final lifetimePoints = acc.$8;

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
        uids[email] = uid;

        // Tính hạng thành viên theo AppConfig
        final tier = AppConfig.getMembershipTier(lifetimePoints).name;

        final user = UserModel(
          id: uid,
          email: email,
          fullName: fullName,
          phone: phone,
          role: role,
          isActive: true,
          walletBalance: initialBalance,
          points: points,
          lifetimePoints: lifetimePoints,
          tier: tier,
          createdAt: DateTime.now(),
        );

        await _firebase.usersCollection.doc(uid).set(user.toMap());

        // Nạp bản ghi Ví ảo
        final wallet = WalletModel(
          id: uid,
          userId: uid,
          balance: initialBalance,
          updatedAt: DateTime.now(),
        );
        await _firebase.walletsCollection.doc(uid).set(wallet.toMap());

        // Nạp lịch sử giao dịch nạp ban đầu
        if (initialBalance > 0) {
          final txDoc = _firebase.walletTransactionsCollection.doc();
          final tx = WalletTransactionModel(
            id: txDoc.id,
            walletId: uid,
            amount: initialBalance,
            balanceAfter: initialBalance,
            type: WalletTxType.deposit,
            description: 'Khởi tạo số dư ví ban đầu',
            createdAt: DateTime.now(),
          );
          await txDoc.set(tx.toMap());
        }

        // Nạp lịch sử điểm thưởng ban đầu
        if (points > 0) {
          final ptDoc = _firebase.pointTransactionsCollection.doc();
          final pt = PointTransactionModel(
            id: ptDoc.id,
            userId: uid,
            points: points,
            type: PointTxType.earn,
            description: 'Tích lũy điểm khởi tạo hệ thống',
            createdAt: DateTime.now(),
          );
          await ptDoc.set(pt.toMap());
        }

        onProgress?.call('Đã nạp user: $email ($role, Tier: $tier, Ví: ${initialBalance.toInt()}đ, Điểm: $points)');
      }
    }

    return uids;
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
    String ownerUid,
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
        true,
        10,
        'Sân cỏ nhân tạo 7 người cao cấp, có đèn LED chiếu sáng ban đêm, bãi gửi xe rộng.',
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
        true,
        5,
        '4 sân thảm Yonex chuẩn thi đấu quốc tế, có điều hòa và quầy nước uống.',
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
        true,
        0,
        'Sân cứng ngoài trời, có mái che che mưa nắng, huấn luyện viên chuyên nghiệp.',
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
        false, // Không nhận ví, chỉ nhận tiền mặt
        0,
        'Sân gỗ bóng rổ tiêu chuẩn NBA trong nhà mát mẻ.',
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
      final acceptWallet = f.$10;
      final cashback = f.$11;
      final desc = f.$12;

      final field = FieldModel(
        id: fieldId,
        fieldName: name,
        fieldTypeId: typeId,
        fieldTypeName: typeName,
        ownerId: ownerUid.isNotEmpty ? ownerUid : 'owner_demo',
        address: address,
        district: district,
        city: city,
        pricePerHour: price,
        peakPricePerHour: peakPrice,
        acceptWalletPayment: acceptWallet,
        cashbackPercent: cashback,
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
        final isPeak = h >= 17 && h < 21;
        final slot = TimeSlotModel(
          id: slotId,
          fieldId: fieldId,
          startTime: startStr,
          endTime: endStr,
          price: isPeak ? peakPrice : price,
          isActive: true,
        );
        batch.set(_firebase.timeSlotsCollection.doc(slotId), slot.toMap());
      }
      await batch.commit();

      onProgress?.call('Đã nạp sân: $name (Ví: ${acceptWallet ? 'Bật' : 'Tắt'}, Cashback: ${cashback.toInt()}%)');
    }
  }

  Future<void> _seedPricingRulesAndGoldenDays(void Function(String)? onProgress) async {
    // 1. Quy tắc giá đa cấp cho sân 1
    final rule1 = FieldPricingRuleModel(
      id: 'rule_peak_night',
      fieldId: 'field_1',
      name: 'Giờ vàng cao điểm tối',
      dayType: PricingDayType.all,
      startHour: 17,
      endHour: 21,
      priceMultiplier: 1.3,
      priority: 10,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _firebase.pricingRulesCollection.doc(rule1.id).set(rule1.toMap());

    final rule2 = FieldPricingRuleModel(
      id: 'rule_weekend_morning',
      fieldId: 'field_1',
      name: 'Khuyến mãi sáng cuối tuần',
      dayType: PricingDayType.weekend,
      startHour: 6,
      endHour: 9,
      priceMultiplier: 0.85,
      priority: 5,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _firebase.pricingRulesCollection.doc(rule2.id).set(rule2.toMap());

    // 2. Ngày vàng mẫu
    final today = DateTime.now();
    final goldenDayToday = GoldenDayModel(
      id: 'golden_today',
      name: 'Ngày Vàng Thể Thao Siêu Ưu Đãi',
      date: DateTime(today.year, today.month, today.day),
      fieldId: 'field_1',
      priceMultiplier: 0.8, // Giảm 20%
      pointMultiplier: 2.0, // X2 tích điểm
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _firebase.goldenDaysCollection.doc(goldenDayToday.id).set(goldenDayToday.toMap());

    onProgress?.call('Đã nạp quy tắc giá & Ngày Vàng Thể Thao (Giảm 20%, x2 điểm)');
  }

  Future<void> _seedPromotions(void Function(String)? onProgress) async {
    final promos = [
      PromotionModel(
        id: 'promo_summer',
        code: 'SUMMER26',
        description: 'Giảm 20% mùa hè rực lửa',
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
        description: 'Giảm 10% cho khách hàng mới',
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

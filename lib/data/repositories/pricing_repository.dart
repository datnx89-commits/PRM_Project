import '../../core/pricing/pricing_engine.dart';
import '../models/field_pricing_rule_model.dart';
import '../models/golden_day_model.dart';
import '../models/time_slot_model.dart';
import '../services/firebase_service.dart';

class PricingRepository {
  final FirebaseService _firebase;

  PricingRepository(this._firebase);

  // ---------------- BẢNG GIÁ ĐA CẤP (FieldPricingRules) ----------------

  /// Lấy danh sách quy tắc giá của sân (sắp xếp theo priority giảm dần)
  Future<List<FieldPricingRuleModel>> getRules(String fieldId) async {
    final snapshot = await _firebase.pricingRulesCollection
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final list = snapshot.docs
        .map((d) => FieldPricingRuleModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => b.priority.compareTo(a.priority));
    return list;
  }

  Future<List<FieldPricingRuleModel>> getRulesForField(String fieldId) => getRules(fieldId);

  /// Thêm hoặc cập nhật quy tắc giá
  Future<(bool, String)> createOrUpdateRule(FieldPricingRuleModel rule) async {
    return addRule(rule);
  }

  /// Thêm quy tắc giá mới
  Future<(bool, String)> addRule(FieldPricingRuleModel rule) async {
    if (rule.startTime.compareTo(rule.endTime) >= 0) {
      return (false, 'Giờ kết thúc phải sau giờ bắt đầu.');
    }
    if ((rule.startMonth != null) != (rule.endMonth != null)) {
      return (false, 'Phải nhập đủ cả tháng bắt đầu và tháng kết thúc (hoặc bỏ trống cả hai).');
    }

    final docRef = rule.id.isNotEmpty
        ? _firebase.pricingRulesCollection.doc(rule.id)
        : _firebase.pricingRulesCollection.doc();
    final newRule = rule.copyWith(id: docRef.id, isActive: true);
    await docRef.set(newRule.toMap());
    return (true, 'Đã lưu quy tắc giá thành công.');
  }

  /// Xóa quy tắc giá
  Future<(bool, String)> deleteRule(String ruleId) async {
    await _firebase.pricingRulesCollection.doc(ruleId).delete();
    return (true, 'Đã xóa quy tắc giá.');
  }

  // ---------------- NGÀY VÀNG (GoldenDays) ----------------

  /// Lấy ngày vàng áp dụng cho sân vào 1 ngày cụ thể (ưu tiên ngày vàng riêng của sân)
  Future<GoldenDayModel?> getGoldenDay(String fieldId, String yyyyMmDd) async {
    final snapshot = await _firebase.goldenDaysCollection
        .where('date', isEqualTo: yyyyMmDd)
        .where('isActive', isEqualTo: true)
        .get();

    final all = snapshot.docs
        .map((d) => GoldenDayModel.fromMap(d.data(), d.id))
        .toList();

    // 1. Tìm ngày vàng riêng của sân
    final fieldSpecific = all.where((g) => g.fieldId == fieldId).toList();
    if (fieldSpecific.isNotEmpty) return fieldSpecific.first;

    // 2. Tìm ngày vàng toàn hệ thống (fieldId null hoặc rỗng)
    final global = all.where((g) => g.isGlobal).toList();
    if (global.isNotEmpty) return global.first;

    return null;
  }

  /// Lấy danh sách ngày vàng (Admin xem tất cả; Owner xem của sân mình + toàn hệ thống)
  Future<List<GoldenDayModel>> getGoldenDays({String? fieldId}) async {
    final snapshot = await _firebase.goldenDaysCollection.get();
    var list = snapshot.docs
        .map((d) => GoldenDayModel.fromMap(d.data(), d.id))
        .toList();

    if (fieldId != null && fieldId.isNotEmpty) {
      list = list.where((g) => g.isGlobal || g.fieldId == fieldId).toList();
    }

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<(bool, String)> createOrUpdateGoldenDay(GoldenDayModel day) => addGoldenDay(day);

  /// Thêm ngày vàng mới
  Future<(bool, String)> addGoldenDay(GoldenDayModel day) async {
    final docRef = day.id.isNotEmpty
        ? _firebase.goldenDaysCollection.doc(day.id)
        : _firebase.goldenDaysCollection.doc();
    final newDay = day.copyWith(id: docRef.id, isActive: true);
    await docRef.set(newDay.toMap());
    return (true, 'Đã lưu ngày vàng.');
  }

  /// Xóa ngày vàng
  Future<(bool, String)> deleteGoldenDay(String goldenDayId) async {
    await _firebase.goldenDaysCollection.doc(goldenDayId).delete();
    return (true, 'Đã xóa ngày vàng.');
  }

  // ---------------- QUẢN LÝ KHUNG GIỜ (TimeSlots) ----------------

  /// Lấy tất cả khung giờ của sân (kể cả đang tắt)
  Future<List<TimeSlotModel>> getAllTimeSlots(String fieldId) async {
    final snapshot = await _firebase.timeSlotsCollection
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final list = snapshot.docs
        .map((d) => TimeSlotModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  /// Bật/tắt khung giờ (không xóa để giữ lịch sử booking)
  Future<(bool, String)> toggleSlotStatus(String timeSlotId, bool isActive) async {
    await _firebase.timeSlotsCollection.doc(timeSlotId).update({
      'isActive': isActive,
    });
    return (true, isActive ? 'Đã mở lại khung giờ.' : 'Đã tắt khung giờ.');
  }

  Future<(bool, String)> toggleTimeSlot(String timeSlotId, String fieldId) async {
    final doc = await _firebase.timeSlotsCollection.doc(timeSlotId).get();
    if (!doc.exists || doc.data() == null) {
      return (false, 'Không tìm thấy khung giờ.');
    }
    final currentActive = doc.data()!['isActive'] as bool? ?? true;
    return toggleSlotStatus(timeSlotId, !currentActive);
  }

  /// Tính giá động cho một slot cụ thể
  Future<double> calculatePrice({
    required String fieldId,
    required DateTime bookingDate,
    required String startTime,
    required double basePrice,
  }) async {
    final dateStr =
        '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
    final rules = await getRules(fieldId);
    final goldenDay = await getGoldenDay(fieldId, dateStr);

    return PricingEngine.calculateSlotPrice(
      bookingDate: bookingDate,
      startTime: startTime,
      basePrice: basePrice,
      pricingRules: rules,
      goldenDay: goldenDay,
    );
  }
}

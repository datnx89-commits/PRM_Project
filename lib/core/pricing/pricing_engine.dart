import '../../data/models/field_model.dart';
import '../../data/models/field_pricing_rule_model.dart';
import '../../data/models/golden_day_model.dart';
import '../../data/models/time_slot_model.dart';

/// Strategy Pattern: Engine tính giá khung giờ của sân theo ngày cụ thể.
/// Thứ tự ưu tiên: Rule bảng giá khớp nhất (giờ + thứ + tháng/mùa, Priority cao nhất thắng)
/// -> fallback về giá cơ bản của sân (pricePerHour)
/// -> nhân hệ số ngày vàng (nếu ngày đó là ngày vàng) và làm tròn đến nghìn đồng.
class PricingEngine {
  /// So khớp Rule với khung giờ và ngày cụ thể
  static bool matches(FieldPricingRuleModel rule, TimeSlotModel slot, DateTime date) {
    if (!rule.isActive) return false;

    // So sánh thời gian (HH:mm)
    if (slot.startTime.compareTo(rule.startTime) < 0 || slot.startTime.compareTo(rule.endTime) >= 0) {
      return false;
    }

    // Thứ trong tuần: Thứ 7 (6) và CN (7) là Weekend
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (rule.dayType == 'Weekday' && isWeekend) return false;
    if (rule.dayType == 'Weekend' && !isWeekend) return false;

    // Khoảng tháng (mùa, hỗ trợ vắt qua năm như tháng 11 đến tháng 2)
    if (rule.startMonth != null && rule.endMonth != null) {
      final m = date.month;
      final sm = rule.startMonth!;
      final em = rule.endMonth!;
      final inRange = sm <= em
          ? (m >= sm && m <= em)
          : (m >= sm || m <= em);
      if (!inRange) return false;
    }

    return true;
  }

  /// Chọn quy tắc giá khớp nhất theo Strategy Pattern
  static FieldPricingRuleModel? findBestRule(
    List<FieldPricingRuleModel> rules,
    TimeSlotModel slot,
    DateTime date,
  ) {
    final matchedRules = rules.where((r) => matches(r, slot, date)).toList();
    if (matchedRules.isEmpty) return null;

    matchedRules.sort((a, b) {
      // 1. Priority cao nhất trước
      final pCompare = b.priority.compareTo(a.priority);
      if (pCompare != 0) return pCompare;

      // 2. Có giới hạn tháng (mùa) cụ thể hơn
      final aHasMonth = a.startMonth != null && a.endMonth != null ? 1 : 0;
      final bHasMonth = b.startMonth != null && b.endMonth != null ? 1 : 0;
      final mCompare = bHasMonth.compareTo(aHasMonth);
      if (mCompare != 0) return mCompare;

      // 3. Có giới hạn thứ cụ thể hơn (Weekday/Weekend so với All)
      final aSpecificDay = a.dayType != 'All' ? 1 : 0;
      final bSpecificDay = b.dayType != 'All' ? 1 : 0;
      return bSpecificDay.compareTo(aSpecificDay);
    });

    return matchedRules.first;
  }

  /// Lấy giá gốc của slot theo quy tắc (hoặc fallback giá cơ bản)
  static double getSlotBasePrice(
    FieldModel field,
    TimeSlotModel slot,
    DateTime date,
    List<FieldPricingRuleModel> rules,
  ) {
    final rule = findBestRule(rules, slot, date);
    if (rule != null) {
      return rule.price;
    }
    // Fallback: nếu slot có gắn isPeak thì dùng peakPricePerHour, còn lại dùng pricePerHour
    return slot.isPeak ? field.peakPricePerHour : field.pricePerHour;
  }

  /// Tính giá cuối cùng của 1 slot sau khi nhân hệ số ngày vàng (làm tròn nghìn đồng)
  static double calculateSlotFinalPrice({
    required FieldModel field,
    required TimeSlotModel slot,
    required DateTime date,
    required List<FieldPricingRuleModel> rules,
    GoldenDayModel? goldenDay,
  }) {
    double price = getSlotBasePrice(field, slot, date, rules);
    if (goldenDay != null && goldenDay.isActive && goldenDay.priceMultiplier > 0) {
      // Làm tròn nghìn đồng giống C#: Math.Round(price * goldenDay.PriceMultiplier / 1000m) * 1000m
      price = ((price * goldenDay.priceMultiplier) / 1000.0).round() * 1000.0;
    }
    return price;
  }

  /// Tính giá của 1 slot theo thông số linh hoạt
  static double calculateSlotPrice({
    required DateTime bookingDate,
    required String startTime,
    required double basePrice,
    required List<FieldPricingRuleModel> pricingRules,
    GoldenDayModel? goldenDay,
  }) {
    final slot = TimeSlotModel(
      id: '',
      fieldId: '',
      startTime: startTime,
      endTime: '',
      price: basePrice,
    );
    final field = FieldModel(
      id: '',
      ownerId: '',
      fieldName: '',
      fieldTypeId: '',
      address: '',
      pricePerHour: basePrice,
      peakPricePerHour: basePrice,
      createdAt: DateTime.now(),
    );
    return calculateSlotFinalPrice(
      field: field,
      slot: slot,
      date: bookingDate,
      rules: pricingRules,
      goldenDay: goldenDay,
    );
  }
}

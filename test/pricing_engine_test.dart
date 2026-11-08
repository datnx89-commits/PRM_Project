import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/core/pricing/pricing_engine.dart';
import 'package:sportsbook_36vn/data/models/field_model.dart';
import 'package:sportsbook_36vn/data/models/field_pricing_rule_model.dart';
import 'package:sportsbook_36vn/data/models/golden_day_model.dart';
import 'package:sportsbook_36vn/data/models/time_slot_model.dart';

void main() {
  final field = FieldModel(
    id: 'f1',
    fieldName: 'San test',
    fieldTypeId: 't1',
    ownerId: 'o1',
    address: 'a',
    pricePerHour: 100000,
    peakPricePerHour: 150000,
    createdAt: DateTime(2026, 1, 1),
  );

  TimeSlotModel slot(String start) =>
      TimeSlotModel(id: start, fieldId: 'f1', startTime: start, endTime: '');

  // 2026-11-09 la Thu 2, 2026-11-14 la Thu 7
  final weekday = DateTime(2026, 11, 9);
  final weekend = DateTime(2026, 11, 14);

  FieldPricingRuleModel rule({
    int startHour = 17,
    int endHour = 21,
    double multiplier = 1.0,
    double? fixedPrice,
    String dayType = 'All',
    int priority = 0,
    bool isActive = true,
  }) =>
      FieldPricingRuleModel(
        id: 'r',
        fieldId: 'f1',
        startHour: startHour,
        endHour: endHour,
        priceMultiplier: multiplier,
        fixedPrice: fixedPrice,
        dayType: dayType,
        priority: priority,
        isActive: isActive,
      );

  group('Gia co ban', () {
    test('Gio thuong lay gia thuong', () {
      expect(PricingEngine.getSlotBasePrice(field, slot('08:00'), weekday, []), 100000);
    });

    test('17h den truoc 21h lay gia cao diem', () {
      expect(PricingEngine.getSlotBasePrice(field, slot('17:00'), weekday, []), 150000);
      expect(PricingEngine.getSlotBasePrice(field, slot('20:00'), weekday, []), 150000);
      expect(PricingEngine.getSlotBasePrice(field, slot('21:00'), weekday, []), 100000);
    });
  });

  group('Quy tac gia', () {
    test('He so 1.2 nhan len gia cao diem, khong ve 0d', () {
      final price = PricingEngine.getSlotBasePrice(
          field, slot('18:00'), weekday, [rule(multiplier: 1.2)]);
      expect(price, 180000);
    });

    test('He so 0.8 giam gia', () {
      final price = PricingEngine.getSlotBasePrice(
          field, slot('18:00'), weekday, [rule(multiplier: 0.8)]);
      expect(price, 120000);
    });

    test('Gia co dinh uu tien hon he so', () {
      final price = PricingEngine.getSlotBasePrice(
          field, slot('18:00'), weekday, [rule(multiplier: 1.2, fixedPrice: 99000)]);
      expect(price, 99000);
    });

    test('Ngoai khung gio thi khong ap dung, gio ket thuc khong tinh', () {
      final rules = [rule(multiplier: 2.0)];
      expect(PricingEngine.getSlotBasePrice(field, slot('16:00'), weekday, rules), 100000);
      expect(PricingEngine.getSlotBasePrice(field, slot('21:00'), weekday, rules), 100000);
    });

    test('Quy tac Cuoi tuan chi ap dung T7, CN', () {
      final rules = [rule(multiplier: 2.0, dayType: 'Weekend')];
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekday, rules), 150000);
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekend, rules), 300000);
    });

    test('Quy tac Ngay thuong khong ap dung cuoi tuan', () {
      final rules = [rule(multiplier: 2.0, dayType: 'Weekday')];
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekday, rules), 300000);
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekend, rules), 150000);
    });

    test('Quy tac da tat thi bo qua', () {
      final rules = [rule(multiplier: 2.0, isActive: false)];
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekday, rules), 150000);
    });

    test('Nhieu quy tac trung gio thi priority cao nhat thang', () {
      final rules = [
        rule(multiplier: 2.0, priority: 1),
        rule(multiplier: 1.2, priority: 10),
      ];
      expect(PricingEngine.getSlotBasePrice(field, slot('18:00'), weekday, rules), 180000);
    });
  });

  group('Ngay vang', () {
    final golden = GoldenDayModel(
      id: 'g',
      name: 'Ngay vang',
      date: DateTime(2026, 11, 9),
      fieldId: 'f1',
      priceMultiplier: 0.85,
    );

    test('Nhan he so ngay vang, lam tron nghin dong', () {
      final price = PricingEngine.calculateSlotFinalPrice(
        field: field,
        slot: slot('08:00'),
        date: weekday,
        rules: [],
        goldenDay: golden,
      );
      expect(price, 85000);
    });

    test('Quy tac va ngay vang cung ap dung', () {
      final price = PricingEngine.calculateSlotFinalPrice(
        field: field,
        slot: slot('18:00'),
        date: weekday,
        rules: [rule(multiplier: 1.2)],
        goldenDay: golden,
      );
      expect(price, 153000); // 150000 x 1.2 x 0.85
    });
  });

  test('calculateSlotPrice (dat ho khach) dung gia cua khung gio lam gia co ban', () {
    final price = PricingEngine.calculateSlotPrice(
      bookingDate: weekday,
      startTime: '18:00',
      basePrice: 150000,
      pricingRules: [rule(multiplier: 1.2)],
    );
    expect(price, 180000);
  });
}

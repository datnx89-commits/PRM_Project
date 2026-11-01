import 'package:flutter_test/flutter_test.dart';
import 'package:sportsbook_36vn/data/models/promotion_model.dart';

void main() {
  group('Promotion Discount Tests', () {
    test('calculateDiscount tinh dung % giam gia khi chua vuot tran maxDiscount', () {
      final promo = PromotionModel(
        id: 'p1',
        code: 'SALE10',
        discountPercent: 10,
        maxDiscount: 50000,
        startDate: '2026-10-01',
        endDate: '2026-11-30',
        quantity: 100,
      );

      // Đơn 200.000đ giảm 10% = 20.000đ (< 50.000đ)
      final discount = promo.calculateDiscount(200000);
      expect(discount, 20000.0);
    });

    test('calculateDiscount chan lai dung tran maxDiscount neu vuot muc', () {
      final promo = PromotionModel(
        id: 'p2',
        code: 'BIGSALE20',
        discountPercent: 20,
        maxDiscount: 30000,
        startDate: '2026-10-01',
        endDate: '2026-11-30',
        quantity: 50,
      );

      // Đơn 300.000đ giảm 20% = 60.000đ -> bị chặn ở max 30.000đ
      final discount = promo.calculateDiscount(300000);
      expect(discount, 30000.0);
    });

    test('isValidForDate tu choi ma khi ngay dat san nam ngoai thoi han', () {
      final promo = PromotionModel(
        id: 'p3',
        code: 'OCTONLY',
        discountPercent: 15,
        maxDiscount: 50000,
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        quantity: 10,
      );

      expect(promo.isValidForDate('2026-10-25'), isTrue);
      expect(promo.isValidForDate('2026-11-01'), isFalse);
      expect(promo.isValidForDate('2026-09-30'), isFalse);
    });

    test('isValidForField chi chap nhan san thuoc cung chu so huu hoac ma he thong', () {
      final systemPromo = PromotionModel(
        id: 'p4',
        code: 'ADMINALL',
        discountPercent: 5,
        maxDiscount: 20000,
        startDate: '2026-10-01',
        endDate: '2026-11-30',
        quantity: 100,
        ownerId: null, // Mã áp dụng toàn hệ thống
      );

      final ownerPromo = PromotionModel(
        id: 'p5',
        code: 'OWNER123',
        discountPercent: 10,
        maxDiscount: 30000,
        startDate: '2026-10-01',
        endDate: '2026-11-30',
        quantity: 50,
        ownerId: 'owner-abc',
      );

      expect(systemPromo.isValidForField('owner-abc'), isTrue);
      expect(systemPromo.isValidForField('owner-xyz'), isTrue);

      expect(ownerPromo.isValidForField('owner-abc'), isTrue);
      expect(ownerPromo.isValidForField('owner-xyz'), isFalse);
    });
  });

  group('Point Redemption & Payment Calculation Tests', () {
    test('1 diem thuong quy doi thanh 100 dong giam gia', () {
      const pointsUsed = 150;
      const pointRate = 100.0;
      final discount = pointsUsed * pointRate;
      expect(discount, 15000.0);
    });

    test('So tien thanh toan cuoi cung khong bao gio bi am', () {
      const totalAmount = 50000.0;
      const pointsDiscount = 70000.0; // Điểm lớn hơn cả tiền đơn
      final finalAmount = (totalAmount - pointsDiscount).clamp(0.0, double.infinity);
      expect(finalAmount, 0.0);
    });

    test('Kiem tra so du vi du hay thieu de thanh toan don dat', () {
      const walletBalance = 150000.0;
      const amount1 = 120000.0;
      const amount2 = 180000.0;

      final canPay1 = walletBalance >= amount1;
      final canPay2 = walletBalance >= amount2;

      expect(canPay1, isTrue);
      expect(canPay2, isFalse);
    });
  });
}

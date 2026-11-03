import '../models/promotion_model.dart';
import '../services/firebase_service.dart';

class PromotionRepository {
  final FirebaseService _firebaseService;

  PromotionRepository(this._firebaseService);

  String? _validationError(PromotionModel promo) {
    if (promo.code.trim().isEmpty) return 'Vui lòng nhập mã khuyến mãi.';
    if (promo.discountPercent < 1 || promo.discountPercent > 100) {
      return 'Phần trăm giảm phải từ 1 đến 100.';
    }
    if (!promo.maxDiscount.isFinite || promo.maxDiscount < 0) {
      return 'Giảm tối đa phải lớn hơn hoặc bằng 0.';
    }
    if (promo.quantity < 0) return 'Số lượng mã không được âm.';
    final start = DateTime.tryParse(promo.startDate);
    final end = DateTime.tryParse(promo.endDate);
    if (start == null || end == null || end.isBefore(start)) {
      return 'Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.';
    }
    return null;
  }

  Future<List<PromotionModel>> getAllPromotions() async {
    final snapshot = await _firebaseService.promotionsCollection.get();
    final list = snapshot.docs
        .map((doc) => PromotionModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  Future<PromotionModel?> getPromotionById(String id) async {
    final doc = await _firebaseService.promotionsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PromotionModel.fromMap(doc.data()!, doc.id);
  }

  Future<PromotionModel?> getPromotionByCode(String code) async {
    final snapshot = await _firebaseService.promotionsCollection
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PromotionModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<(bool, String)> createPromotion(PromotionModel promo) async {
    final error = _validationError(promo);
    if (error != null) return (false, error);
    final existing = await getPromotionByCode(promo.code);
    if (existing != null) {
      return (false, 'Mã khuyến mãi đã tồn tại.');
    }
    final docRef = _firebaseService.promotionsCollection.doc();
    final toSave = promo.copyWith(id: docRef.id, code: promo.code.trim().toUpperCase());
    await docRef.set(toSave.toMap());
    return (true, 'Tạo khuyến mãi thành công.');
  }

  Future<(bool, String)> updatePromotion(PromotionModel promo) async {
    final error = _validationError(promo);
    if (error != null) return (false, error);
    final snapshot = await _firebaseService.promotionsCollection
        .where('code', isEqualTo: promo.code.trim().toUpperCase())
        .get();

    final duplicate = snapshot.docs.any((d) => d.id != promo.id);
    if (duplicate) {
      return (false, 'Mã khuyến mãi đã tồn tại.');
    }

    await _firebaseService.promotionsCollection.doc(promo.id).update(
      promo.copyWith(code: promo.code.trim().toUpperCase()).toMap(),
    );
    return (true, 'Cập nhật khuyến mãi thành công.');
  }

  Future<void> togglePromotionActive(String id) async {
    final promo = await getPromotionById(id);
    if (promo == null) return;
    await _firebaseService.promotionsCollection
        .doc(id)
        .update({'isActive': !promo.isActive});
  }
}

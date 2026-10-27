import '../models/promotion_model.dart';
import '../services/firebase_service.dart';

class PromotionRepository {
  final FirebaseService _firebaseService;

  PromotionRepository(this._firebaseService);

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
    final existing = await getPromotionByCode(promo.code);
    if (existing != null) {
      return (false, 'Mã khuyến mãi đã tồn tại.');
    }
    if (promo.endDate.compareTo(promo.startDate) < 0) {
      return (false, 'Ngày kết thúc phải sau ngày bắt đầu.');
    }

    final docRef = _firebaseService.promotionsCollection.doc();
    final toSave = promo.copyWith(id: docRef.id, code: promo.code.trim().toUpperCase());
    await docRef.set(toSave.toMap());
    return (true, 'Tạo khuyến mãi thành công.');
  }

  Future<(bool, String)> updatePromotion(PromotionModel promo) async {
    final snapshot = await _firebaseService.promotionsCollection
        .where('code', isEqualTo: promo.code.trim().toUpperCase())
        .get();

    final duplicate = snapshot.docs.any((d) => d.id != promo.id);
    if (duplicate) {
      return (false, 'Mã khuyến mãi đã tồn tại.');
    }

    await _firebaseService.promotionsCollection.doc(promo.id).update(promo.toMap());
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

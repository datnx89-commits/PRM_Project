import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/field_model.dart';
import '../models/field_type_model.dart';
import '../models/review_model.dart';
import '../models/time_slot_model.dart';
import '../services/firebase_service.dart';

class FieldRepository {
  final FirebaseService _firebaseService;

  FieldRepository(this._firebaseService);

  Future<List<FieldModel>> searchFields({
    String? keyword,
    String? fieldTypeId,
    String? city,
    double? maxPrice,
    int? minRating,
  }) async {
    Query<Map<String, dynamic>> query = _firebaseService.fieldsCollection
        .where('status', isEqualTo: FieldStatus.active);

    if (fieldTypeId != null && fieldTypeId.isNotEmpty) {
      query = query.where('fieldTypeId', isEqualTo: fieldTypeId);
    }
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    final snapshot = await query.get();
    List<FieldModel> fields = snapshot.docs
        .map((doc) => FieldModel.fromMap(doc.data(), doc.id))
        .toList();

    if (keyword != null && keyword.trim().isNotEmpty) {
      final k = keyword.trim().toLowerCase();
      fields = fields.where((f) {
        return f.fieldName.toLowerCase().contains(k) ||
            f.address.toLowerCase().contains(k) ||
            f.district.toLowerCase().contains(k);
      }).toList();
    }

    if (maxPrice != null && maxPrice > 0) {
      fields = fields.where((f) => f.pricePerHour <= maxPrice).toList();
    }

    if (minRating != null && minRating > 0) {
      fields = fields.where((f) => f.averageRating >= minRating).toList();
    }

    fields.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    return fields;
  }

  Future<FieldModel?> getFieldDetail(String fieldId) async {
    final doc = await _firebaseService.fieldsCollection.doc(fieldId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FieldModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<FieldTypeModel>> getFieldTypes() async {
    final snapshot = await _firebaseService.fieldTypesCollection.get();
    return snapshot.docs
        .map((doc) => FieldTypeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<String>> getCities() async {
    final snapshot = await _firebaseService.fieldsCollection.get();
    final cities = snapshot.docs
        .map((doc) => doc.data()['city'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  Future<List<TimeSlotModel>> getTimeSlots(String fieldId) async {
    final snapshot = await _firebaseService.timeSlotsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('isActive', isEqualTo: true)
        .get();

    final slots = snapshot.docs
        .map((doc) => TimeSlotModel.fromMap(doc.data(), doc.id))
        .toList();

    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  Future<List<ReviewModel>> getFieldReviews(String fieldId) async {
    final snapshot = await _firebaseService.reviewsCollection
        .where('fieldId', isEqualTo: fieldId)
        .get();

    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList();

    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<String> createField(FieldModel field) async {
    final docRef = _firebaseService.fieldsCollection.doc();
    final newField = field.copyWith(id: docRef.id);
    await docRef.set(newField.toMap());

    final batch = _firebaseService.firestore.batch();
    for (int h = 6; h < 22; h++) {
      final slotDoc = _firebaseService.timeSlotsCollection.doc();
      final startStr = '${h.toString().padLeft(2, '0')}:00';
      final endStr = '${(h + 1).toString().padLeft(2, '0')}:00';
      final slot = TimeSlotModel(
        id: slotDoc.id,
        fieldId: docRef.id,
        startTime: startStr,
        endTime: endStr,
        isActive: true,
      );
      batch.set(slotDoc, slot.toMap());
    }
    await batch.commit();

    return docRef.id;
  }

  Future<void> updateField(FieldModel field) async {
    await _firebaseService.fieldsCollection.doc(field.id).update(field.toMap());
  }

  Future<bool> deleteOrCloseField(String fieldId) async {
    final bookingsSnapshot = await _firebaseService.bookingDetailsCollection
        .where('fieldId', isEqualTo: fieldId)
        .limit(1)
        .get();

    if (bookingsSnapshot.docs.isNotEmpty) {
      await _firebaseService.fieldsCollection
          .doc(fieldId)
          .update({'status': FieldStatus.closed});
      return false;
    } else {
      await _firebaseService.fieldsCollection.doc(fieldId).delete();
      final slots = await _firebaseService.timeSlotsCollection
          .where('fieldId', isEqualTo: fieldId)
          .get();
      final batch = _firebaseService.firestore.batch();
      for (var d in slots.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      return true;
    }
  }

  Future<List<FieldModel>> getFieldsByOwner(String ownerId) async {
    final snapshot = await _firebaseService.fieldsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => FieldModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<FieldModel>> getAllFieldsForAdmin() async {
    final snapshot = await _firebaseService.fieldsCollection.get();
    return snapshot.docs
        .map((doc) => FieldModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateFieldAverageRating(String fieldId) async {
    final reviews = await getFieldReviews(fieldId);
    if (reviews.isEmpty) return;
    final total = reviews.fold<num>(0, (acc, r) => acc + r.rating);
    final avg = (total / reviews.length).toDouble();
    await _firebaseService.fieldsCollection.doc(fieldId).update({
      'averageRating': double.parse(avg.toStringAsFixed(1)),
    });
  }

}

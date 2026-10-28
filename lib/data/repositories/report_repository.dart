import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../models/report_summary_model.dart';
import '../services/firebase_service.dart';

class ReportRepository {
  final FirebaseService _firebaseService;

  ReportRepository(this._firebaseService);

  /// Lấy báo cáo thống kê doanh thu theo khoảng ngày.
  /// Nếu ownerId != null: Chỉ thống kê các sân thuộc quyền quản lý của chủ sân đó.
  /// Nếu ownerId == null: Thống kê toàn hệ thống (dành cho Admin).
  Future<ReportSummary> getSummary(
    DateTime fromDate,
    DateTime toDate, {
    String? ownerId,
  }) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    // 1. Lấy danh sách sân bóng (lọc theo ownerId nếu có)
    Query<Map<String, dynamic>> fieldsQuery = _firebaseService.fieldsCollection;
    if (ownerId != null && ownerId.isNotEmpty) {
      fieldsQuery = fieldsQuery.where('ownerId', isEqualTo: ownerId);
    }
    final fieldsSnapshot = await fieldsQuery.get();
    final ownedFieldIds = fieldsSnapshot.docs.map((doc) => doc.id).toSet();
    final fieldNameMap = {
      for (var doc in fieldsSnapshot.docs)
        doc.id: (doc.data()['fieldName'] as String? ?? 'Sân thể thao')
    };
    final totalFields = fieldsSnapshot.docs.length;

    // 2. Lấy dữ liệu thanh toán từ paymentsCollection
    final paymentsSnapshot = await _firebaseService.paymentsCollection
        .where('status', isEqualTo: PaymentStatus.paid)
        .get();

    final Map<String, PaymentModel> paymentByBookingId = {};
    for (var doc in paymentsSnapshot.docs) {
      final p = PaymentModel.fromMap(doc.data(), doc.id);
      paymentByBookingId[p.bookingId] = p;
    }

    // 3. Lấy dữ liệu bookings
    final bookingsSnapshot = await _firebaseService.bookingsCollection.get();

    double totalRevenue = 0.0;
    final Set<String> bookingIds = {};
    final Set<String> customerIds = {};
    final Map<String, (double, int)> dailyMap = {};
    final Map<String, (int, double)> fieldStats = {};

    for (var bDoc in bookingsSnapshot.docs) {
      final b = BookingModel.fromMap(bDoc.data(), bDoc.id);

      // Nếu lọc theo ownerId, chỉ tính booking thuộc sân của owner này
      if (ownerId != null && ownerId.isNotEmpty) {
        if (b.ownerId != ownerId && !ownedFieldIds.contains(b.fieldId)) {
          continue;
        }
      }

      // Kiểm tra trạng thái đã thanh toán
      final payment = paymentByBookingId[b.id];
      final isPaid = b.isPaid || (payment != null && payment.status == PaymentStatus.paid);
      if (!isPaid || b.status == BookingStatus.cancelled) continue;

      // Xác định thời điểm thanh toán
      final effectivePaidAt = payment?.paidAt ?? b.paidAt ?? b.createdAt;
      if (effectivePaidAt.isBefore(start) || effectivePaidAt.isAfter(end)) continue;

      final amount = payment?.amount ?? b.totalAmount;
      totalRevenue += amount;
      bookingIds.add(b.id);
      if (b.userId.isNotEmpty) customerIds.add(b.userId);

      // Thống kê theo ngày
      final dStr =
          '${effectivePaidAt.year}-${effectivePaidAt.month.toString().padLeft(2, '0')}-${effectivePaidAt.day.toString().padLeft(2, '0')}';
      final currDaily = dailyMap[dStr] ?? (0.0, 0);
      dailyMap[dStr] = (currDaily.$1 + amount, currDaily.$2 + 1);

      // Thống kê theo sân
      final fName = fieldNameMap[b.fieldId] ?? b.fieldName ?? 'Sân thể thao';
      final currField = fieldStats[fName] ?? (0, 0.0);
      fieldStats[fName] = (currField.$1 + 1, currField.$2 + amount);
    }

    final totalCustomers = customerIds.isNotEmpty
        ? customerIds.length
        : (await _firebaseService.usersCollection.where('role', isEqualTo: UserRole.customer).get()).docs.length;

    final revenueByDays = dailyMap.entries
        .map((e) => RevenueByDay(date: e.key, revenue: e.value.$1, bookingCount: e.value.$2))
        .toList();
    revenueByDays.sort((a, b) => a.date.compareTo(b.date));

    final topFields = fieldStats.entries
        .map((e) => TopField(fieldName: e.key, bookingCount: e.value.$1, revenue: e.value.$2))
        .toList();
    topFields.sort((a, b) => b.revenue.compareTo(a.revenue));

    return ReportSummary(
      totalRevenue: totalRevenue,
      totalBookings: bookingIds.length,
      totalCustomers: totalCustomers,
      totalFields: totalFields,
      revenueByDays: revenueByDays,
      topFields: topFields.take(5).toList(),
    );
  }
}

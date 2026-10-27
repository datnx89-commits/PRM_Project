import '../../core/constants/app_constants.dart';
import '../models/booking_detail_model.dart';
import '../models/payment_model.dart';
import '../models/report_summary_model.dart';
import '../services/firebase_service.dart';

class ReportRepository {
  final FirebaseService _firebaseService;

  ReportRepository(this._firebaseService);

  Future<ReportSummary> getSummary(DateTime fromDate, DateTime toDate) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    final paymentsSnapshot = await _firebaseService.paymentsCollection
        .where('status', isEqualTo: PaymentStatus.paid)
        .get();

    final allPaidPayments = paymentsSnapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
        .where((p) => p.paidAt != null && p.paidAt!.isAfter(start.subtract(const Duration(seconds: 1))) && p.paidAt!.isBefore(end.add(const Duration(seconds: 1))))
        .toList();

    double totalRevenue = 0.0;
    final Set<String> bookingIds = {};
    final Map<String, (double, int)> dailyMap = {};

    for (var p in allPaidPayments) {
      totalRevenue += p.amount;
      bookingIds.add(p.bookingId);

      if (p.paidAt != null) {
        final dStr = '${p.paidAt!.year}-${p.paidAt!.month.toString().padLeft(2, '0')}-${p.paidAt!.day.toString().padLeft(2, '0')}';
        final curr = dailyMap[dStr] ?? (0.0, 0);
        dailyMap[dStr] = (curr.$1 + p.amount, curr.$2 + 1);
      }
    }

    final usersSnapshot = await _firebaseService.usersCollection
        .where('role', isEqualTo: UserRole.customer)
        .get();
    final totalCustomers = usersSnapshot.docs.length;

    final fieldsSnapshot = await _firebaseService.fieldsCollection.get();
    final totalFields = fieldsSnapshot.docs.length;

    final revenueByDays = dailyMap.entries
        .map((e) => RevenueByDay(date: e.key, revenue: e.value.$1, bookingCount: e.value.$2))
        .toList();
    revenueByDays.sort((a, b) => a.date.compareTo(b.date));

    final Map<String, (int, double)> fieldStats = {};
    for (var bId in bookingIds) {
      final detailsSnapshot = await _firebaseService.bookingDetailsCollection
          .where('bookingId', isEqualTo: bId)
          .where('status', isEqualTo: 'Active')
          .get();

      for (var doc in detailsSnapshot.docs) {
        final d = BookingDetailModel.fromMap(doc.data(), doc.id);
        final fieldName = d.fieldName ?? 'Chưa đặt tên';
        final curr = fieldStats[fieldName] ?? (0, 0.0);
        fieldStats[fieldName] = (curr.$1 + 1, curr.$2 + d.price);
      }
    }

    final topFields = fieldStats.entries
        .map((e) => TopField(fieldName: e.key, bookingCount: e.value.$1, revenue: e.value.$2))
        .toList();
    topFields.sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

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

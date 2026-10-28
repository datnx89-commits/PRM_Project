import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/maintenance_request_model.dart';
import '../models/refund_request_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'point_repository.dart';
import 'wallet_repository.dart';

class MaintenanceRepository {
  final FirebaseService _firebase;
  final WalletRepository _walletRepo;
  final PointRepository _pointRepo;

  MaintenanceRepository(this._firebase, this._walletRepo, this._pointRepo);

  /// Lấy danh sách yêu cầu bảo trì của Owner
  Future<List<MaintenanceRequestModel>> getByOwner(String ownerId) async {
    final snapshot = await _firebase.maintenanceRequestsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final list = snapshot.docs
        .map((d) => MaintenanceRequestModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Lấy toàn bộ yêu cầu bảo trì cho Admin (có thể lọc theo status)
  Future<List<MaintenanceRequestModel>> getAllForAdmin({String? status}) async {
    Query query = _firebase.maintenanceRequestsCollection;
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    final list = snapshot.docs
        .map((d) => MaintenanceRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Owner gửi yêu cầu bảo trì sân
  Future<(bool, String)> createRequest({
    required String ownerId,
    required String ownerName,
    required String fieldId,
    required String fieldName,
    required String reason,
    required String startDate,
    required String endDate,
  }) async {
    if (reason.trim().isEmpty) {
      return (false, 'Vui lòng nhập lý do bảo trì.');
    }
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (startDate.compareTo(todayStr) < 0) {
      return (false, 'Ngày bắt đầu không được ở quá khứ.');
    }
    if (endDate.compareTo(startDate) < 0) {
      return (false, 'Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.');
    }

    // Kiểm tra có yêu cầu đang chờ duyệt trùng sân không
    final pendingDup = await _firebase.maintenanceRequestsCollection
        .where('fieldId', isEqualTo: fieldId)
        .where('status', isEqualTo: MaintenanceStatus.pending)
        .limit(1)
        .get();
    if (pendingDup.docs.isNotEmpty) {
      return (false, 'Sân này đang có yêu cầu bảo trì chờ duyệt.');
    }

    final docRef = _firebase.maintenanceRequestsCollection.doc();
    final request = MaintenanceRequestModel(
      id: docRef.id,
      fieldId: fieldId,
      fieldName: fieldName,
      ownerId: ownerId,
      ownerName: ownerName,
      reason: reason.trim(),
      startDate: startDate,
      endDate: endDate,
      status: MaintenanceStatus.pending,
      createdAt: DateTime.now(),
    );
    await docRef.set(request.toMap());

    return (true, 'Đã gửi yêu cầu bảo trì, chờ Quản trị viên duyệt.');
  }

  /// Admin duyệt yêu cầu bảo trì:
  /// - Chuyển sân sang Maintenance (nếu bao gồm ngày hiện tại)
  /// - Tự động hủy mọi booking trùng lịch
  /// - Hoàn tiền ví ngay hoặc tạo RefundRequest về STK
  /// - Hoàn điểm tích lũy và hoàn lượt mã KM
  /// - Gửi thông báo đến từng khách hàng
  Future<(bool, String)> approveRequest(String requestId, String? adminNote) async {
    final reqDoc = await _firebase.maintenanceRequestsCollection.doc(requestId).get();
    if (!reqDoc.exists || reqDoc.data() == null) {
      return (false, 'Không tìm thấy yêu cầu.');
    }
    final request = MaintenanceRequestModel.fromMap(reqDoc.data()!, reqDoc.id);
    if (!request.isPending) {
      return (false, 'Yêu cầu này đã được xử lý trước đó.');
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Cập nhật trạng thái yêu cầu
    await _firebase.maintenanceRequestsCollection.doc(requestId).update({
      'status': MaintenanceStatus.approved,
      'adminNote': adminNote,
      'processedAt': now.toIso8601String(),
    });

    // 2. Chuyển trạng thái sân nếu khoảng bảo trì chứa ngày hôm nay
    if (request.startDate.compareTo(todayStr) <= 0 && request.endDate.compareTo(todayStr) >= 0) {
      await _firebase.fieldsCollection.doc(request.fieldId).update({
        'status': FieldStatus.maintenance,
      });
    }

    // 3. Tìm các booking của sân trùng khoảng ngày bảo trì
    final bookingsSnapshot = await _firebase.bookingsCollection
        .where('fieldId', isEqualTo: request.fieldId)
        .where('bookingDate', isGreaterThanOrEqualTo: request.startDate)
        .where('bookingDate', isLessThanOrEqualTo: request.endDate)
        .get();

    final affectedBookings = bookingsSnapshot.docs
        .map((d) => BookingModel.fromMap(d.data(), d.id))
        .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
        .toList();

    // 4. Lấy thông tin sân để kiểm tra acceptWalletPayment
    final fieldDoc = await _firebase.fieldsCollection.doc(request.fieldId).get();
    final acceptWallet = fieldDoc.exists ? (fieldDoc.data()?['acceptWalletPayment'] as bool? ?? false) : false;

    int affectedCount = 0;
    for (var booking in affectedBookings) {
      affectedCount++;

      // a. Chuyển trạng thái booking thành Cancelled
      await _firebase.bookingsCollection.doc(booking.id).update({
        'status': BookingStatus.cancelled,
        'paymentStatus': booking.isPaid ? PaymentStatus.refunded : booking.paymentStatus,
      });

      // Cập nhật payment trong paymentsCollection thành Refunded nếu đã thanh toán
      if (booking.isPaid) {
        final pSnap = await _firebase.paymentsCollection
            .where('bookingId', isEqualTo: booking.id)
            .where('status', isEqualTo: PaymentStatus.paid)
            .get();
        for (var pDoc in pSnap.docs) {
          await pDoc.reference.update({'status': PaymentStatus.refunded});
        }
      }

      // b. Hoàn lại lượt mã khuyến mãi nếu có
      if (booking.promotionId != null && booking.promotionId!.isNotEmpty) {
        final pDoc = await _firebase.promotionsCollection.doc(booking.promotionId).get();
        if (pDoc.exists && pDoc.data() != null) {
          final curQty = (pDoc.data()!['quantity'] as num?)?.toInt() ?? 0;
          await _firebase.promotionsCollection.doc(booking.promotionId).update({
            'quantity': curQty + 1,
          });
        }
      }

      // c. Hoàn lại điểm đã dùng
      await _pointRepo.returnUsedPoints(booking, 'sân bảo trì');

      // d. Hoàn tiền nếu đơn đã thanh toán
      if (booking.isPaid && booking.totalAmount > 0) {
        final toWallet = booking.paymentMethod == PaymentMethod.wallet || acceptWallet;

        if (toWallet) {
          // Hoàn ngay vào ví
          await _walletRepo.refund(
            userId: booking.userId,
            amount: booking.totalAmount,
            bookingId: booking.id,
            description: 'Hoàn tiền booking #${booking.id} (sân bảo trì)',
          );
        } else {
          // Tạo RefundRequest chuyển khoản STK ngân hàng
          final userDoc = await _firebase.usersCollection.doc(booking.userId).get();
          UserModel? user;
          if (userDoc.exists && userDoc.data() != null) {
            user = UserModel.fromMap(userDoc.data()!, userDoc.id);
          }

          final refundRef = _firebase.refundRequestsCollection.doc();
          final refundReq = RefundRequestModel(
            id: refundRef.id,
            bookingId: booking.id,
            userId: booking.userId,
            userName: booking.userFullName,
            amount: booking.totalAmount,
            reason: 'Sân bảo trì (${request.startDate} - ${request.endDate})',
            status: RefundStatus.pending,
            bankName: user?.bankName,
            bankAccountNumber: user?.bankAccountNumber,
            bankAccountHolder: user?.bankAccountHolder,
            createdAt: now,
          );
          await refundRef.set(refundReq.toMap());
        }
      }

      // e. Tạo thông báo trong app cho khách hàng
      final notifRef = _firebase.notificationsCollection.doc();
      await notifRef.set({
        'id': notifRef.id,
        'userId': booking.userId,
        'title': 'Booking bị hủy do sân bảo trì',
        'message': 'Sân ${request.fieldName ?? "thể thao"} bảo trì từ ${request.startDate} đến ${request.endDate} nên booking #${booking.id} (${booking.bookingDate}) của bạn đã được tự động hủy và hoàn tiền.',
        'url': '/my-bookings',
        'isRead': false,
        'createdAt': now.toIso8601String(),
      });
    }

    // Gửi thông báo cho Chủ sân
    final ownerNotifRef = _firebase.notificationsCollection.doc();
    await ownerNotifRef.set({
      'id': ownerNotifRef.id,
      'userId': request.ownerId,
      'title': 'Yêu cầu bảo trì được duyệt',
      'message': 'Admin đã duyệt yêu cầu bảo trì sân ${request.fieldName} (${request.startDate} đến ${request.endDate}). $affectedCount booking trùng lịch đã được hủy và hoàn tiền tự động.',
      'url': '/owner/maintenance',
      'isRead': false,
      'createdAt': now.toIso8601String(),
    });

    return (
      true,
      'Đã duyệt bảo trì sân thành công. $affectedCount đơn đặt trùng lịch đã được hủy và xử lý hoàn tiền tự động.'
    );
  }

  /// Admin từ chối yêu cầu bảo trì
  Future<(bool, String)> rejectRequest(String requestId, String? adminNote) async {
    final reqDoc = await _firebase.maintenanceRequestsCollection.doc(requestId).get();
    if (!reqDoc.exists || reqDoc.data() == null) {
      return (false, 'Không tìm thấy yêu cầu.');
    }
    final request = MaintenanceRequestModel.fromMap(reqDoc.data()!, reqDoc.id);
    if (!request.isPending) {
      return (false, 'Yêu cầu này đã được xử lý trước đó.');
    }

    final now = DateTime.now();
    await _firebase.maintenanceRequestsCollection.doc(requestId).update({
      'status': MaintenanceStatus.rejected,
      'adminNote': adminNote,
      'processedAt': now.toIso8601String(),
    });

    // Thông báo cho Owner
    final notifRef = _firebase.notificationsCollection.doc();
    final noteText = adminNote != null && adminNote.isNotEmpty ? ' Lý do: $adminNote' : '';
    await notifRef.set({
      'id': notifRef.id,
      'userId': request.ownerId,
      'title': 'Yêu cầu bảo trì bị từ chối',
      'message': 'Admin đã từ chối yêu cầu bảo trì sân ${request.fieldName} (${request.startDate} - ${request.endDate}).$noteText',
      'url': '/owner/maintenance',
      'isRead': false,
      'createdAt': now.toIso8601String(),
    });

    return (true, 'Đã từ chối yêu cầu bảo trì.');
  }
}

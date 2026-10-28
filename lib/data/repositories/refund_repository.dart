import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/refund_request_model.dart';
import '../services/firebase_service.dart';

class RefundRepository {
  final FirebaseService _firebase;

  RefundRepository(this._firebase);

  /// Lấy danh sách yêu cầu hoàn tiền chuyển khoản STK ngân hàng
  Future<List<RefundRequestModel>> getRefundRequests({String? status}) async {
    Query query = _firebase.refundRequestsCollection;
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    final list = snapshot.docs
        .map((d) => RefundRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Admin/Owner đánh dấu đã chuyển khoản hoàn tiền thành công
  Future<(bool, String)> markTransferred({
    required String refundRequestId,
    required String processedById,
    String? note,
  }) async {
    final doc = await _firebase.refundRequestsCollection.doc(refundRequestId).get();
    if (!doc.exists || doc.data() == null) {
      return (false, 'Không tìm thấy yêu cầu hoàn tiền.');
    }
    final req = RefundRequestModel.fromMap(doc.data()!, doc.id);
    if (req.isCompleted) {
      return (false, 'Yêu cầu này đã được đánh dấu hoàn thành trước đó.');
    }

    final now = DateTime.now();
    await _firebase.refundRequestsCollection.doc(refundRequestId).update({
      'status': RefundStatus.completed,
      'processedNote': note,
      'processedById': processedById,
      'processedAt': now.toIso8601String(),
    });

    // Gửi thông báo cho khách hàng
    final notifRef = _firebase.notificationsCollection.doc();
    await notifRef.set({
      'id': notifRef.id,
      'userId': req.userId,
      'title': 'Hoàn tiền thành công',
      'message': 'Số tiền ${req.amount.toInt()}đ của booking #${req.bookingId} đã được chuyển khoản về tài khoản ngân hàng của bạn.${note != null && note.isNotEmpty ? ' Mã GD: $note' : ''}',
      'url': '/my-bookings',
      'isRead': false,
      'createdAt': now.toIso8601String(),
    });

    return (true, 'Đã xác nhận chuyển khoản hoàn tiền thành công.');
  }

  /// Admin/Owner từ chối yêu cầu hoàn tiền kèm lý do
  Future<(bool, String)> rejectRefund({
    required String refundRequestId,
    required String processedById,
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      return (false, 'Vui lòng ghi lý do từ chối hoàn tiền.');
    }

    final doc = await _firebase.refundRequestsCollection.doc(refundRequestId).get();
    if (!doc.exists || doc.data() == null) {
      return (false, 'Không tìm thấy yêu cầu hoàn tiền.');
    }
    final req = RefundRequestModel.fromMap(doc.data()!, doc.id);
    if (!req.isPending) {
      return (false, 'Yêu cầu này đã được xử lý trước đó.');
    }

    final now = DateTime.now();
    await _firebase.refundRequestsCollection.doc(refundRequestId).update({
      'status': RefundStatus.rejected,
      'processedNote': note.trim(),
      'processedById': processedById,
      'processedAt': now.toIso8601String(),
    });

    // Gửi thông báo cho khách hàng
    final notifRef = _firebase.notificationsCollection.doc();
    await notifRef.set({
      'id': notifRef.id,
      'userId': req.userId,
      'title': 'Yêu cầu hoàn tiền bị từ chối',
      'message': 'Yêu cầu hoàn ${req.amount.toInt()}đ cho booking #${req.bookingId} chưa được xử lý — lý do: ${note.trim()}. Vui lòng liên hệ quản trị viên nếu cần hỗ trợ.',
      'url': '/my-bookings',
      'isRead': false,
      'createdAt': now.toIso8601String(),
    });

    return (true, 'Đã từ chối yêu cầu hoàn tiền thành công.');
  }
}

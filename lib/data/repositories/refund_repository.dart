import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/refund_request_model.dart';
import '../services/firebase_service.dart';
import 'wallet_repository.dart';

class RefundRepository {
  final FirebaseService _firebase;
  final WalletRepository? _walletRepo;

  RefundRepository(this._firebase, [this._walletRepo]);

  /// Lấy danh sách yêu cầu hoàn tiền chuyển khoản STK ngân hàng
  Future<List<RefundRequestModel>> getRefundRequests({String? status}) async {
    Query query = _firebase.refundRequestsCollection;
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    var list = snapshot.docs
        .map((d) => RefundRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    // Yêu cầu tạo lúc khách chưa nhập STK -> lấy STK mới nhất từ hồ sơ khách
    list = await Future.wait(list.map(_fillBankInfo));

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<RefundRequestModel> _fillBankInfo(RefundRequestModel req) async {
    final hasBank = (req.bankAccountNumber ?? '').trim().isNotEmpty;
    if (hasBank || !req.isPending) return req;
    try {
      final userDoc = await _firebase.usersCollection.doc(req.userId).get();
      final data = userDoc.data();
      if (data == null) return req;
      final number = (data['bankAccountNumber'] as String?)?.trim() ?? '';
      if (number.isEmpty) return req;
      final bankName = data['bankName'] as String?;
      final holder = data['bankAccountHolder'] as String?;
      await _firebase.refundRequestsCollection.doc(req.id).update({
        'bankName': bankName,
        'bankAccountNumber': number,
        'bankAccountHolder': holder,
      });
      return req.copyWith(
        bankName: bankName,
        bankAccountNumber: number,
        bankAccountHolder: holder,
      );
    } catch (_) {
      return req;
    }
  }

  /// Admin hoàn tiền thẳng vào Ví SportsBook của khách (thay cho chuyển khoản ngân hàng)
  Future<(bool, String)> refundToWallet({
    required String refundRequestId,
    required String processedById,
    String? note,
  }) async {
    final walletRepo = _walletRepo;
    if (walletRepo == null) {
      return (false, 'Chưa cấu hình WalletRepository cho hoàn tiền vào ví.');
    }

    // 1. Giữ yêu cầu bằng transaction trước khi cộng tiền: bấm 2 lần hay 2 admin cùng duyệt cũng chỉ cộng 1 lần
    final refundRef = _firebase.refundRequestsCollection.doc(refundRequestId);
    final now = DateTime.now();
    final extra = (note != null && note.trim().isNotEmpty) ? ' - ${note.trim()}' : '';
    final (req, error) = await _firebase.firestore.runTransaction<(RefundRequestModel?, String?)>((tx) async {
      final doc = await tx.get(refundRef);
      if (!doc.exists || doc.data() == null) {
        return (null, 'Không tìm thấy yêu cầu hoàn tiền.');
      }
      final current = RefundRequestModel.fromMap(doc.data()!, doc.id);
      if (!current.isPending) {
        return (null, 'Yêu cầu này đã được xử lý trước đó.');
      }
      tx.update(refundRef, {
        'status': RefundStatus.completed,
        'processedNote': 'Đã hoàn vào Ví SportsBook$extra',
        'processedById': processedById,
        'processedAt': now.toIso8601String(),
      });
      return (current, null);
    });
    if (req == null) {
      return (false, error ?? 'Không thể xử lý yêu cầu hoàn tiền.');
    }

    // 2. Cộng tiền vào ví (ghi giao dịch Refund + cập nhật số dư); lỗi thì trả yêu cầu về Pending
    try {
      await walletRepo.refund(
        userId: req.userId,
        amount: req.amount,
        bookingId: req.bookingId,
        description: 'Hoàn tiền hủy booking #${req.bookingId} (Admin duyệt)',
      );
    } catch (e) {
      await refundRef.update({
        'status': RefundStatus.pending,
        'processedNote': null,
        'processedById': null,
        'processedAt': null,
      });
      return (false, 'Lỗi cộng tiền vào ví: $e');
    }

    // 3. Thông báo cho khách, bấm vào mở màn Ví; tiền đã cộng nên lỗi gửi thông báo không tính là thất bại
    try {
      final notifRef = _firebase.notificationsCollection.doc();
      await notifRef.set({
        'id': notifRef.id,
        'userId': req.userId,
        'title': 'Đã hoàn tiền vào ví',
        'message': 'Số tiền ${req.amount.toInt()}đ của booking #${req.bookingId} đã được cộng vào Ví SportsBook của bạn.',
        'url': '/wallet',
        'isRead': false,
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {}

    return (true, 'Đã cộng ${req.amount.toInt()}đ vào ví của khách.');
  }

  /// Admin/Owner đánh dấu đã chuyển khoản hoàn tiền thành công
  Future<(bool, String)> markTransferred({
    required String refundRequestId,
    required String processedById,
    String? note,
  }) async {
    final refundRef = _firebase.refundRequestsCollection.doc(refundRequestId);
    return _firebase.firestore.runTransaction<(bool, String)>((tx) async {
      final doc = await tx.get(refundRef);
      if (!doc.exists || doc.data() == null) {
        return (false, 'Không tìm thấy yêu cầu hoàn tiền.');
      }
      final req = RefundRequestModel.fromMap(doc.data()!, doc.id);
      if (!req.isPending) {
        return (false, 'Yêu cầu này đã được xử lý trước đó.');
      }

      final now = DateTime.now().toIso8601String();
      tx.update(refundRef, {
        'status': RefundStatus.completed,
        'processedNote': note?.trim(),
        'processedById': processedById,
        'processedAt': now,
      });
      final notifRef = _firebase.notificationsCollection.doc();
      tx.set(notifRef, {
        'id': notifRef.id,
        'userId': req.userId,
        'title': 'Hoàn tiền thành công',
        'message': 'Số tiền ${req.amount.toInt()}đ của booking #${req.bookingId} đã được chuyển khoản về tài khoản ngân hàng của bạn.${note != null && note.trim().isNotEmpty ? ' Mã GD: ${note.trim()}' : ''}',
        'url': '/my-bookings',
        'isRead': false,
        'createdAt': now,
      });
      return (true, 'Đã xác nhận chuyển khoản hoàn tiền thành công.');
    });
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

    final refundRef = _firebase.refundRequestsCollection.doc(refundRequestId);
    return _firebase.firestore.runTransaction<(bool, String)>((tx) async {
      final doc = await tx.get(refundRef);
      if (!doc.exists || doc.data() == null) {
        return (false, 'Không tìm thấy yêu cầu hoàn tiền.');
      }
      final req = RefundRequestModel.fromMap(doc.data()!, doc.id);
      if (!req.isPending) {
        return (false, 'Yêu cầu này đã được xử lý trước đó.');
      }

      final now = DateTime.now().toIso8601String();
      tx.update(refundRef, {
        'status': RefundStatus.rejected,
        'processedNote': note.trim(),
        'processedById': processedById,
        'processedAt': now,
      });
      final notifRef = _firebase.notificationsCollection.doc();
      tx.set(notifRef, {
        'id': notifRef.id,
        'userId': req.userId,
        'title': 'Yêu cầu hoàn tiền bị từ chối',
        'message': 'Yêu cầu hoàn ${req.amount.toInt()}đ cho booking #${req.bookingId} chưa được xử lý — lý do: ${note.trim()}. Vui lòng liên hệ quản trị viên nếu cần hỗ trợ.',
        'url': '/my-bookings',
        'isRead': false,
        'createdAt': now,
      });
      return (true, 'Đã từ chối yêu cầu hoàn tiền thành công.');
    });
  }
}

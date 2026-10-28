import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/wallet_model.dart';
import '../services/firebase_service.dart';

class WalletRepository {
  final FirebaseService _firebase;
  final AppConfig _appConfig;

  WalletRepository(this._firebase, this._appConfig);

  /// Lấy hoặc tự tạo ví cho người dùng nếu chưa có
  Future<WalletModel> getOrCreateWallet(String userId) async {
    final doc = await _firebase.walletsCollection.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return WalletModel.fromMap(doc.data()!, doc.id);
    }

    final newWallet = WalletModel(
      id: userId,
      userId: userId,
      balance: 0.0,
      isLocked: false,
      updatedAt: DateTime.now(),
    );
    await _firebase.walletsCollection.doc(userId).set(newWallet.toMap());
    return newWallet;
  }

  /// Lấy lịch sử biến động số dư của người dùng (mới nhất trước)
  Future<List<WalletTransactionModel>> getTransactions(String userId) async {
    final snapshot = await _firebase.walletTransactionsCollection
        .where('walletId', isEqualTo: userId)
        .get();

    final list = snapshot.docs
        .map((d) => WalletTransactionModel.fromMap(d.data(), d.id))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Thêm giao dịch ví và cập nhật số dư
  Future<void> _addTransaction({
    required WalletModel wallet,
    required String type,
    required double amount,
    String? description,
    String? bookingId,
  }) async {
    final newBalance = wallet.balance + amount;
    final now = DateTime.now();

    final txDocRef = _firebase.walletTransactionsCollection.doc();
    final tx = WalletTransactionModel(
      id: txDocRef.id,
      walletId: wallet.id,
      type: type,
      amount: amount,
      balanceAfter: newBalance,
      description: description,
      bookingId: bookingId,
      createdAt: now,
    );

    final batch = _firebase.firestore.batch();
    batch.set(txDocRef, tx.toMap());
    batch.update(_firebase.walletsCollection.doc(wallet.id), {
      'balance': newBalance,
      'updatedAt': now.toIso8601String(),
    });

    await batch.commit();
  }

  /// Nạp tiền vào ví (có khuyến mãi nạp theo bậc: 200k +15k, 500k +50k)
  Future<(bool, String)> deposit(String userId, double amount) async {
    final min = _appConfig.minDepositAmount;
    if (amount < min) {
      return (false, 'Số tiền nạp tối thiểu là ${min.toInt()}đ.');
    }

    final wallet = await getOrCreateWallet(userId);
    if (wallet.isLocked) {
      return (false, 'Ví của bạn đang bị khóa. Vui lòng liên hệ quản trị viên.');
    }

    // 1. Ghi nhận giao dịch nạp tiền chính (Deposit)
    await _addTransaction(
      wallet: wallet,
      type: WalletTxType.deposit,
      amount: amount,
      description: 'Nạp tiền vào ví qua cổng thanh toán',
    );

    // 2. Kiểm tra khuyến mãi nạp theo bậc (Bonus)
    final bonusTier = _appConfig.getDepositBonus(amount);
    if (bonusTier != null) {
      // Lấy lại ví sau khi đã cộng tiền deposit
      final updatedWallet = await getOrCreateWallet(userId);
      await _addTransaction(
        wallet: updatedWallet,
        type: WalletTxType.bonus,
        amount: bonusTier.bonusAmount,
        description: 'Khuyến mãi nạp: nạp từ ${bonusTier.minAmount.toInt()}đ tặng ${bonusTier.bonusAmount.toInt()}đ',
      );
    }

    final bonusText = bonusTier != null
        ? ' + tặng ${bonusTier.bonusAmount.toInt()}đ khuyến mãi nạp'
        : '';
    return (true, 'Đã nạp ${amount.toInt()}đ vào ví$bonusText.');
  }

  /// Trừ tiền ví để thanh toán booking
  Future<(bool, String)> charge({
    required String userId,
    required double amount,
    required String bookingId,
    required String description,
  }) async {
    final wallet = await getOrCreateWallet(userId);
    if (wallet.isLocked) {
      return (false, 'Ví của bạn đang bị khóa, không thể thanh toán bằng ví.');
    }
    if (wallet.balance < amount) {
      return (
        false,
        'Số dư ví không đủ (hiện có ${wallet.balance.toInt()}đ, cần ${amount.toInt()}đ). Vui lòng nạp thêm.'
      );
    }

    await _addTransaction(
      wallet: wallet,
      type: WalletTxType.payment,
      amount: -amount,
      description: description,
      bookingId: bookingId,
    );

    return (true, 'Đã trừ tiền ví thành công.');
  }

  /// Hoàn tiền vào ví (khi hủy booking hoặc sân bảo trì)
  Future<void> refund({
    required String userId,
    required double amount,
    String? bookingId,
    required String description,
  }) async {
    if (amount <= 0) return;
    final wallet = await getOrCreateWallet(userId);
    await _addTransaction(
      wallet: wallet,
      type: WalletTxType.refund,
      amount: amount,
      description: description,
      bookingId: bookingId,
    );
  }

  /// Cộng tiền cashback vào ví (khi thanh toán booking có cashback)
  Future<void> cashback({
    required String userId,
    required double amount,
    required String bookingId,
    required String description,
  }) async {
    if (amount <= 0) return;
    final wallet = await getOrCreateWallet(userId);
    await _addTransaction(
      wallet: wallet,
      type: WalletTxType.cashback,
      amount: amount,
      description: description,
      bookingId: bookingId,
    );
  }

  // ---------------- QUẢN TRỊ VÍ (Admin) ----------------

  /// Lấy toàn bộ ví cho Admin
  Future<List<WalletModel>> getAllWallets() async {
    final snapshot = await _firebase.walletsCollection.get();
    return snapshot.docs
        .map((d) => WalletModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Khóa hoặc mở khóa ví
  Future<(bool, String)> toggleLock(String walletId) async {
    final doc = await _firebase.walletsCollection.doc(walletId).get();
    if (!doc.exists || doc.data() == null) {
      return (false, 'Không tìm thấy ví.');
    }
    final currentLocked = doc.data()!['isLocked'] as bool? ?? false;
    final nextLocked = !currentLocked;

    await _firebase.walletsCollection.doc(walletId).update({
      'isLocked': nextLocked,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return (true, nextLocked ? 'Đã khóa ví.' : 'Đã mở khóa ví.');
  }

  /// Admin điều chỉnh cộng/trừ số dư ví thủ công (bắt buộc có lý do)
  Future<(bool, String)> adjust({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      return (false, 'Cộng/trừ tiền thủ công bắt buộc phải ghi lý do.');
    }
    final wallet = await getOrCreateWallet(userId);
    if (wallet.balance + amount < 0) {
      return (false, 'Không thể trừ quá số dư hiện tại của ví.');
    }

    await _addTransaction(
      wallet: wallet,
      type: WalletTxType.adjust,
      amount: amount,
      description: 'Admin điều chỉnh: $reason',
    );

    return (true, 'Đã điều chỉnh số dư ví.');
  }

  /// Alias cho admin điều chỉnh số dư
  Future<(bool, String)> adminAdjustBalance({
    required String userId,
    required double amount,
    required String reason,
    required String adminId,
  }) => adjust(userId: userId, amount: amount, reason: reason);
}

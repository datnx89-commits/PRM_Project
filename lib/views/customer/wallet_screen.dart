import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/point_transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../shared/app_drawer.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WalletModel? _wallet;
  List<WalletTransactionModel> _walletTransactions = [];
  List<PointTransactionModel> _pointTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final walletRepo = ref.read(walletRepositoryProvider);
    final pointRepo = ref.read(pointRepositoryProvider);

    final w = await walletRepo.getOrCreateWallet(user.id);
    final wTxs = await walletRepo.getTransactions(user.id);
    final pTxs = await pointRepo.getHistory(user.id);

    if (mounted) {
      setState(() {
        _wallet = w;
        _walletTransactions = wTxs;
        _pointTransactions = pTxs;
        _isLoading = false;
      });
    }
  }

  Future<void> _showDepositDialog() async {
    final amountController = TextEditingController(text: '200000');
    final appConfig = ref.read(appConfigProvider);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final entered = double.tryParse(amountController.text) ?? 0.0;
            final bonus = appConfig.getDepositBonus(entered);

            return AlertDialog(
              title: const Text('Nạp tiền vào ví'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nhập số tiền muốn nạp (tối thiểu 10.000đ):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: 'VNĐ',
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [100000.0, 200000.0, 500000.0].map((amt) {
                        return OutlinedButton(
                          onPressed: () {
                            amountController.text = amt.toInt().toString();
                            setModalState(() {});
                          },
                          child: Text('${(amt / 1000).toInt()}k'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    if (bonus != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.card_giftcard, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Khuyến mãi: Nạp từ ${bonus.minAmount.toInt()}đ tặng thêm ${bonus.bonusAmount.toInt()}đ vào ví!',
                                style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    if (amt < 10000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số tiền nạp tối thiểu là 10.000đ')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final user = ref.read(authViewModelProvider).user;
                    if (user != null) {
                      final (ok, msg) = await ref.read(walletRepositoryProvider).deposit(user.id, amt);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        _loadData();
                      }
                    }
                  },
                  child: const Text('Xác nhận nạp'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _redeemVoucher(int optionIndex) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final (ok, msg, code) = await ref.read(pointRepositoryProvider).redeemVoucher(user.id, optionIndex);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (ok) {
        // Cập nhật lại Auth state để refresh điểm hiển thị
        ref.read(authViewModelProvider.notifier).refreshUser();
        _loadData();
      }
    }
  }

  Future<void> _showBankInfoDialog() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final bankNameCtrl = TextEditingController(text: user.bankName ?? '');
    final bankAccNumCtrl = TextEditingController(text: user.bankAccountNumber ?? '');
    final bankAccHolderCtrl = TextEditingController(text: user.bankAccountHolder ?? (user.fullName));

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tài khoản ngân hàng nhận hoàn tiền'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin này dùng để nhận tiền chuyển khoản khi hủy lịch đặt tại các sân không chấp nhận ví tiền ảo.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên ngân hàng (ví dụ: Vietcombank, MBBank)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bankAccNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản ngân hàng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bankAccHolderCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản (viết hoa không dấu)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Lưu thông tin'),
          ),
        ],
      ),
    );

    if (result == true) {
      final (ok, msg) = await ref.read(authViewModelProvider.notifier).updateBankInfo(
            bankName: bankNameCtrl.text,
            bankAccountNumber: bankAccNumCtrl.text,
            bankAccountHolder: bankAccHolderCtrl.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví & Điểm thưởng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Lịch sử Ví'),
            Tab(text: 'Lịch sử Điểm'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: TỔNG QUAN
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thẻ số dư ví
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.blue.shade900,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Số dư ví SportBooking', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    if (_wallet?.isLocked == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('BỊ KHÓA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.currency(_wallet?.balance ?? 0.0),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: _wallet?.isLocked == true ? null : _showDepositDialog,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Nạp tiền vào ví', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Thẻ Hạng thành viên & Điểm tích lũy
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.military_tech, color: Colors.amber, size: 28),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hạng: ${user?.membershipTier.name ?? "Thường"}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        (user != null && user.membershipTier.discountPercent > 0)
                                            ? 'Giảm ${user.membershipTier.discountPercent}%'
                                            : 'Không giảm',
                                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Điểm khả dụng: ${user?.points ?? 0} điểm', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Điểm trọn đời: ${user?.lifetimePoints ?? 0} điểm', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Thẻ Tài khoản ngân hàng nhận tiền hoàn (STK)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.account_balance, color: Colors.teal, size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tài khoản nhận tiền hoàn',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: _showBankInfoDialog,
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: Text(
                                        user?.bankAccountNumber != null && user!.bankAccountNumber!.isNotEmpty
                                            ? 'Sửa'
                                            : 'Thiết lập',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (user?.bankAccountNumber != null && user!.bankAccountNumber!.isNotEmpty) ...[
                                  Text('Ngân hàng: ${user.bankName ?? "Chưa rõ"}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('Số tài khoản: ${user.bankAccountNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('Chủ tài khoản: ${user.bankAccountHolder ?? ""}', style: const TextStyle(fontSize: 14)),
                                ] else ...[
                                  const Text(
                                    'Chưa thiết lập tài khoản ngân hàng để nhận tiền hoàn khi hủy sân không hỗ trợ ví.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Đổi điểm lấy voucher
                        const Text('Đổi điểm lấy mã giảm giá (Voucher):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...appConfig.voucherOptions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final opt = entry.value;
                          final canRedeem = (user?.points ?? 0) >= opt.pointCost;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: canRedeem ? Colors.green.shade100 : Colors.grey.shade200,
                                child: Text('-${opt.discountPercent}%', style: TextStyle(color: canRedeem ? Colors.green.shade800 : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              title: Text('Voucher giảm ${opt.discountPercent}% (tối đa ${opt.maxDiscount.toInt()}đ)'),
                              subtitle: Text('Tốn ${opt.pointCost} điểm • HSD: ${opt.validityDays} ngày'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canRedeem ? Colors.green : Colors.grey.shade300,
                                  foregroundColor: canRedeem ? Colors.white : Colors.grey.shade700,
                                ),
                                onPressed: canRedeem ? () => _redeemVoucher(idx) : null,
                                child: const Text('Đổi'),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // TAB 2: LỊCH SỬ VÍ
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _walletTransactions.isEmpty
                      ? const Center(child: Text('Chưa có giao dịch ví nào.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _walletTransactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final tx = _walletTransactions[i];
                            return ListTile(
                              leading: Icon(
                                tx.isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                color: tx.isPositive ? Colors.green : Colors.red,
                              ),
                              title: Text(tx.description ?? tx.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${Formatters.dateTimeString(tx.createdAt.toIso8601String())} • Sau GD: ${Formatters.currency(tx.balanceAfter)}', style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                '${tx.isPositive ? "+" : ""}${Formatters.currency(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // TAB 3: LỊCH SỬ ĐIỂM
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _pointTransactions.isEmpty
                      ? const Center(child: Text('Chưa có lịch sử điểm nào.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pointTransactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final tx = _pointTransactions[i];
                            return ListTile(
                              leading: Icon(
                                tx.isPositive ? Icons.star : Icons.star_border,
                                color: tx.isPositive ? Colors.amber : Colors.grey,
                              ),
                              title: Text(tx.description ?? tx.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(Formatters.dateTimeString(tx.createdAt.toIso8601String()), style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                '${tx.isPositive ? "+" : ""}${tx.points} điểm',
                                style: TextStyle(
                                  color: tx.isPositive ? Colors.amber.shade800 : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

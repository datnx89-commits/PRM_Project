// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/field_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/my_bookings_viewmodel.dart';
import 'my_bookings_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final List<String>? bookingIds;
  final double totalAmount;
  final String fieldName;

  const PaymentScreen({
    super.key,
    this.bookingId,
    this.bookingIds,
    required this.totalAmount,
    required this.fieldName,
  }) : assert(bookingId != null || (bookingIds != null && bookingIds.length > 0));

  List<String> get effectiveBookingIds {
    if (bookingIds != null && bookingIds!.isNotEmpty) return bookingIds!;
    if (bookingId != null) return [bookingId!];
    return [];
  }

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = PaymentMethod.wallet;
  bool _isProcessing = false;
  bool _usePoints = false;
  int _pointsToUse = 0;
  int _maxPoints = 0;

  FieldModel? _field;
  WalletModel? _wallet;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final bookingRepo = ref.read(bookingRepositoryProvider);
    final fieldRepo = ref.read(fieldRepositoryProvider);
    final walletRepo = ref.read(walletRepositoryProvider);
    final pointRepo = ref.read(pointRepositoryProvider);

    final ids = widget.effectiveBookingIds;
    final bookings = <BookingModel>[];
    for (var id in ids) {
      final b = await bookingRepo.getBookingDetail(id);
      if (b != null) bookings.add(b);
    }

    FieldModel? f;
    bool allAcceptWallet = true;
    for (var b in bookings) {
      if (b.fieldId.isNotEmpty) {
        final fDetail = await fieldRepo.getFieldDetail(b.fieldId);
        if (fDetail != null) {
          f ??= fDetail;
          if (!fDetail.acceptWalletPayment) {
            allAcceptWallet = false;
          }
        }
      }
    }

    final w = await walletRepo.getOrCreateWallet(user.id);

    int totalMaxPoints = 0;
    for (var b in bookings) {
      final maxPts = await pointRepo.getMaxRedeemable(user.id, b.totalAmount);
      totalMaxPoints += maxPts;
    }
    if (totalMaxPoints > user.points) {
      totalMaxPoints = user.points;
    }

    if (mounted) {
      setState(() {
        _field = f;
        _wallet = w;
        _maxPoints = totalMaxPoints;
        _isLoadingData = false;
        // Nếu bất kỳ sân nào không nhận ví, tự động chuyển phương thức mặc định sang VNPay
        if (!allAcceptWallet) {
          _selectedMethod = PaymentMethod.vnpay;
        }
      });
    }
  }

  double get _pointDiscount => _usePoints ? _pointsToUse * 100.0 : 0.0;
  double get _finalAmount => (widget.totalAmount - _pointDiscount).clamp(0.0, double.infinity);

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    final (success, msg) = await ref
        .read(myBookingsViewModelProvider.notifier)
        .payBookings(
          widget.effectiveBookingIds,
          _selectedMethod,
          pointsToUse: _usePoints ? _pointsToUse : 0,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          (route) => route.isFirst,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán đơn đặt')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final acceptWallet = _field?.acceptWalletPayment ?? false;
    final cashbackPercent = _field?.cashbackPercent ?? 0;
    final walletBalance = _wallet?.balance ?? 0.0;
    final isWalletLocked = _wallet?.isLocked ?? false;
    final isWalletInsufficient = walletBalance < _finalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán đơn đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin đơn đặt
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sân thể thao:'),
                        Text(widget.fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá gốc đơn đặt:'),
                        Text(Formatters.currency(widget.totalAmount)),
                      ],
                    ),
                    if (_usePoints && _pointDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Điểm trừ tiền ($_pointsToUse điểm):'),
                          Text(
                            '- ${Formatters.currency(_pointDiscount)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cần thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          Formatters.currency(_finalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu điểm thưởng (nếu có điểm)
            if (_maxPoints > 0) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bạn có thể dùng tối đa $_maxPoints điểm (giảm ${Formatters.currency(_maxPoints * 100.0)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: _usePoints,
                            onChanged: (val) {
                              setState(() {
                                _usePoints = val;
                                if (val && _pointsToUse == 0) {
                                  _pointsToUse = _maxPoints;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_usePoints) ...[
                        const SizedBox(height: 8),
                        Slider(
                          value: _pointsToUse.toDouble(),
                          min: 0,
                          max: _maxPoints.toDouble(),
                          divisions: _maxPoints > 10 ? (_maxPoints / 10).round() : 1,
                          label: '$_pointsToUse điểm (-${Formatters.currency(_pointsToUse * 100.0)})',
                          onChanged: (val) {
                            setState(() => _pointsToUse = val.round());
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Phương thức thanh toán
            const Text(
              'Chọn phương thức thanh toán:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 1. VÍ TIỀN ẢO
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.wallet ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 32),
                title: Row(
                  children: [
                    const Text('Ví tiền ảo SportBooking', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (cashbackPercent > 0 && acceptWallet) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('+$cashbackPercent% hoàn tiền', style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số dư hiện tại: ${Formatters.currency(walletBalance)}'),
                    if (!acceptWallet)
                      const Text('Sân này không chấp nhận thanh toán bằng ví.', style: TextStyle(color: Colors.red, fontSize: 12))
                    else if (isWalletLocked)
                      const Text('Ví đang bị khóa bởi quản trị viên.', style: TextStyle(color: Colors.red, fontSize: 12))
                    else if (isWalletInsufficient)
                      const Text('Số dư ví không đủ để thanh toán.', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
                trailing: Radio<String>(
                  value: PaymentMethod.wallet,
                  groupValue: _selectedMethod,
                  onChanged: (acceptWallet && !isWalletLocked && !isWalletInsufficient)
                      ? (val) => setState(() => _selectedMethod = val!)
                      : null,
                ),
                onTap: (acceptWallet && !isWalletLocked && !isWalletInsufficient)
                    ? () => setState(() => _selectedMethod = PaymentMethod.wallet)
                    : null,
              ),
            ),

            // 2. VNPAY
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.vnpay ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue, size: 32),
                title: const Text('VNPay (Cổng thanh toán điện tử)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hỗ trợ thẻ ATM nội địa, QR Pay, Visa/Mastercard'),
                trailing: Radio<String>(
                  value: PaymentMethod.vnpay,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                ),
                onTap: () => setState(() => _selectedMethod = PaymentMethod.vnpay),
              ),
            ),

            // 3. MOMO
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.momo ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.wallet, color: Colors.pink, size: 32),
                title: const Text('Ví MoMo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Thanh toán qua ví điện tử MoMo'),
                trailing: Radio<String>(
                  value: PaymentMethod.momo,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                ),
                onTap: () => setState(() => _selectedMethod = PaymentMethod.momo),
              ),
            ),

            // 4. TIỀN MẶT
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.cash ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.money, color: Colors.green, size: 32),
                title: const Text('Tiền mặt tại sân', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Thanh toán tại quầy khi đến sân, chủ sân xác nhận thu tiền.'),
                trailing: Radio<String>(
                  value: PaymentMethod.cash,
                  groupValue: _selectedMethod,
                  onChanged: (val) {
                    setState(() {
                      _selectedMethod = val!;
                      _usePoints = false; // Tiền mặt không dùng điểm
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedMethod = PaymentMethod.cash;
                    _usePoints = false;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Xác nhận thanh toán ${Formatters.currency(_finalAmount)} ($_selectedMethod)',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

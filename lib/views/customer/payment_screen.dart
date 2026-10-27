import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/my_bookings_viewmodel.dart';
import 'my_bookings_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double totalAmount;
  final String fieldName;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    required this.fieldName,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = PaymentMethod.vnpay;
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    final (success, msg) = await ref
        .read(myBookingsViewModelProvider.notifier)
        .payBooking(widget.bookingId, _selectedMethod);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán đơn đặt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sân bóng:'),
                        Text(widget.fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số tiền thanh toán:'),
                        Text(
                          Formatters.currency(widget.totalAmount),
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
            const SizedBox(height: 20),
            const Text(
              'Chọn phương thức thanh toán mô phỏng:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedMethod,
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('VNPay (Mô phỏng)'),
                    subtitle: Text('Cổng thanh toán điện tử VNPay'),
                    value: PaymentMethod.vnpay,
                  ),
                  RadioListTile<String>(
                    title: Text('Ví MoMo (Mô phỏng)'),
                    subtitle: Text('Ví điện tử MoMo'),
                    value: PaymentMethod.momo,
                  ),
                  RadioListTile<String>(
                    title: Text('Tiền mặt (Mô phỏng)'),
                    subtitle: Text('Thanh toán trực tiếp tại sân'),
                    value: PaymentMethod.cash,
                  ),
                ],
              ),
            ),

            const Spacer(),
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
                    : Text('Xác nhận thanh toán $_selectedMethod'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

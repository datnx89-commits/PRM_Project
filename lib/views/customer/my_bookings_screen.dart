import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/my_bookings_viewmodel.dart';
import '../shared/app_drawer.dart';
import 'booking_detail_screen.dart';
import 'payment_screen.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
      default:
        return 'Chờ duyệt';
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy sân'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đặt sân này không? Lưu ý: Chỉ được hủy trước giờ bắt đầu tối thiểu 2 giờ. Nếu đã thanh toán bằng ví, tiền sẽ được hoàn ngay vào ví của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final (success, msg) = await ref
                  .read(myBookingsViewModelProvider.notifier)
                  .cancelBooking(bookingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
            child: const Text('Hủy đặt sân', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsViewModelProvider);
    final vm = ref.read(myBookingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt sân'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: vm.loadBookings,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.bookings.isEmpty
                ? const Center(child: Text('Bạn chưa có đơn đặt sân nào.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.bookings.length,
                    itemBuilder: (context, index) {
                      final b = state.bookings[index];
                      final fieldName = b.effectiveFieldName;
                      final dateStr = b.effectiveBookingDate;
                      final slotTime = b.slotTimeText;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(booking: b),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fieldName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        _getStatusText(b.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(b.status),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Text('Ngày: ${Formatters.dateString(dateStr)}'),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.access_time, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Text('Giờ: $slotTime'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Formatters.currency(b.totalAmount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        _buildPaymentStatusBadge(b),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (!b.isPaid &&
                                            !b.isCashPending &&
                                            b.status != BookingStatus.cancelled)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PaymentScreen(
                                                    bookingId: b.id,
                                                    totalAmount: b.totalAmount,
                                                    fieldName: fieldName,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('Thanh toán'),
                                          ),
                                        if (b.status == BookingStatus.pending ||
                                            b.status == BookingStatus.confirmed) ...[
                                          const SizedBox(width: 6),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                            onPressed: () => _showCancelDialog(context, ref, b.id),
                                            child: const Text('Hủy'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(b) {
    if (b.isCashPending) {
      return const Text(
        'Thanh toán: Tiền mặt tại sân',
        style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
      );
    } else if (b.isPaid) {
      return Text(
        b.paymentMethod == PaymentMethod.wallet ? 'Đã thanh toán qua Ví' : 'Đã thanh toán tiền mặt',
        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
      );
    } else {
      return const Text(
        'Chưa thanh toán',
        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
      );
    }
  }
}

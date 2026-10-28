import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking_model.dart';
import '../../viewmodels/my_bookings_viewmodel.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmittingReview = true);
    final (success, msg) = await ref.read(myBookingsViewModelProvider.notifier).addReview(
          bookingId: widget.booking.id,
          rating: _rating,
          comment: _commentController.text.isEmpty ? null : _commentController.text,
        );
    if (mounted) {
      setState(() => _isSubmittingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$msg (+10 điểm thưởng tích lũy!)' : msg),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final fieldName = b.effectiveFieldName;
    final dateStr = b.effectiveBookingDate;
    final slotTime = b.slotTimeText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mã đơn: #${b.id.length > 8 ? b.id.substring(0, 8) : b.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        _buildStatusBadge(b.status),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('Thời gian tạo: ${Formatters.dateTime(b.createdAt)}'),
                    if (b.note != null && b.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Ghi chú: ${b.note}', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Thông tin sân & Khung giờ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.teal, size: 36),
                title: Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ngày: ${Formatters.dateString(dateStr)}\nKhung giờ: $slotTime'),
                trailing: Text(
                  Formatters.currency(b.unitPrice > 0 ? b.unitPrice : b.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Chi tiết thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    if (b.unitPrice > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giá gốc:'),
                          Text(Formatters.currency(b.unitPrice)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (b.promotionCode != null && b.promotionCode!.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Khuyến mãi (${b.promotionCode}):', style: const TextStyle(color: Colors.green)),
                          Text('-${Formatters.currency(b.discountAmount)}', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (b.pointsUsed > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Điểm thưởng (${b.pointsUsed} đ):', style: const TextStyle(color: Colors.amber)),
                          Text('-${Formatters.currency(b.pointsUsed * 100.0)}', style: const TextStyle(color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          Formatters.currency(b.totalAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    if (b.pointsEarned > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Điểm tích lũy đơn này:', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                          Text('+${b.pointsEarned} điểm', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Phương thức thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          b.paymentMethod == PaymentMethod.wallet ? Icons.account_balance_wallet : Icons.money,
                          color: Colors.teal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b.paymentMethod == PaymentMethod.wallet
                              ? 'Ví điện tử SportsBook'
                              : 'Tiền mặt tại quầy',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Trạng thái: '),
                        Text(
                          b.isCashPending
                              ? 'Chờ thu tiền mặt tại sân'
                              : b.isPaid
                                  ? 'Đã thanh toán thành công'
                                  : 'Chưa thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: b.isPaid
                                ? Colors.green
                                : b.isCashPending
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (b.status == BookingStatus.completed) ...[
              const SizedBox(height: 18),
              const Text('Đánh giá dịch vụ & Tích điểm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              if (b.review != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < b.review!.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        if (b.review!.comment != null && b.review!.comment!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(b.review!.comment!),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        const Text(
                          'Đánh giá chất lượng sân để nhận ngay +10 điểm tích lũy!',
                          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              icon: Icon(
                                star <= _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () => setState(() => _rating = star),
                            );
                          }),
                        ),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Nhận xét của bạn về sân bóng (tùy chọn)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isSubmittingReview ? null : _submitReview,
                            child: _isSubmittingReview
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Gửi đánh giá (+10 điểm)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Đã xác nhận';
        break;
      case BookingStatus.completed:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Hoàn thành';
        break;
      case BookingStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Đã hủy';
        break;
      case BookingStatus.pending:
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'Chờ duyệt';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

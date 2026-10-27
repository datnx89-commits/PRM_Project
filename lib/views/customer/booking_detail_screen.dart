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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã đơn: ${b.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Trạng thái: ${b.status}'),
                    Text('Thời gian tạo: ${Formatters.dateTime(b.createdAt)}'),
                    if (b.note != null && b.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Ghi chú: ${b.note}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Khung giờ đã đặt:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...b.details.map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(d.fieldName ?? 'Sân'),
                    subtitle: Text('Ngày: ${Formatters.dateString(d.bookingDate)} | Giờ: ${d.slotTime}'),
                    trailing: Text(
                      Formatters.currency(d.price),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (b.promotionCode != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã khuyến mãi:'),
                          Text(b.promotionCode!, style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.currency(b.totalAmount),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (b.payment != null) ...[
              const SizedBox(height: 12),
              const Text('Thông tin thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phương thức: ${b.payment!.method}'),
                      Text('Trạng thái: ${b.payment!.status}'),
                      if (b.payment!.transactionCode != null)
                        Text('Mã GD: ${b.payment!.transactionCode}'),
                      if (b.payment!.paidAt != null)
                        Text('Thời gian: ${Formatters.dateTime(b.payment!.paidAt!)}'),
                    ],
                  ),
                ),
              ),
            ],
            if (b.status == BookingStatus.completed) ...[
              const SizedBox(height: 16),
              const Text('Đánh giá dịch vụ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (b.review != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
                        if (b.review!.comment != null) ...[
                          const SizedBox(height: 6),
                          Text(b.review!.comment!),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              icon: Icon(
                                star <= _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () => setState(() => _rating = star),
                            );
                          }),
                        ),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Nhận xét của bạn',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isSubmittingReview ? null : _submitReview,
                          child: _isSubmittingReview
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Gửi đánh giá'),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/field_detail_viewmodel.dart';
import 'booking_screen.dart';

class FieldDetailScreen extends ConsumerWidget {
  final String fieldId;

  const FieldDetailScreen({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldDetailViewModelProvider(fieldId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sân')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final field = state.field;
    if (field == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sân')),
        body: const Center(child: Text('Không tìm thấy thông tin sân.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(field.fieldName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.fieldName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${field.address}, ${field.district}, ${field.city}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${field.averageRating.toStringAsFixed(1)} (${state.reviews.length} đánh giá)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá giờ thường:'),
                        Text(
                          '${Formatters.currency(field.pricePerHour)} / giờ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá giờ cao điểm (17h-21h):'),
                        Text(
                          '${Formatters.currency(field.peakPricePerHour)} / giờ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (field.description != null && field.description!.isNotEmpty) ...[
              const Text(
                'Mô tả sân:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(field.description!),
              const Divider(height: 24),
            ],
            const Text(
              'Đánh giá từ khách hàng:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (state.reviews.isEmpty)
              const Text('Chưa có đánh giá nào cho sân này.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.reviews.length,
                itemBuilder: (context, index) {
                  final r = state.reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r.userFullName ?? 'Khách hàng',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.rating ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.comment != null && r.comment!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(r.comment!),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            Formatters.date(r.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(
                    field: field,
                    slots: state.timeSlots,
                  ),
                ),
              );
            },
            child: const Text('Chọn khung giờ đặt sân', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

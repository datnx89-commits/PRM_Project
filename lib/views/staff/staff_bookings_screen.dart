import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/staff_bookings_viewmodel.dart';
import '../shared/app_drawer.dart';

class StaffBookingsScreen extends ConsumerWidget {
  const StaffBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffBookingsViewModelProvider);
    final vm = ref.read(staffBookingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn đặt sân'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: state.selectedStatus == null,
                    onSelected: (_) => vm.filterByStatus(null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Chờ xử lý'),
                    selected: state.selectedStatus == BookingStatus.pending,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.pending),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Đã xác nhận'),
                    selected: state.selectedStatus == BookingStatus.confirmed,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.confirmed),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Đã hủy'),
                    selected: state.selectedStatus == BookingStatus.cancelled,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.cancelled),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Hoàn thành'),
                    selected: state.selectedStatus == BookingStatus.completed,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.completed),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.loadBookings,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.bookings.isEmpty
                      ? const Center(child: Text('Không có đơn đặt sân nào.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: state.bookings.length,
                          itemBuilder: (context, index) {
                            final b = state.bookings[index];
                            final firstDetail = b.details.isNotEmpty ? b.details.first : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          firstDetail?.fieldName ?? 'Sân',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Chip(
                                          label: Text(
                                            b.status,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Khách: ${b.userFullName ?? b.userEmail ?? b.userId}'),
                                    Text('Ngày: ${Formatters.dateString(firstDetail?.bookingDate ?? '')}'),
                                    Text('Khung giờ: ${b.details.map((d) => d.slotTime ?? '').join(', ')}'),
                                    Text('Tổng tiền: ${Formatters.currency(b.totalAmount)}'),
                                    if (b.note != null && b.note!.isNotEmpty)
                                      Text('Ghi chú: ${b.note}'),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (b.status == BookingStatus.pending) ...[
                                          ElevatedButton(
                                            onPressed: () async {
                                              final (ok, msg) = await vm.confirmBooking(b.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                              }
                                            },
                                            child: const Text('Xác nhận'),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                            onPressed: () async {
                                              final (ok, msg) = await vm.cancelBooking(b.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                              }
                                            },
                                            child: const Text('Hủy đơn'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

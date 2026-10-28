import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../shared/app_drawer.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref, ReportState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: state.fromDate, end: state.toDate),
    );

    if (picked != null) {
      ref.read(reportViewModelProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportViewModelProvider);
    final vm = ref.read(reportViewModelProvider.notifier);
    final s = state.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isOwnerView ? 'Báo cáo doanh thu của tôi' : 'Báo cáo doanh thu hệ thống'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: vm.loadReport,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Từ: ${Formatters.date(state.fromDate)} - Đến: ${Formatters.date(state.toDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context, ref, state),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Chọn ngày'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (s != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Doanh thu', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currency(s.totalRevenue),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Lượt đặt', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                '${s.totalBookings}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Khách hàng', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                '${s.totalCustomers}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tổng số sân', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                '${s.totalFields}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Top 5 sân doanh thu cao nhất:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (s.topFields.isEmpty)
                  const Text('Không có dữ liệu.')
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: s.topFields.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tf = s.topFields[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(tf.fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Số lượt đặt: ${tf.bookingCount}'),
                          trailing: Text(
                            Formatters.currency(tf.revenue),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Doanh thu theo ngày:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (s.revenueByDays.isEmpty)
                  const Text('Không có dữ liệu trong khoảng thời gian này.')
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: s.revenueByDays.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = s.revenueByDays[index];
                        return ListTile(
                          title: Text(Formatters.dateString(r.date)),
                          subtitle: Text('Lượt đặt: ${r.bookingCount}'),
                          trailing: Text(
                            Formatters.currency(r.revenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

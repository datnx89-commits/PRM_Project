import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/field_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/providers.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/staff_bookings_viewmodel.dart';
import '../shared/app_drawer.dart';

class StaffBookingsScreen extends ConsumerStatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  ConsumerState<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends ConsumerState<StaffBookingsScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Future<void> _openWalkInBookingDialog() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final fieldRepo = ref.read(fieldRepositoryProvider);
    final slotRepo = ref.read(timeSlotRepositoryProvider);
    final pricingRepo = ref.read(pricingRepositoryProvider);

    // Lấy danh sách sân
    final ownerId = (user.role == UserRole.admin || user.role == UserRole.superAdmin) ? null : user.id;
    final fields = await fieldRepo.getFields(ownerId: ownerId);

    if (fields.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có sân bóng nào để đặt lịch! Vui lòng tạo sân trước.')),
        );
      }
      return;
    }

    if (!mounted) return;

    FieldModel selectedField = fields.first;
    DateTime selectedDate = DateTime.now();
    List<TimeSlotModel> availableSlots = [];
    TimeSlotModel? selectedSlot;
    bool isLoadingSlots = false;
    double calculatedPrice = 0;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isPaidNow = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> loadSlots() async {
            setModalState(() => isLoadingSlots = true);
            try {
              final slots = await slotRepo.getTimeSlots(fieldId: selectedField.id);
              availableSlots = slots.where((s) => s.isActive).toList();
              selectedSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
              if (selectedSlot != null) {
                final price = await pricingRepo.calculatePrice(
                  fieldId: selectedField.id,
                  bookingDate: selectedDate,
                  startTime: selectedSlot!.startTime,
                  basePrice: selectedSlot!.price,
                );
                calculatedPrice = price;
              }
            } catch (_) {}
            setModalState(() => isLoadingSlots = false);
          }

          if (availableSlots.isEmpty && !isLoadingSlots) {
            loadSlots();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đặt hộ khách vãng lai',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  DropdownButtonFormField<FieldModel>(
                    initialValue: selectedField,
                    decoration: const InputDecoration(labelText: 'Chọn sân bóng', border: OutlineInputBorder()),
                    items: fields.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedField = val;
                          availableSlots.clear();
                          selectedSlot = null;
                        });
                        loadSlots();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                              loadSlots();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (availableSlots.isEmpty)
                    const Text('Sân này chưa có khung giờ hoạt động nào.', style: TextStyle(color: Colors.red))
                  else
                    DropdownButtonFormField<TimeSlotModel>(
                      initialValue: selectedSlot,
                      decoration: const InputDecoration(labelText: 'Chọn khung giờ', border: OutlineInputBorder()),
                      items: availableSlots.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.startTime} - ${s.endTime} (${_currencyFormat.format(s.price)})'),
                        );
                      }).toList(),
                      onChanged: (slot) async {
                        if (slot != null) {
                          setModalState(() => selectedSlot = slot);
                          final price = await pricingRepo.calculatePrice(
                            fieldId: selectedField.id,
                            bookingDate: selectedDate,
                            startTime: slot.startTime,
                            basePrice: slot.price,
                          );
                          setModalState(() => calculatedPrice = price);
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên khách hàng *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giá tính tự động:'),
                        Text(
                          _currencyFormat.format(calculatedPrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Khách đã thanh toán tiền mặt'),
                    subtitle: const Text('Đánh dấu đã thu tiền tại quầy'),
                    value: isPaidNow,
                    onChanged: (val) => setModalState(() => isPaidNow = val),
                  ),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú thêm (tùy chọn)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (selectedSlot == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn khung giờ.')),
                          );
                          return;
                        }
                        if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tên và số điện thoại khách.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        final vm = ref.read(staffBookingsViewModelProvider.notifier);
                        final (ok, msg) = await vm.createWalkInBooking(
                          fieldId: selectedField.id,
                          timeSlotId: selectedSlot!.id,
                          bookingDate: selectedDate,
                          customerName: nameCtrl.text.trim(),
                          customerPhone: phoneCtrl.text.trim(),
                          price: calculatedPrice,
                          isPaidCash: isPaidNow,
                          note: noteCtrl.text.trim(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Xác nhận tạo đơn đặt hộ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffBookingsViewModelProvider);
    final vm = ref.read(staffBookingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: vm.loadBookings,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Đặt hộ khách'),
        onPressed: _openWalkInBookingDialog,
      ),
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
                    label: const Text('Hoàn thành'),
                    selected: state.selectedStatus == BookingStatus.completed,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.completed),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Đã hủy'),
                    selected: state.selectedStatus == BookingStatus.cancelled,
                    onSelected: (_) => vm.filterByStatus(BookingStatus.cancelled),
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
                          padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 80),
                          itemCount: state.bookings.length,
                          itemBuilder: (context, index) {
                            final b = state.bookings[index];
                            final fieldName = b.effectiveFieldName;
                            final dateText = Formatters.dateString(b.effectiveBookingDate);
                            final slotTime = b.slotTimeText;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: b.isCashPending
                                      ? Colors.orange.shade400
                                      : Colors.grey.shade200,
                                  width: b.isCashPending ? 1.5 : 1,
                                ),
                              ),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusBgColor(b.status),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _getStatusText(b.status),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusTextColor(b.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 15, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text('Khách: ${b.userFullName ?? b.userEmail ?? b.userId}'),
                                        if (b.createdById != null && b.createdById!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Đặt tại quầy',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month, size: 15, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text('Ngày: $dateText | Giờ: $slotTime'),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.payments_outlined, size: 15, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tổng tiền: ${_currencyFormat.format(b.totalAmount)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPaymentBadge(b),
                                      ],
                                    ),
                                    if (b.note != null && b.note!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Ghi chú: ${b.note}',
                                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                                        ),
                                      ),

                                    // Khối thao tác xác nhận thu tiền mặt
                                    if (b.isCashPending) ...[
                                      const Divider(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Khách chọn trả tiền mặt tại sân (${_currencyFormat.format(b.totalAmount)}):',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                            onPressed: () async {
                                              final (ok, msg) = await vm.rejectCashPayment(b.id, reason: 'Chủ sân từ chối thu tiền');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                              }
                                            },
                                            child: const Text('Từ chối thu tiền'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.check, size: 16),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () async {
                                              final (ok, msg) = await vm.confirmCashPayment(b.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                              }
                                            },
                                            label: const Text('Đã thu tiền mặt'),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Khối thao tác duyệt/hủy thông thường
                                    if (!b.isCashPending && (b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)) ...[
                                      const Divider(height: 16),
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

  Widget _buildPaymentBadge(b) {
    if (b.isCashPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Chờ thu tiền mặt',
          style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold),
        ),
      );
    } else if (b.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          b.paymentMethod == PaymentMethod.wallet ? 'Đã trừ ví' : 'Đã trả tiền mặt',
          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Chưa thanh toán',
          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green.shade50;
      case BookingStatus.completed:
        return Colors.blue.shade50;
      case BookingStatus.cancelled:
        return Colors.red.shade50;
      case BookingStatus.pending:
      default:
        return Colors.orange.shade50;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green.shade800;
      case BookingStatus.completed:
        return Colors.blue.shade800;
      case BookingStatus.cancelled:
        return Colors.red.shade800;
      case BookingStatus.pending:
      default:
        return Colors.orange.shade800;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.pending:
      default:
        return 'Chờ duyệt';
    }
  }
}

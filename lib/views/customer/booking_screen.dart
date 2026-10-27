import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/field_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../viewmodels/booking_viewmodel.dart';
import 'payment_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final FieldModel field;
  final List<TimeSlotModel> slots;

  const BookingScreen({
    super.key,
    required this.field,
    required this.slots,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _promoController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String currentDate, BookingProcessViewModel vm) async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(currentDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null) {
      final str = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await vm.setDate(str);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tuple = (widget.field, widget.slots);
    final state = ref.watch(bookingProcessViewModelProvider(tuple));
    final vm = ref.read(bookingProcessViewModelProvider(tuple).notifier);

    final subtotal = state.calculateSubtotal(widget.field);
    final discount = state.calculateDiscount(widget.field);
    final total = state.calculateTotal(widget.field);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt sân: ${widget.field.fieldName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày: ${Formatters.dateString(state.selectedDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(state.selectedDate, vm),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Đổi ngày'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn khung giờ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            state.isLoading && state.bookedSlotIds.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.allSlots.map((slot) {
                      final isBooked = state.bookedSlotIds.contains(slot.id);
                      final isSelected = state.selectedSlots.any((s) => s.id == slot.id);

                      Color? bg;
                      if (isBooked) {
                        bg = Colors.grey.shade300;
                      } else if (isSelected) {
                        bg = Colors.blue.shade100;
                      }

                      return ChoiceChip(
                        label: Text(
                          '${slot.startTime} - ${slot.endTime}${slot.isPeak ? ' *' : ''}',
                          style: TextStyle(
                            color: isBooked ? Colors.grey : (isSelected ? Colors.blue.shade900 : Colors.black),
                            decoration: isBooked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: bg,
                        onSelected: isBooked ? null : (_) => vm.toggleSlot(slot),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 8),
            const Text(
              '(*) Khung giờ cao điểm (17:00 - 21:00)',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      labelText: 'Mã giảm giá',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: state.promoError,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => vm.applyPromo(_promoController.text),
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
            if (state.appliedPromo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Đã áp dụng: ${state.appliedPromo!.code} (-${state.appliedPromo!.discountPercent}%)',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho chủ sân (nếu có)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: vm.setNote,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số khung giờ đã chọn:'),
                        Text('${state.selectedSlots.length}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính:'),
                        Text(Formatters.currency(subtotal)),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giảm giá:'),
                          Text(
                            '- ${Formatters.currency(discount)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thanh toán:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.currency(total),
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
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
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
            onPressed: state.isLoading || state.selectedSlots.isEmpty
                ? null
                : () async {
                    final ok = await vm.submitBooking();
                    if (!context.mounted) return;
                    final nextState = ref.read(bookingProcessViewModelProvider(tuple));
                    if (ok && nextState.successBookingId != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            bookingId: nextState.successBookingId!,
                            totalAmount: total,
                            fieldName: widget.field.fieldName,
                          ),
                        ),
                      );
                    }


                  },
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tiếp tục thanh toán', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

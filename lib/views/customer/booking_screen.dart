import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/field_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
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
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final subtotal = state.calculateSubtotal(widget.field);
    final promoDiscount = state.calculatePromoDiscount(widget.field);
    final tierDiscount = state.calculateTierDiscount(widget.field, user);
    final total = state.calculateTotal(widget.field, user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt sân: ${widget.field.fieldName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Ngày Vàng nếu có
            if (state.goldenDay != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hôm nay là Ngày Vàng: ${state.goldenDay!.name}\n'
                        'Hệ số giá: x${state.goldenDay!.priceMultiplier} • Tích điểm: x${state.goldenDay!.pointsMultiplier}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Chọn ngày
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

            // Danh sách khung giờ
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
                      final slotPrice = state.getSlotPrice(widget.field, slot);

                      Color? bg;
                      if (isBooked) {
                        bg = Colors.grey.shade300;
                      } else if (isSelected) {
                        bg = Colors.blue.shade100;
                      }

                      return ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isBooked ? Colors.grey : (isSelected ? Colors.blue.shade900 : Colors.black),
                                decoration: isBooked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              Formatters.currency(slotPrice),
                              style: TextStyle(
                                fontSize: 11,
                                color: isBooked ? Colors.grey : (isSelected ? Colors.blue.shade900 : Colors.grey.shade700),
                              ),
                            ),
                          ],
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
              '(*) Giá từng khung giờ đã được tự động áp dụng bảng giá linh hoạt và ngày vàng.',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
            const Divider(height: 24),

            // Mã giảm giá
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

            // Ghi chú
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

            // Tóm tắt chi phí
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số khung giờ đã chọn:'),
                        Text('${state.selectedSlots.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    if (promoDiscount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giảm giá Voucher:'),
                          Text(
                            '- ${Formatters.currency(promoDiscount)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    if (tierDiscount > 0 && user != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ưu đãi Hạng ${user.membershipTier.name} (-${user.membershipTier.discountPercent}%):'),
                          Text(
                            '- ${Formatters.currency(tierDiscount)}',
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
                    if (ok && nextState.successBookingIds.isNotEmpty) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            bookingIds: nextState.successBookingIds,
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

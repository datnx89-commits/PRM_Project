import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/field_model.dart';
import '../data/models/promotion_model.dart';
import '../data/models/time_slot_model.dart';
import '../data/providers.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/promotion_repository.dart';
import 'auth_viewmodel.dart';

class BookingProcessState {
  final String selectedDate;
  final List<String> bookedSlotIds;
  final List<TimeSlotModel> allSlots;
  final List<TimeSlotModel> selectedSlots;
  final PromotionModel? appliedPromo;
  final String? promoError;
  final String note;
  final bool isLoading;
  final String? errorMessage;
  final String? successBookingId;

  BookingProcessState({
    required this.selectedDate,
    this.bookedSlotIds = const [],
    this.allSlots = const [],
    this.selectedSlots = const [],
    this.appliedPromo,
    this.promoError,
    this.note = '',
    this.isLoading = false,
    this.errorMessage,
    this.successBookingId,
  });

  double calculateSubtotal(FieldModel field) {
    double sum = 0.0;
    for (var slot in selectedSlots) {
      sum += slot.isPeak ? field.peakPricePerHour : field.pricePerHour;
    }
    return sum;
  }

  double calculateDiscount(FieldModel field) {
    if (appliedPromo == null) return 0.0;
    final subtotal = calculateSubtotal(field);
    return appliedPromo!.calculateDiscount(subtotal);
  }

  double calculateTotal(FieldModel field) {
    final subtotal = calculateSubtotal(field);
    final discount = calculateDiscount(field);
    return subtotal - discount;
  }

  BookingProcessState copyWith({
    String? selectedDate,
    List<String>? bookedSlotIds,
    List<TimeSlotModel>? allSlots,
    List<TimeSlotModel>? selectedSlots,
    PromotionModel? appliedPromo,
    String? promoError,
    String? note,
    bool? isLoading,
    String? errorMessage,
    String? successBookingId,
    bool clearPromo = false,
    bool clearPromoError = false,
  }) {
    return BookingProcessState(
      selectedDate: selectedDate ?? this.selectedDate,
      bookedSlotIds: bookedSlotIds ?? this.bookedSlotIds,
      allSlots: allSlots ?? this.allSlots,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      note: note ?? this.note,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successBookingId: successBookingId,
    );
  }
}

class BookingProcessViewModel extends StateNotifier<BookingProcessState> {
  final BookingRepository _bookingRepository;
  final PromotionRepository _promotionRepository;
  final Ref _ref;
  final FieldModel field;

  BookingProcessViewModel({
    required BookingRepository bookingRepository,
    required PromotionRepository promotionRepository,
    required Ref ref,
    required this.field,
    required List<TimeSlotModel> slots,
  })  : _bookingRepository = bookingRepository,
        _promotionRepository = promotionRepository,
        _ref = ref,
        super(BookingProcessState(
          selectedDate: _getTodayString(),
          allSlots: slots,
        )) {
    loadBookedSlots();
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> setDate(String yyyyMmDd) async {
    state = state.copyWith(
      selectedDate: yyyyMmDd,
      selectedSlots: [],
      clearPromo: false,
    );
    await loadBookedSlots();
  }

  Future<void> loadBookedSlots() async {
    state = state.copyWith(isLoading: true);
    try {
      final ids = await _bookingRepository.getBookedSlotIds(field.id, state.selectedDate);
      state = state.copyWith(bookedSlotIds: ids, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không thể tải lịch đã đặt.');
    }
  }

  void toggleSlot(TimeSlotModel slot) {
    if (state.bookedSlotIds.contains(slot.id)) return;

    final current = List<TimeSlotModel>.from(state.selectedSlots);
    final exists = current.any((s) => s.id == slot.id);
    if (exists) {
      current.removeWhere((s) => s.id == slot.id);
    } else {
      current.add(slot);
    }
    state = state.copyWith(selectedSlots: current);
  }

  Future<void> applyPromo(String code) async {
    if (code.trim().isEmpty) {
      state = state.copyWith(clearPromo: true, clearPromoError: true);
      return;
    }
    final promo = await _promotionRepository.getPromotionByCode(code.trim());
    if (promo == null) {
      state = state.copyWith(
        clearPromo: true,
        promoError: 'Mã khuyến mãi không tồn tại.',
      );
      return;
    }
    if (!promo.isValidForDate(state.selectedDate)) {
      state = state.copyWith(
        clearPromo: true,
        promoError: 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn.',
      );
      return;
    }
    state = state.copyWith(
      appliedPromo: promo,
      clearPromoError: true,
    );
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  Future<bool> submitBooking() async {
    final authState = _ref.read(authViewModelProvider);
    final user = authState.user;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Vui lòng đăng nhập trước khi đặt sân.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final (success, message, bookingId) = await _bookingRepository.createBooking(
      userId: user.id,
      userEmail: user.email,
      userFullName: user.fullName,
      field: field,
      bookingDate: state.selectedDate,
      selectedSlots: state.selectedSlots,
      promo: state.appliedPromo,
      note: state.note.isEmpty ? null : state.note,
    );

    if (success && bookingId != null) {
      state = state.copyWith(
        isLoading: false,
        successBookingId: bookingId,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }
}

final bookingProcessViewModelProvider = StateNotifierProvider.autoDispose
    .family<BookingProcessViewModel, BookingProcessState, (FieldModel, List<TimeSlotModel>)>(
        (ref, params) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  final promoRepo = ref.watch(promotionRepositoryProvider);
  return BookingProcessViewModel(
    bookingRepository: bookingRepo,
    promotionRepository: promoRepo,
    ref: ref,
    field: params.$1,
    slots: params.$2,
  );
});

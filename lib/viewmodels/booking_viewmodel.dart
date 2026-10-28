import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/pricing/pricing_engine.dart';
import '../data/models/field_model.dart';
import '../data/models/field_pricing_rule_model.dart';
import '../data/models/golden_day_model.dart';
import '../data/models/promotion_model.dart';
import '../data/models/time_slot_model.dart';
import '../data/models/user_model.dart';
import '../data/providers.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/pricing_repository.dart';
import '../data/repositories/promotion_repository.dart';
import 'auth_viewmodel.dart';

class BookingProcessState {
  final String selectedDate;
  final List<String> bookedSlotIds;
  final List<TimeSlotModel> allSlots;
  final List<TimeSlotModel> selectedSlots;
  final List<FieldPricingRuleModel> pricingRules;
  final GoldenDayModel? goldenDay;
  final PromotionModel? appliedPromo;
  final String? promoError;
  final String note;
  final bool isLoading;
  final String? errorMessage;
  final List<String> successBookingIds;

  BookingProcessState({
    required this.selectedDate,
    this.bookedSlotIds = const [],
    this.allSlots = const [],
    this.selectedSlots = const [],
    this.pricingRules = const [],
    this.goldenDay,
    this.appliedPromo,
    this.promoError,
    this.note = '',
    this.isLoading = false,
    this.errorMessage,
    this.successBookingIds = const [],
  });

  /// Giá 1 khung giờ cụ thể theo Strategy PricingEngine
  double getSlotPrice(FieldModel field, TimeSlotModel slot) {
    final dateObj = DateTime.tryParse(selectedDate) ?? DateTime.now();
    return PricingEngine.calculateSlotFinalPrice(
      field: field,
      slot: slot,
      date: dateObj,
      rules: pricingRules,
      goldenDay: goldenDay,
    );
  }

  /// Tổng tiền trước giảm giá của tất cả khung giờ được chọn
  double calculateSubtotal(FieldModel field) {
    double sum = 0.0;
    for (var slot in selectedSlots) {
      sum += getSlotPrice(field, slot);
    }
    return sum;
  }

  /// Tiền giảm từ mã khuyến mãi
  double calculatePromoDiscount(FieldModel field) {
    if (appliedPromo == null) return 0.0;
    final subtotal = calculateSubtotal(field);
    return appliedPromo!.calculateDiscount(subtotal);
  }

  /// Tiền giảm theo Hạng thành viên (% trên phần còn lại)
  double calculateTierDiscount(FieldModel field, UserModel? user) {
    if (user == null) return 0.0;
    final tier = user.membershipTier;
    if (tier.discountPercent <= 0) return 0.0;

    final subtotal = calculateSubtotal(field);
    final promoDisc = calculatePromoDiscount(field);
    final remaining = (subtotal - promoDisc).clamp(0.0, double.infinity);
    return ((remaining * tier.discountPercent) / 100.0).roundToDouble();
  }

  /// Tổng tiền giảm giá (Khuyến mãi + Hạng thành viên)
  double calculateTotalDiscount(FieldModel field, UserModel? user) {
    return calculatePromoDiscount(field) + calculateTierDiscount(field, user);
  }

  /// Số tiền phải thanh toán cuối cùng
  double calculateTotal(FieldModel field, UserModel? user) {
    final subtotal = calculateSubtotal(field);
    final discount = calculateTotalDiscount(field, user);
    return (subtotal - discount).clamp(0.0, double.infinity);
  }

  BookingProcessState copyWith({
    String? selectedDate,
    List<String>? bookedSlotIds,
    List<TimeSlotModel>? allSlots,
    List<TimeSlotModel>? selectedSlots,
    List<FieldPricingRuleModel>? pricingRules,
    GoldenDayModel? goldenDay,
    PromotionModel? appliedPromo,
    String? promoError,
    String? note,
    bool? isLoading,
    String? errorMessage,
    List<String>? successBookingIds,
    bool clearPromo = false,
    bool clearPromoError = false,
    bool clearGoldenDay = false,
  }) {
    return BookingProcessState(
      selectedDate: selectedDate ?? this.selectedDate,
      bookedSlotIds: bookedSlotIds ?? this.bookedSlotIds,
      allSlots: allSlots ?? this.allSlots,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      pricingRules: pricingRules ?? this.pricingRules,
      goldenDay: clearGoldenDay ? null : (goldenDay ?? this.goldenDay),
      appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      note: note ?? this.note,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successBookingIds: successBookingIds ?? this.successBookingIds,
    );
  }
}

class BookingProcessViewModel extends StateNotifier<BookingProcessState> {
  final BookingRepository _bookingRepository;
  final PromotionRepository _promotionRepository;
  final PricingRepository _pricingRepository;
  final Ref _ref;
  final FieldModel field;

  BookingProcessViewModel({
    required BookingRepository bookingRepository,
    required PromotionRepository promotionRepository,
    required PricingRepository pricingRepository,
    required Ref ref,
    required this.field,
    required List<TimeSlotModel> slots,
  })  : _bookingRepository = bookingRepository,
        _promotionRepository = promotionRepository,
        _pricingRepository = pricingRepository,
        _ref = ref,
        super(BookingProcessState(
          selectedDate: _getTodayString(),
          allSlots: slots,
        )) {
    loadDateData();
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
    await loadDateData();
  }

  Future<void> loadDateData() async {
    state = state.copyWith(isLoading: true);
    try {
      final bookedIdsFuture = _bookingRepository.getBookedSlotIds(field.id, state.selectedDate);
      final rulesFuture = _pricingRepository.getRules(field.id);
      final goldenFuture = _pricingRepository.getGoldenDay(field.id, state.selectedDate);

      final results = await Future.wait([bookedIdsFuture, rulesFuture, goldenFuture]);

      state = state.copyWith(
        bookedSlotIds: results[0] as List<String>,
        pricingRules: results[1] as List<FieldPricingRuleModel>,
        goldenDay: results[2] as GoldenDayModel?,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không thể tải lịch đặt hoặc bảng giá.');
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
    if (!promo.isValidForField(field.ownerId)) {
      state = state.copyWith(
        clearPromo: true,
        promoError: 'Mã khuyến mãi này không áp dụng cho sân bạn chọn.',
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

    final (success, message, bookingIds) = await _bookingRepository.createBooking(
      userId: user.id,
      userEmail: user.email,
      userFullName: user.fullName,
      userPhone: user.phone,
      field: field,
      bookingDate: state.selectedDate,
      selectedSlots: state.selectedSlots,
      promo: state.appliedPromo,
      note: state.note.isEmpty ? null : state.note,
      userLifetimePoints: user.lifetimePoints,
    );

    if (success && bookingIds.isNotEmpty) {
      state = state.copyWith(
        isLoading: false,
        successBookingIds: bookingIds,
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
  final pricingRepo = ref.watch(pricingRepositoryProvider);
  return BookingProcessViewModel(
    bookingRepository: bookingRepo,
    promotionRepository: promoRepo,
    pricingRepository: pricingRepo,
    ref: ref,
    field: params.$1,
    slots: params.$2,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/models/booking_model.dart';
import '../data/providers.dart';
import '../data/repositories/booking_repository.dart';
import 'auth_viewmodel.dart';

class StaffBookingsState {
  final List<BookingModel> bookings;
  final String? selectedStatus;
  final bool isLoading;
  final String? errorMessage;

  StaffBookingsState({
    this.bookings = const [],
    this.selectedStatus,
    this.isLoading = false,
    this.errorMessage,
  });

  StaffBookingsState copyWith({
    List<BookingModel>? bookings,
    String? selectedStatus,
    bool? isLoading,
    String? errorMessage,
    bool clearStatus = false,
  }) {
    return StaffBookingsState(
      bookings: bookings ?? this.bookings,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class StaffBookingsViewModel extends StateNotifier<StaffBookingsState> {
  final BookingRepository _bookingRepository;
  final Ref _ref;

  StaffBookingsViewModel(this._bookingRepository, this._ref) : super(StaffBookingsState()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    await _bookingRepository.completePastBookings();
    try {
      final ownerId = user.role == UserRole.admin ? null : user.id;
      final list = await _bookingRepository.getBookingsForStaff(
        ownerId: ownerId,
        status: state.selectedStatus,
      );
      state = state.copyWith(bookings: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không thể tải danh sách đơn đặt.');
    }
  }

  void filterByStatus(String? status) {
    state = state.copyWith(selectedStatus: status, clearStatus: status == null);
    loadBookings();
  }

  Future<(bool, String)> confirmBooking(String bookingId) async {
    final (success, msg) = await _bookingRepository.confirmBooking(bookingId);
    if (success) {
      await loadBookings();
    }
    return (success, msg);
  }

  Future<(bool, String)> cancelBooking(String bookingId) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return (false, 'Chưa đăng nhập.');

    final (success, msg) = await _bookingRepository.cancelBooking(
      bookingId: bookingId,
      userId: user.id,
      isStaff: true,
    );

    if (success) {
      await loadBookings();
    }
    return (success, msg);
  }
}

final staffBookingsViewModelProvider =
    StateNotifierProvider<StaffBookingsViewModel, StaffBookingsState>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return StaffBookingsViewModel(repo, ref);
});

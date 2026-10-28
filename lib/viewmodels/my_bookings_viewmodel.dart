import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_model.dart';
import '../data/providers.dart';
import '../data/repositories/booking_repository.dart';
import 'auth_viewmodel.dart';

class MyBookingsState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? errorMessage;
  final String? message;

  MyBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.errorMessage,
    this.message,
  });

  MyBookingsState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    String? errorMessage,
    String? message,
  }) {
    return MyBookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      message: message,
    );
  }
}

class MyBookingsViewModel extends StateNotifier<MyBookingsState> {
  final BookingRepository _bookingRepository;
  final Ref _ref;

  MyBookingsViewModel(this._bookingRepository, this._ref) : super(MyBookingsState()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    await _bookingRepository.completePastBookings();
    try {
      final list = await _bookingRepository.getBookingsByUser(user.id);
      state = state.copyWith(bookings: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không thể tải lịch sử đặt sân.');
    }
  }

  Future<(bool, String)> cancelBooking(String bookingId) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return (false, 'Chưa đăng nhập.');

    final (success, msg) = await _bookingRepository.cancelBooking(
      bookingId: bookingId,
      userId: user.id,
      isStaff: false,
    );

    if (success) {
      await loadBookings();
    }
    return (success, msg);
  }

  Future<(bool, String)> payBookings(
    List<String> bookingIds,
    String method, {
    int pointsToUse = 0,
  }) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return (false, 'Chưa đăng nhập.');

    final (success, msg) = await _bookingRepository.payBookings(
      bookingIds: bookingIds,
      userId: user.id,
      method: method,
      pointsToUse: pointsToUse,
    );

    if (success) {
      await loadBookings();
    }
    return (success, msg);
  }

  Future<(bool, String)> payBooking(String bookingId, String method, {int pointsToUse = 0}) async {
    return payBookings([bookingId], method, pointsToUse: pointsToUse);
  }

  Future<(bool, String)> addReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return (false, 'Chưa đăng nhập.');

    final (success, msg) = await _bookingRepository.addReview(
      bookingId: bookingId,
      userId: user.id,
      userFullName: user.fullName,
      rating: rating,
      comment: comment,
    );

    if (success) {
      await loadBookings();
    }
    return (success, msg);
  }
}

final myBookingsViewModelProvider =
    StateNotifierProvider<MyBookingsViewModel, MyBookingsState>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return MyBookingsViewModel(repo, ref);
});

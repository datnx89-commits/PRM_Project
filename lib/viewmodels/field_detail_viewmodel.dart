import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/field_model.dart';
import '../data/models/review_model.dart';
import '../data/models/time_slot_model.dart';
import '../data/providers.dart';
import '../data/repositories/field_repository.dart';

class FieldDetailState {
  final FieldModel? field;
  final List<TimeSlotModel> timeSlots;
  final List<ReviewModel> reviews;
  final bool isLoading;
  final String? errorMessage;

  FieldDetailState({
    this.field,
    this.timeSlots = const [],
    this.reviews = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FieldDetailState copyWith({
    FieldModel? field,
    List<TimeSlotModel>? timeSlots,
    List<ReviewModel>? reviews,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FieldDetailState(
      field: field ?? this.field,
      timeSlots: timeSlots ?? this.timeSlots,
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FieldDetailViewModel extends StateNotifier<FieldDetailState> {
  final FieldRepository _fieldRepository;
  final String fieldId;

  FieldDetailViewModel(this._fieldRepository, this.fieldId)
      : super(FieldDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true);
    try {
      final field = await _fieldRepository.getFieldDetail(fieldId);
      final slots = await _fieldRepository.getTimeSlots(fieldId);
      final reviews = await _fieldRepository.getFieldReviews(fieldId);
      state = state.copyWith(
        field: field,
        timeSlots: slots,
        reviews: reviews,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải thông tin sân.',
      );
    }
  }
}

final fieldDetailViewModelProvider = StateNotifierProvider.family<
    FieldDetailViewModel, FieldDetailState, String>((ref, fieldId) {
  final repo = ref.watch(fieldRepositoryProvider);
  return FieldDetailViewModel(repo, fieldId);
});

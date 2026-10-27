import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/promotion_model.dart';
import '../data/providers.dart';
import '../data/repositories/promotion_repository.dart';

class PromotionState {
  final List<PromotionModel> promotions;
  final bool isLoading;
  final String? errorMessage;

  PromotionState({
    this.promotions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PromotionState copyWith({
    List<PromotionModel>? promotions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PromotionState(
      promotions: promotions ?? this.promotions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PromotionViewModel extends StateNotifier<PromotionState> {
  final PromotionRepository _promotionRepository;

  PromotionViewModel(this._promotionRepository) : super(PromotionState()) {
    loadPromotions();
  }

  Future<void> loadPromotions() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _promotionRepository.getAllPromotions();
      state = state.copyWith(promotions: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải danh sách khuyến mãi.',
      );
    }
  }

  Future<(bool, String)> createPromotion(PromotionModel promo) async {
    final (success, msg) = await _promotionRepository.createPromotion(promo);
    if (success) {
      await loadPromotions();
    }
    return (success, msg);
  }

  Future<(bool, String)> updatePromotion(PromotionModel promo) async {
    final (success, msg) = await _promotionRepository.updatePromotion(promo);
    if (success) {
      await loadPromotions();
    }
    return (success, msg);
  }

  Future<void> toggleActive(String id) async {
    await _promotionRepository.togglePromotionActive(id);
    await loadPromotions();
  }
}

final promotionViewModelProvider =
    StateNotifierProvider<PromotionViewModel, PromotionState>((ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return PromotionViewModel(repo);
});

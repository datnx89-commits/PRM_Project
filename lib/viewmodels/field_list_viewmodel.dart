import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/field_model.dart';
import '../data/models/field_type_model.dart';
import '../data/providers.dart';
import '../data/repositories/field_repository.dart';

class FieldListState {
  final List<FieldModel> fields;
  final List<FieldTypeModel> fieldTypes;
  final List<String> cities;
  final String keyword;
  final String? selectedFieldTypeId;
  final String? selectedCity;
  final double? maxPrice;
  final int? minRating;
  final bool isLoading;
  final String? errorMessage;

  FieldListState({
    this.fields = const [],
    this.fieldTypes = const [],
    this.cities = const [],
    this.keyword = '',
    this.selectedFieldTypeId,
    this.selectedCity,
    this.maxPrice,
    this.minRating,
    this.isLoading = false,
    this.errorMessage,
  });

  FieldListState copyWith({
    List<FieldModel>? fields,
    List<FieldTypeModel>? fieldTypes,
    List<String>? cities,
    String? keyword,
    String? selectedFieldTypeId,
    String? selectedCity,
    double? maxPrice,
    int? minRating,
    bool? isLoading,
    String? errorMessage,
    bool clearFieldType = false,
    bool clearCity = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
  }) {
    return FieldListState(
      fields: fields ?? this.fields,
      fieldTypes: fieldTypes ?? this.fieldTypes,
      cities: cities ?? this.cities,
      keyword: keyword ?? this.keyword,
      selectedFieldTypeId: clearFieldType ? null : (selectedFieldTypeId ?? this.selectedFieldTypeId),
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FieldListViewModel extends StateNotifier<FieldListState> {
  final FieldRepository _fieldRepository;

  FieldListViewModel(this._fieldRepository) : super(FieldListState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final types = await _fieldRepository.getFieldTypes();
      final cities = await _fieldRepository.getCities();
      final fields = await _fieldRepository.searchFields();
      state = state.copyWith(
        fieldTypes: types,
        cities: cities,
        fields: fields,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách sân.',
      );
    }
  }

  Future<void> search() async {
    state = state.copyWith(isLoading: true);
    try {
      final fields = await _fieldRepository.searchFields(
        keyword: state.keyword,
        fieldTypeId: state.selectedFieldTypeId,
        city: state.selectedCity,
        maxPrice: state.maxPrice,
        minRating: state.minRating,
      );
      state = state.copyWith(fields: fields, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tìm kiếm sân.',
      );
    }
  }

  void setKeyword(String val) {
    state = state.copyWith(keyword: val);
  }

  void setFieldType(String? val) {
    state = state.copyWith(selectedFieldTypeId: val, clearFieldType: val == null);
    search();
  }

  void setCity(String? val) {
    state = state.copyWith(selectedCity: val, clearCity: val == null);
    search();
  }

  void setMaxPrice(double? val) {
    state = state.copyWith(maxPrice: val, clearMaxPrice: val == null);
    search();
  }

  void setMinRating(int? val) {
    state = state.copyWith(minRating: val, clearMinRating: val == null);
    search();
  }

  void resetFilters() {
    state = state.copyWith(
      keyword: '',
      clearFieldType: true,
      clearCity: true,
      clearMaxPrice: true,
      clearMinRating: true,
    );
    search();
  }
}

final fieldListViewModelProvider =
    StateNotifierProvider<FieldListViewModel, FieldListState>((ref) {
  final repo = ref.watch(fieldRepositoryProvider);
  return FieldListViewModel(repo);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/models/field_model.dart';
import '../data/models/field_type_model.dart';
import '../data/providers.dart';
import '../data/repositories/field_repository.dart';
import 'auth_viewmodel.dart';

class FieldManageState {
  final List<FieldModel> fields;
  final List<FieldTypeModel> fieldTypes;
  final bool isLoading;
  final String? errorMessage;

  FieldManageState({
    this.fields = const [],
    this.fieldTypes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FieldManageState copyWith({
    List<FieldModel>? fields,
    List<FieldTypeModel>? fieldTypes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FieldManageState(
      fields: fields ?? this.fields,
      fieldTypes: fieldTypes ?? this.fieldTypes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FieldManageViewModel extends StateNotifier<FieldManageState> {
  final FieldRepository _fieldRepository;
  final Ref _ref;

  FieldManageViewModel(this._fieldRepository, this._ref) : super(FieldManageState()) {
    loadData();
  }

  Future<void> loadData() async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final types = await _fieldRepository.getFieldTypes();
      final fields = user.role == UserRole.admin
          ? await _fieldRepository.getAllFieldsForAdmin()
          : await _fieldRepository.getFieldsByOwner(user.id);

      state = state.copyWith(
        fieldTypes: types,
        fields: fields,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải danh sách sân quản lý.',
      );
    }
  }

  Future<(bool, String)> saveField(FieldModel field, bool isEditing) async {
    final user = _ref.read(authViewModelProvider).user;
    if (user == null) return (false, 'Chưa đăng nhập.');

    state = state.copyWith(isLoading: true);
    try {
      if (isEditing) {
        await _fieldRepository.updateField(field);
      } else {
        final toCreate = field.copyWith(ownerId: user.id);
        await _fieldRepository.createField(toCreate);
      }
      await loadData();
      return (true, isEditing ? 'Cập nhật sân thành công.' : 'Tạo sân thành công (đã tự tạo 16 khung giờ).');
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return (false, 'Đã xảy ra lỗi khi lưu sân.');
    }
  }

  Future<(bool, String)> deleteOrClose(String fieldId) async {
    state = state.copyWith(isLoading: true);
    try {
      final isDeleted = await _fieldRepository.deleteOrCloseField(fieldId);
      await loadData();
      return (true, isDeleted ? 'Đã xóa sân thành công.' : 'Sân đã có lịch đặt, chuyển trạng thái sang Đóng sân.');
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return (false, 'Lỗi khi xóa/đóng sân.');
    }
  }
}

final fieldManageViewModelProvider =
    StateNotifierProvider<FieldManageViewModel, FieldManageState>((ref) {
  final repo = ref.watch(fieldRepositoryProvider);
  return FieldManageViewModel(repo, ref);
});

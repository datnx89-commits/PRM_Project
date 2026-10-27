import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/providers.dart';
import '../data/repositories/user_repository.dart';

class UserManageState {
  final List<UserModel> users;
  final bool isLoading;
  final String? errorMessage;

  UserManageState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  UserManageState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserManageState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class UserManageViewModel extends StateNotifier<UserManageState> {
  final UserRepository _userRepository;

  UserManageViewModel(this._userRepository) : super(UserManageState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _userRepository.getAllUsers();
      state = state.copyWith(users: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải danh sách người dùng.',
      );
    }
  }

  Future<void> toggleActive(String userId) async {
    await _userRepository.toggleUserActive(userId);
    await loadUsers();
  }

  Future<void> changeRole(String userId, String newRole) async {
    await _userRepository.changeUserRole(userId, newRole);
    await loadUsers();
  }
}

final userManageViewModelProvider =
    StateNotifierProvider<UserManageViewModel, UserManageState>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserManageViewModel(repo);
});

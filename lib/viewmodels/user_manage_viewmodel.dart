import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/providers.dart';
import '../data/repositories/point_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/wallet_repository.dart';
import 'auth_viewmodel.dart';

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
  final WalletRepository _walletRepository;
  final PointRepository _pointRepository;
  final Ref _ref;

  UserManageViewModel(
    this._userRepository,
    this._walletRepository,
    this._pointRepository,
    this._ref,
  ) : super(UserManageState()) {
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

  /// Admin điều chỉnh số dư ví
  Future<(bool, String)> adjustWallet({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    final adminUser = _ref.read(authViewModelProvider).user;
    if (adminUser == null) return (false, 'Chưa đăng nhập.');

    final result = await _walletRepository.adminAdjustBalance(
      userId: userId,
      amount: amount,
      reason: reason,
      adminId: adminUser.id,
    );

    if (result.$1) {
      await loadUsers();
    }
    return result;
  }

  /// Admin điều chỉnh điểm tích lũy
  Future<(bool, String)> adjustPoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    final adminUser = _ref.read(authViewModelProvider).user;
    if (adminUser == null) return (false, 'Chưa đăng nhập.');

    final result = await _pointRepository.adminAdjustPoints(
      userId: userId,
      points: points,
      reason: reason,
      adminId: adminUser.id,
    );

    if (result.$1) {
      await loadUsers();
    }
    return result;
  }
}

final userManageViewModelProvider =
    StateNotifierProvider<UserManageViewModel, UserManageState>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  final pointRepo = ref.watch(pointRepositoryProvider);
  return UserManageViewModel(userRepo, walletRepo, pointRepo, ref);
});

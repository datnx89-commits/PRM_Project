import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/providers.dart';
import '../data/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    final user = await _authRepository.getCurrentUser();
    state = state.copyWith(
      user: user,
      isLoading: false,
      isInitialized: true,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final (success, message, user) = await _authRepository.login(email, password);
    if (success && user != null) {
      state = state.copyWith(
        user: user,
        isLoading: false,
        errorMessage: null,
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

  Future<(bool, String)> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final (success, message) = await _authRepository.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
    );
    state = state.copyWith(isLoading: false, errorMessage: success ? null : message);
    return (success, message);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.logout();
    state = state.copyWith(
      clearUser: true,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepo);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/promotion_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/user_repository.dart';
import 'services/firebase_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final appConfigProvider = Provider<AppConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppConfig(prefs);
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  return AuthRepository(firebaseService, appConfig);
});

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return FieldRepository(firebaseService);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  return BookingRepository(firebaseService, appConfig);
});

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PromotionRepository(firebaseService);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return UserRepository(firebaseService);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return ReportRepository(firebaseService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/time_slot_model.dart';
import '../core/config/app_config.dart';
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/field_repository.dart';
import 'repositories/maintenance_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/point_repository.dart';
import 'repositories/pricing_repository.dart';
import 'repositories/promotion_repository.dart';
import 'repositories/refund_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/wallet_repository.dart';
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

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  return WalletRepository(firebaseService, appConfig);
});

final pointRepositoryProvider = Provider<PointRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  return PointRepository(firebaseService, appConfig);
});

final pricingRepositoryProvider = Provider<PricingRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PricingRepository(firebaseService);
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  final pointRepo = ref.watch(pointRepositoryProvider);
  return MaintenanceRepository(firebaseService, walletRepo, pointRepo);
});

final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return RefundRepository(firebaseService);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return NotificationRepository(firebaseService);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return ChatRepository(firebaseService);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  final pricingRepo = ref.watch(pricingRepositoryProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  final pointRepo = ref.watch(pointRepositoryProvider);
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final refundRepo = ref.watch(refundRepositoryProvider);
  return BookingRepository(
    firebaseService,
    appConfig,
    pricingRepo,
    walletRepo,
    pointRepo,
    notifRepo,
    refundRepo,
  );
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

class TimeSlotRepository {
  final PricingRepository _pricingRepo;
  TimeSlotRepository(this._pricingRepo);

  Future<List<TimeSlotModel>> getTimeSlots({required String fieldId}) async {
    return _pricingRepo.getAllTimeSlots(fieldId);
  }
}

final timeSlotRepositoryProvider = Provider<TimeSlotRepository>((ref) {
  final pricingRepo = ref.watch(pricingRepositoryProvider);
  return TimeSlotRepository(pricingRepo);
});

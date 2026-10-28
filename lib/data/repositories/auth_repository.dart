import 'package:firebase_auth/firebase_auth.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/hash_util.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthRepository {
  final FirebaseService _firebaseService;
  final AppConfig _appConfig;

  AuthRepository(this._firebaseService, this._appConfig);

  Future<(bool, String, UserModel?)> login(String email, String password) async {
    // 1. Kiểm tra Cơ chế Super Account (Cứu hộ hệ thống qua mã hóa SHA-256)
    // Tài khoản này không lưu trong DB, dùng để khôi phục quyền Admin/User khi hệ thống gặp sự cố
    final emailHash = HashUtil.sha256(email.trim().toLowerCase());
    final passwordHash = HashUtil.sha256(password);

    if (emailHash == SuperAccountConstants.emailHash &&
        passwordHash == SuperAccountConstants.passwordHash) {
      final superUser = UserModel(
        id: SuperAccountConstants.superAdminId,
        email: email.trim().toLowerCase(),
        fullName: 'Super Administrator',
        role: UserRole.superAdmin,
        isActive: true,
        walletBalance: 0.0,
        points: 0,
        lifetimePoints: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      await _appConfig.saveUserSession(
        id: superUser.id,
        email: superUser.email,
        name: superUser.fullName,
        role: superUser.role,
      );

      return (true, 'Đăng nhập quyền Super Admin thành công.', superUser);
    }

    try {
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return (false, 'Không tìm thấy thông tin tài khoản.', null);
      }

      final doc = await _firebaseService.usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return (false, 'Dữ liệu người dùng không tồn tại.', null);
      }

      final user = UserModel.fromMap(doc.data()!, uid);
      if (!user.isActive) {
        await _firebaseService.auth.signOut();
        return (false, 'Tài khoản của bạn đã bị khóa.', null);
      }

      await _appConfig.saveUserSession(
        id: user.id,
        email: user.email,
        name: user.fullName,
        role: user.role,
      );

      return (true, 'Đăng nhập thành công.', user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return (false, 'Email hoặc mật khẩu không đúng.', null);
      }
      return (false, e.message ?? 'Đăng nhập thất bại.', null);
    } catch (e) {
      return (false, 'Đã xảy ra lỗi khi đăng nhập.', null);
    }
  }

  Future<(bool, String)> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return (false, 'Đăng ký không thành công.');
      }

      final newUser = UserModel(
        id: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone?.trim(),
        role: UserRole.customer,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firebaseService.usersCollection.doc(uid).set(newUser.toMap());
      await _firebaseService.auth.signOut();
      return (true, 'Đăng ký thành công. Vui lòng đăng nhập.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return (false, 'Email đã được sử dụng.');
      }
      if (e.code == 'weak-password') {
        return (false, 'Mật khẩu phải có ít nhất 6 ký tự.');
      }
      return (false, e.message ?? 'Đăng ký thất bại.');
    } catch (_) {
      return (false, 'Đã xảy ra lỗi trong quá trình đăng ký.');
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseService.auth.signOut();
    } catch (_) {}
    await _appConfig.clearUserSession();
  }

  Future<UserModel?> getCurrentUser() async {
    // 1. Kiểm tra session Super Admin
    if (_appConfig.userRole == UserRole.superAdmin) {
      return UserModel(
        id: SuperAccountConstants.superAdminId,
        email: _appConfig.userEmail ?? 'superadmin@system.local',
        fullName: _appConfig.userName ?? 'Super Administrator',
        role: UserRole.superAdmin,
        isActive: true,
        walletBalance: 0.0,
        points: 0,
        lifetimePoints: 0,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    final currentFirebaseUser = _firebaseService.auth.currentUser;
    if (currentFirebaseUser != null) {
      final doc = await _firebaseService.usersCollection.doc(currentFirebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, currentFirebaseUser.uid);
      }
    }
    final cachedId = _appConfig.userId;
    if (cachedId != null) {
      final doc = await _firebaseService.usersCollection.doc(cachedId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, cachedId);
      }
    }
    return null;
  }

  Future<void> updateBankInfo({
    required String userId,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolder,
  }) async {
    await _firebaseService.usersCollection.doc(userId).update({
      'bankName': bankName.trim(),
      'bankAccountNumber': bankAccountNumber.trim(),
      'bankAccountHolder': bankAccountHolder.trim(),
    });
  }
}

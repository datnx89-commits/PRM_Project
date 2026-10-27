import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyCancelBeforeHours = 'cancel_before_hours';
  static const String _keyMaxAdvanceDays = 'max_advance_days';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserRole = 'user_role';

  final SharedPreferences _prefs;

  AppConfig(this._prefs);

  int get cancelBeforeHours => _prefs.getInt(_keyCancelBeforeHours) ?? 2;
  Future<void> setCancelBeforeHours(int hours) => _prefs.setInt(_keyCancelBeforeHours, hours);

  int get maxAdvanceBookingDays => _prefs.getInt(_keyMaxAdvanceDays) ?? 30;
  Future<void> setMaxAdvanceBookingDays(int days) => _prefs.setInt(_keyMaxAdvanceDays, days);

  String? get userId => _prefs.getString(_keyUserId);
  String? get userEmail => _prefs.getString(_keyUserEmail);
  String? get userName => _prefs.getString(_keyUserName);
  String? get userRole => _prefs.getString(_keyUserRole);

  Future<void> saveUserSession({
    required String id,
    required String email,
    required String name,
    required String role,
  }) async {
    await _prefs.setString(_keyUserId, id);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserRole, role);
  }

  Future<void> clearUserSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserRole);
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _userDataKey = 'user_data';

  /// Save user data from login response
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userDataKey, value: jsonString);
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _userDataKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get current user ID
  static Future<String?> getCurrentUserId() async {
    final userData = await getUserData();
    return userData?['id'] as String?;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userData = await getUserData();
    return userData != null;
  }

  /// Clear all auth data (logout)
  static Future<void> clearUserData() async {
    await _storage.delete(key: _userDataKey);
  }
}

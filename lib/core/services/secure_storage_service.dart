import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'facil_count_secure',
    ),
  );

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'user_role';
  // ❌ SUPPRIMÉ : business_id ne doit pas être stocké séparément
  // Il fait partie du UserModel et doit être lu depuis authProvider uniquement

  static Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> setUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> setRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // ❌ SUPPRIMÉES : setBusinessId et getBusinessId
  // Le business_id doit toujours être lu depuis authProvider.currentUser.businessId
  // Stocker séparément cause des bugs de cache entre utilisateurs

  static Future<void> clearAll() async {
    await _storage.deleteAll();
    print('🧹 SecureStorage - Tout supprimé');
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token yang aman (Keychain/Keystore).
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static Future<String?> readToken() => _safeRead(_tokenKey);

  static Future<String?> readUser() => _safeRead(_userKey);

  static Future<void> saveSession(String token, String userJson) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {
      // Penyimpanan rusak: tidak ada yang bisa dihapus, abaikan.
    }
  }

  /// Baca nilai; jika penyimpanan rusak/tidak terbaca, anggap belum login.
  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await clear();
      return null;
    }
  }
}

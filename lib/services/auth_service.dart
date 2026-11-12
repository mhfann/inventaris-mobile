import 'dart:convert';

import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Login dan simpan token + profil user ke secure storage.
  Future<User> login({required String email, required String password}) async {
    final response = await _api.request(
      '/login',
      method: 'POST',
      data: {'email': email.trim(), 'password': password},
    );

    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    final token = dataMap['token']?.toString() ?? '';
    final userMap = dataMap['user'];
    if (token.isEmpty || userMap is! Map<String, dynamic> || userMap.isEmpty) {
      throw Exception('Respons login tidak valid. Silakan coba lagi.');
    }

    final user = User.fromJson(userMap);

    await TokenStorage.saveSession(token, jsonEncode(user.toJson()));
    return user;
  }

  /// Keluar. Sesi lokal selalu dihapus; kegagalan menghubungi server diabaikan
  /// (mis. offline atau token sudah kedaluwarsa), karena hasilnya sama.
  Future<void> logout() async {
    try {
      await _api.request('/logout', method: 'POST');
    } catch (_) {
      // Diabaikan: sesi lokal tetap dibersihkan di bawah.
    } finally {
      await TokenStorage.clear();
    }
  }

  /// Ubah password akun yang sedang login.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.request(
      '/password',
      method: 'PUT',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }

  Future<User?> restoreSession() async {
    final userJson = await TokenStorage.readUser();
    final token = await TokenStorage.readToken();
    if (userJson == null || token == null || token.isEmpty) return null;

    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return user;
    } catch (_) {
      await TokenStorage.clear();
      return null;
    }
  }
}

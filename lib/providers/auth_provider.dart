import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, this.onSessionExpired})
    : _authService = authService ?? AuthService() {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
  }

  final AuthService _authService;

  /// Dipanggil saat sesi dianggap tidak valid (401) supaya kembali ke login.
  final VoidCallback? onSessionExpired;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<bool> restoreSession() async {
    final user = await _authService.restoreSession();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authService.login(email: email, password: password);
      _user = user;
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Tandai keluar lebih dulu supaya 401 dari /logout tidak memicu
    // onSessionExpired (navigasi ke login ditangani pemanggil).
    _status = AuthStatus.unauthenticated;
    try {
      await _authService.logout();
    } catch (_) {
      // Abaikan error dari server; sesi lokal tetap dibersihkan.
    }
    _user = null;
    notifyListeners();
  }

  /// Dipanggil otomatis oleh [ApiClient] saat API mengembalikan 401.
  void _handleUnauthorized() {
    if (_status != AuthStatus.authenticated) return;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    onSessionExpired?.call();
  }

  bool can(String permission) => _user?.can(permission) ?? false;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

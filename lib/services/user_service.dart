import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/user.dart';

class UserListData {
  const UserListData({
    required this.users,
    required this.roles,
    this.total = 0,
    this.online = 0,
  });

  final List<User> users;
  final List<RoleOption> roles;
  final int total;
  final int online;
}

class UserService {
  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Ambil daftar user + role tersedia + statistik.
  Future<UserListData> all() async {
    final Response<dynamic> response = await _api.request('/users');
    final body = _body(response);
    final stats = body['stats'] is Map
        ? Map<String, dynamic>.from(body['stats'] as Map)
        : const <String, dynamic>{};

    final users = _list(body['data']).map((e) => User.fromJson(e)).toList();
    final roles = _list(
      body['roles'],
    ).map((e) => RoleOption.fromJson(e)).toList();

    return UserListData(
      users: users,
      roles: roles,
      total: _toInt(stats['total']) ?? users.length,
      online: _toInt(stats['online']) ?? 0,
    );
  }

  Future<User> create(Map<String, dynamic> payload) async {
    final Response<dynamic> response = await _api.request(
      '/users',
      method: 'POST',
      data: payload,
    );
    return User.fromJson(_single(response));
  }

  Future<User> update(int id, Map<String, dynamic> payload) async {
    final Response<dynamic> response = await _api.request(
      '/users/$id',
      method: 'PUT',
      data: payload,
    );
    return User.fromJson(_single(response));
  }

  Future<void> delete(int id) async {
    await _api.request('/users/$id', method: 'DELETE');
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    final body = response.data;
    return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _single(Response<dynamic> response) {
    final body = _body(response);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    // Respons tanpa pembungkus "data": objek user langsung di level atas.
    if (body.containsKey('id')) return body;
    throw const FormatException('Respons server tidak berisi data user.');
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

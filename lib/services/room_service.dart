import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/room.dart';

class RoomService {
  RoomService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Room>> all() async {
    final Response<dynamic> response = await _api.request('/rooms');
    final body = response.data;
    final dynamic data = body is Map ? body['data'] : body;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Room.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Room> create(Map<String, dynamic> payload) async {
    final Response<dynamic> response = await _api.request(
      '/rooms',
      method: 'POST',
      data: payload,
    );
    return _fromResponse(response);
  }

  Future<Room> update(int id, Map<String, dynamic> payload) async {
    final Response<dynamic> response = await _api.request(
      '/rooms/$id',
      method: 'PUT',
      data: payload,
    );
    return _fromResponse(response);
  }

  Future<void> delete(int id) async {
    await _api.request('/rooms/$id', method: 'DELETE');
  }

  Room _fromResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is Map) {
      final data = body['data'];
      if (data is Map) {
        return Room.fromJson(Map<String, dynamic>.from(data));
      }
      // Respons tanpa pembungkus "data": objek ruangan langsung di level atas.
      if (body.containsKey('id')) {
        return Room.fromJson(Map<String, dynamic>.from(body));
      }
    }
    throw const FormatException('Respons server tidak berisi data ruangan.');
  }
}

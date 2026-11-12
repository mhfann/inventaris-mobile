import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/category.dart';

class CategoryService {
  CategoryService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Category>> all() async {
    final response = await _api.request('/categories');
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  Future<Category> create(Map<String, dynamic> payload) async {
    final response = await _api.request(
      '/categories',
      method: 'POST',
      data: payload,
    );
    return _fromResponse(response);
  }

  Future<Category> update(int id, Map<String, dynamic> payload) async {
    final response = await _api.request(
      '/categories/$id',
      method: 'PUT',
      data: payload,
    );
    return _fromResponse(response);
  }

  Future<void> delete(int id) async {
    await _api.request('/categories/$id', method: 'DELETE');
  }

  Category _fromResponse(Response<dynamic> response) {
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is Map<String, dynamic>) return Category.fromJson(data);
    throw Exception('Respons server tidak valid.');
  }
}

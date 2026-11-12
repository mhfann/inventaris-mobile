import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<DashboardData> fetch() async {
    final Response<dynamic> response = await _api.request('/dashboard');
    final body = response.data;
    if (body is Map) {
      final data = body['data'];
      if (data is Map) {
        return DashboardData.fromJson(Map<String, dynamic>.from(data));
      }
      // Respons tanpa pembungkus "data": pakai objek level atas.
      if (!body.containsKey('data')) {
        return DashboardData.fromJson(Map<String, dynamic>.from(body));
      }
    }
    return DashboardData.fromJson(<String, dynamic>{});
  }
}

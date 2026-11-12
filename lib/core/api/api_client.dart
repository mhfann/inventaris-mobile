import 'package:dio/dio.dart';

import 'api_exception.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

/// Klien Dio dengan interceptor Bearer token dan parsing error terpusat.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await TokenStorage.readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Gagal membaca token: lanjutkan tanpa Authorization.
            // Server akan membalas 401 dan user diarahkan ke login.
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// Dipanggil saat API mengembalikan 401 (token tidak valid/kedaluwarsa).
  /// Dipakai untuk logout otomatis dan kembali ke halaman login.
  void Function()? onUnauthorized;

  /// Dipanggil saat API mengembalikan 503 (mode pemeliharaan server aktif).
  /// Dipakai untuk menampilkan layar "Sistem Sedang Maintenance".
  void Function()? onMaintenance;

  Dio get dio => _dio;

  /// Eksekusi request dan konversi error Dio menjadi [ApiException].
  Future<Response<dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  ApiException _parseError(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (statusCode == 401) {
      // Token tidak valid/kedaluwarsa: bersihkan sesi & minta login ulang.
      TokenStorage.clear();
      onUnauthorized?.call();
    }

    if (statusCode == 503) {
      // Server dalam mode pemeliharaan: tampilkan layar maintenance.
      onMaintenance?.call();
    }

    if (statusCode != null && statusCode >= 500 && statusCode != 503) {
      // Jangan tampilkan pesan mentah dari server (mis. "Server Error").
      return ApiException(
        'Server sedang bermasalah. Coba lagi nanti.',
        statusCode: statusCode,
      );
    }

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ?? 'Terjadi kesalahan.';
      final errors = <String, List<String>>{};
      final rawErrors = data['errors'];
      if (rawErrors is Map<String, dynamic>) {
        rawErrors.forEach((key, value) {
          errors[key] = value is List
              ? value.map((e) => e.toString()).toList()
              : [value.toString()];
        });
      }
      return ApiException(message, statusCode: statusCode, errors: errors);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Koneksi ke server timeout. Coba lagi nanti.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Tidak dapat terhubung ke server. Pastikan server aktif.',
      );
    }

    return ApiException(
      'Terjadi kesalahan (${statusCode ?? 'tidak diketahui'}).',
      statusCode: statusCode,
    );
  }
}

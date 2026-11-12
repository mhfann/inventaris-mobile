/// Konfigurasi aplikasi yang disinkronkan dari server.
class AppConfig {
  AppConfig._();

  /// Ambang stok menipis (dari pengaturan server `low_stock_threshold`).
  /// Diperbarui saat aplikasi mengambil `/status`.
  static int lowStockThreshold = 5;

  /// Terapkan isi respons `/status` ke konfigurasi.
  /// Menerima angka maupun string angka; nilai tidak valid diabaikan.
  static void applyStatus(Object? body) {
    if (body is! Map<String, dynamic>) return;
    final payload = body['data'];
    if (payload is! Map<String, dynamic>) return;
    final raw = payload['low_stock_threshold'];
    final value = raw is int ? raw : int.tryParse('$raw');
    if (value != null && value >= 0) lowStockThreshold = value;
  }
}

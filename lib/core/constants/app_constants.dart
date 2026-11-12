class AppConstants {
  AppConstants._();

  static const String appName = 'Inventaris Sekolah';

  /// Base URL API backend Laravel (server produksi).
  ///
  /// Untuk development lokal, jalankan dengan
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://inventaris.mhfann.my.id/api',
  );

  static const int perPage = 15;
}
/// Pengecualian API dengan pesan yang bisa langsung ditampilkan ke user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  /// Semua pesan validasi per kolom, digabung per baris.
  /// Kosong jika server tidak mengirim rincian `errors`.
  String get validationMessage =>
      (errors ?? const {}).values.expand((list) => list).join('\n');

  @override
  String toString() =>
      validationMessage.isNotEmpty ? validationMessage : message;
}

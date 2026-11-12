import '../core/api/api_client.dart';
import '../models/report.dart';

class ReportService {
  ReportService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Ambil data laporan dari `/api/report`.
  Future<ReportData> fetch({
    String type = 'inventory',
    String period = 'daily',
    DateTime? date,
    DateTime? month,
    int? year,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{'type': type, 'period': period};

    switch (period) {
      case 'monthly':
        params['month'] = _monthKey(month ?? DateTime.now());
      case 'yearly':
        params['year'] = year ?? DateTime.now().year;
      case 'range':
        var start = from ?? DateTime.now();
        var end = to ?? DateTime.now();
        if (start.isAfter(end)) {
          final tmp = start;
          start = end;
          end = tmp;
        }
        params['from'] = _dateKey(start);
        params['to'] = _dateKey(end);
      default:
        params['date'] = _dateKey(date ?? DateTime.now());
    }

    final response = await _api.request('/report', queryParameters: params);
    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ReportData.fromJson(data);
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';
}

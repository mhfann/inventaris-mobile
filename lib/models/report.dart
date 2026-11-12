/// Baca angka dari JSON: menerima int, double, maupun string angka.
/// Nilai kosong/tidak valid menjadi 0.
int _toInt(Object? value) =>
    value is num ? value.toInt() : (int.tryParse('$value') ?? 0);

class ReportRow {
  const ReportRow({
    required this.id,
    required this.name,
    this.code,
    this.category,
    this.room,
    this.condition,
    this.stock = 0,
    this.unit,
    this.transactionNumber,
    this.date,
    this.quantity = 0,
    this.destination,
    this.creator,
  });

  final int id;
  final String name;
  final String? code;
  final String? category;
  final String? room;
  final String? condition;
  final int stock;
  final String? unit;
  final String? transactionNumber;
  final String? date;
  final int quantity;
  final String? destination;
  final String? creator;

  factory ReportRow.fromJson(Map<String, dynamic> json) {
    final item = json['item'] is Map<String, dynamic>
        ? json['item'] as Map<String, dynamic>
        : null;

    return ReportRow(
      id: json['id'] as int,
      name: item?['name'] as String? ?? json['name'] as String? ?? '',
      code: json['code'] as String?,
      category: json['category'] is Map<String, dynamic>
          ? (json['category'] as Map<String, dynamic>)['name'] as String?
          : null,
      room: json['room'] is Map<String, dynamic>
          ? (json['room'] as Map<String, dynamic>)['name'] as String?
          : null,
      condition: json['condition'] as String?,
      stock: _toInt(json['stock']),
      unit: json['unit'] as String?,
      transactionNumber: json['transaction_number'] as String?,
      date: json['date'] as String?,
      quantity: _toInt(json['quantity']),
      destination: json['destination'] as String?,
      creator: json['created_by'] as String?,
    );
  }
}

class ReportData {
  const ReportData({
    required this.type,
    required this.period,
    required this.periodLabel,
    required this.rangeFrom,
    required this.rangeTo,
    this.totals = const {},
    this.rows = const [],
  });

  final String type;
  final String period;
  final String periodLabel;
  final String rangeFrom;
  final String rangeTo;
  final Map<String, int> totals;
  final List<ReportRow> rows;

  bool get isInventory => type == 'inventory';

  factory ReportData.fromJson(Map<String, dynamic> json) {
    final range = json['range'] is Map<String, dynamic>
        ? json['range'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final totalsRaw = json['totals'] is Map<String, dynamic>
        ? json['totals'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ReportData(
      type: json['type'] as String? ?? 'inventory',
      period: json['period'] as String? ?? 'daily',
      periodLabel: json['period_label'] as String? ?? '',
      rangeFrom: range['from'] as String? ?? '',
      rangeTo: range['to'] as String? ?? '',
      totals: totalsRaw.map((key, value) => MapEntry(key, _toInt(value))),
      rows: (json['rows'] as List? ?? [])
          .map((e) => ReportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
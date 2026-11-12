import 'item.dart';

/// Baca angka dari JSON: menerima int, double, maupun string angka.
int _toInt(Object? value) =>
    value is num ? value.toInt() : (int.tryParse('$value') ?? 0);

List<int> _toIntList(Object? value) =>
    value is List ? value.map(_toInt).toList() : const [];

class DashboardStats {
  const DashboardStats({
    this.totalItems = 0,
    this.totalCategories = 0,
    this.totalRooms = 0,
    this.totalIncoming = 0,
    this.totalOutgoing = 0,
    this.lowStock = 0,
  });

  final int totalItems;
  final int totalCategories;
  final int totalRooms;
  final int totalIncoming;
  final int totalOutgoing;
  final int lowStock;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalItems: _toInt(json['total_items']),
    totalCategories: _toInt(json['total_categories']),
    totalRooms: _toInt(json['total_rooms']),
    totalIncoming: _toInt(json['total_incoming']),
    totalOutgoing: _toInt(json['total_outgoing']),
    lowStock: _toInt(json['low_stock']),
  );
}

class DashboardMonthly {
  const DashboardMonthly({
    this.labels = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  final List<String> labels;
  final List<int> incoming;
  final List<int> outgoing;

  factory DashboardMonthly.fromJson(Map<String, dynamic> json) =>
      DashboardMonthly(
        labels:
            (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
        incoming: _toIntList(json['incoming']),
        outgoing: _toIntList(json['outgoing']),
      );
}

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.monthly,
    this.lowStockItems = const [],
  });

  final DashboardStats stats;
  final DashboardMonthly monthly;
  final List<Item> lowStockItems;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    stats: DashboardStats.fromJson(
      json['stats'] is Map<String, dynamic>
          ? json['stats'] as Map<String, dynamic>
          : const {},
    ),
    monthly: DashboardMonthly.fromJson(
      json['monthly'] is Map<String, dynamic>
          ? json['monthly'] as Map<String, dynamic>
          : const {},
    ),
    lowStockItems:
        (json['low_stock_items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Item.fromJson)
            .toList() ??
        [],
  );
}

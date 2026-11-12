import '../core/api/api_client.dart';
import '../models/item.dart';

class ItemService {
  ItemService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  static int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  /// Ambil objek `data` dari respons, atau lempar error yang jelas.
  static Map<String, dynamic> _unwrap(dynamic body) {
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respons server tidak valid.');
  }

  /// Ambil daftar item dengan pagination. Mengembalikan (items, hasMore).
  Future<(List<Item>, bool)> all({
    String? search,
    int? categoryId,
    int? roomId,
    bool? lowStock,
    int page = 1,
    int perPage = 15,
  }) async {
    final keyword = search?.trim() ?? '';
    final response = await _api.request(
      '/items',
      queryParameters: {
        if (keyword.isNotEmpty) 'search': keyword,
        'category_id': ?categoryId,
        'room_id': ?roomId,
        if (lowStock == true) 'low_stock': true,
        'page': page,
        'per_page': perPage,
      },
    );

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};

    final raw = body['data'];
    final items = (raw is List ? raw : const [])
        .whereType<Map<String, dynamic>>()
        .map(Item.fromJson)
        .toList();

    // Info halaman bisa ada di `meta` (resource collection) atau di level atas.
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : body;
    final currentPage = _toInt(meta['current_page']);
    final lastPage = _toInt(meta['last_page']);

    final bool hasMore;
    if (currentPage != null && lastPage != null) {
      hasMore = currentPage < lastPage;
    } else {
      // Tidak ada info halaman: anggap masih ada jika halaman ini penuh.
      hasMore = items.length >= perPage;
    }

    return (items, hasMore);
  }

  Future<Item> show(int id) async {
    final response = await _api.request('/items/$id');
    return Item.fromJson(_unwrap(response.data));
  }

  Future<Item> create(Map<String, dynamic> payload) async {
    final response = await _api.request(
      '/items',
      method: 'POST',
      data: payload,
    );
    return Item.fromJson(_unwrap(response.data));
  }

  Future<Item> update(int id, Map<String, dynamic> payload) async {
    final response = await _api.request(
      '/items/$id',
      method: 'PUT',
      data: payload,
    );
    return Item.fromJson(_unwrap(response.data));
  }

  Future<void> delete(int id) => _api.request('/items/$id', method: 'DELETE');
}

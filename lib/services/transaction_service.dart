import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/incoming_item.dart';
import '../models/outgoing_item.dart';

class TransactionService {
  TransactionService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<(List<IncomingItem>, bool)> incoming({
    String? search,
    String? from,
    String? to,
    int? itemId,
    int page = 1,
    int perPage = 15,
  }) async {
    final Response<dynamic> response = await _api.request(
      '/incoming-items',
      queryParameters: _listParams(search, from, to, itemId, page, perPage),
    );
    final body = _body(response);
    final items = _list(body).map((e) => IncomingItem.fromJson(e)).toList();
    return (items, _hasMore(body, page, items.length, perPage));
  }

  Future<(List<OutgoingItem>, bool)> outgoing({
    String? search,
    String? from,
    String? to,
    int? itemId,
    int page = 1,
    int perPage = 15,
  }) async {
    final Response<dynamic> response = await _api.request(
      '/outgoing-items',
      queryParameters: _listParams(search, from, to, itemId, page, perPage),
    );
    final body = _body(response);
    final items = _list(body).map((e) => OutgoingItem.fromJson(e)).toList();
    return (items, _hasMore(body, page, items.length, perPage));
  }

  Future<IncomingItem> storeIncoming({
    required int itemId,
    required String date,
    required int quantity,
    String? description,
  }) async {
    final Response<dynamic> response = await _api.request(
      '/incoming-items',
      method: 'POST',
      data: {
        'item_id': itemId,
        'date': date,
        'quantity': quantity,
        'description': description,
      },
    );
    return IncomingItem.fromJson(_single(response));
  }

  Future<OutgoingItem> storeOutgoing({
    required int itemId,
    required String date,
    required int quantity,
    String? destination,
    String? description,
  }) async {
    final Response<dynamic> response = await _api.request(
      '/outgoing-items',
      method: 'POST',
      data: {
        'item_id': itemId,
        'date': date,
        'quantity': quantity,
        'destination': destination,
        'description': description,
      },
    );
    return OutgoingItem.fromJson(_single(response));
  }

  Map<String, dynamic> _listParams(
    String? search,
    String? from,
    String? to,
    int? itemId,
    int page,
    int perPage,
  ) {
    return <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      'item_id': ?itemId,
      'page': page,
      'per_page': perPage,
    };
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    final body = response.data;
    return body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _single(Response<dynamic> response) {
    final body = _body(response);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    // Respons tanpa pembungkus "data": objek transaksi langsung di level atas.
    if (body.containsKey('id')) return body;
    throw const FormatException('Respons server tidak berisi data transaksi.');
  }

  bool _hasMore(Map<String, dynamic> body, int page, int count, int perPage) {
    final meta = body['meta'] is Map
        ? Map<String, dynamic>.from(body['meta'] as Map)
        : body;
    final lastPage = _toInt(meta['last_page']);
    if (lastPage != null) {
      final currentPage = _toInt(meta['current_page']) ?? page;
      return currentPage < lastPage;
    }
    // Tidak ada info halaman: anggap masih ada bila halaman ini penuh.
    return count >= perPage;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

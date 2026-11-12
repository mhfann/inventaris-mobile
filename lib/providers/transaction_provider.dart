import 'package:flutter/foundation.dart';

import '../models/incoming_item.dart';
import '../models/outgoing_item.dart';
import '../models/transaction_filter.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({TransactionService? transactionService})
    : _transactionService = transactionService ?? TransactionService();

  final TransactionService _transactionService;

  // ── Barang masuk ───────────────────────────────────────────────────────
  List<IncomingItem> _incoming = [];
  TransactionFilter _incomingFilter = const TransactionFilter();
  bool _incomingLoading = false;
  String? _incomingError;
  bool _incomingHasMore = false;
  int _incomingPage = 1;
  int _incomingRequest = 0;

  // ── Barang keluar ──────────────────────────────────────────────────────
  List<OutgoingItem> _outgoing = [];
  TransactionFilter _outgoingFilter = const TransactionFilter();
  bool _outgoingLoading = false;
  String? _outgoingError;
  bool _outgoingHasMore = false;
  int _outgoingPage = 1;
  int _outgoingRequest = 0;

  List<IncomingItem> get incoming => _incoming;
  TransactionFilter get incomingFilter => _incomingFilter;
  bool get incomingLoading => _incomingLoading;
  String? get incomingError => _incomingError;
  bool get incomingHasMore => _incomingHasMore;

  List<OutgoingItem> get outgoing => _outgoing;
  TransactionFilter get outgoingFilter => _outgoingFilter;
  bool get outgoingLoading => _outgoingLoading;
  String? get outgoingError => _outgoingError;
  bool get outgoingHasMore => _outgoingHasMore;

  /// Gabungan kedua daftar. Dipertahankan agar layar yang masih memakai
  /// `loading`/`error` tetap berjalan; layar baru sebaiknya memakai getter
  /// per daftar di atas.
  bool get loading => _incomingLoading || _outgoingLoading;
  String? get error => _incomingError ?? _outgoingError;

  /// Muat barang masuk.
  ///
  /// `refresh: true` (bawaan) memuat ulang dari halaman pertama.
  /// `refresh: false` memuat halaman berikutnya dan menambahkannya ke daftar.
  Future<void> loadIncoming({bool refresh = true}) async {
    if (!refresh && (_incomingLoading || !_incomingHasMore)) return;
    final request = ++_incomingRequest;
    final page = refresh ? 1 : _incomingPage + 1;
    _incomingLoading = true;
    _incomingError = null;
    notifyListeners();
    try {
      final (items, hasMore) = await _transactionService.incoming(
        search: _incomingFilter.search,
        from: _incomingFilter.from,
        to: _incomingFilter.to,
        itemId: _incomingFilter.itemId,
        page: page,
      );
      // Ada permintaan yang lebih baru (mis. filter diganti): buang hasil ini.
      if (request != _incomingRequest) return;
      _incoming = refresh ? items : [..._incoming, ...items];
      _incomingHasMore = hasMore;
      _incomingPage = page;
    } catch (e) {
      if (request == _incomingRequest) {
        _incomingError = e.toString();
        // Gagal memuat halaman berikutnya: hentikan muat otomatis.
        if (!refresh) _incomingHasMore = false;
      }
    } finally {
      if (request == _incomingRequest) {
        _incomingLoading = false;
        notifyListeners();
      }
    }
  }

  /// Muat barang keluar. Arti `refresh` sama dengan [loadIncoming].
  Future<void> loadOutgoing({bool refresh = true}) async {
    if (!refresh && (_outgoingLoading || !_outgoingHasMore)) return;
    final request = ++_outgoingRequest;
    final page = refresh ? 1 : _outgoingPage + 1;
    _outgoingLoading = true;
    _outgoingError = null;
    notifyListeners();
    try {
      final (items, hasMore) = await _transactionService.outgoing(
        search: _outgoingFilter.search,
        from: _outgoingFilter.from,
        to: _outgoingFilter.to,
        itemId: _outgoingFilter.itemId,
        page: page,
      );
      if (request != _outgoingRequest) return;
      _outgoing = refresh ? items : [..._outgoing, ...items];
      _outgoingHasMore = hasMore;
      _outgoingPage = page;
    } catch (e) {
      if (request == _outgoingRequest) {
        _outgoingError = e.toString();
        if (!refresh) _outgoingHasMore = false;
      }
    } finally {
      if (request == _outgoingRequest) {
        _outgoingLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setIncomingFilter(TransactionFilter filter) async {
    _incomingFilter = filter;
    await loadIncoming();
  }

  Future<void> setOutgoingFilter(TransactionFilter filter) async {
    _outgoingFilter = filter;
    await loadOutgoing();
  }

  /// Simpan barang masuk lalu muat ulang daftarnya.
  /// Error penyimpanan diteruskan ke pemanggil (form menampilkannya sendiri)
  /// dan tidak dicatat sebagai error daftar.
  Future<void> storeIncoming({
    required int itemId,
    required String date,
    required int quantity,
    String? description,
  }) async {
    await _transactionService.storeIncoming(
      itemId: itemId,
      date: date,
      quantity: quantity,
      description: description,
    );
    await loadIncoming();
  }

  /// Simpan barang keluar lalu muat ulang daftarnya.
  Future<void> storeOutgoing({
    required int itemId,
    required String date,
    required int quantity,
    String? destination,
    String? description,
  }) async {
    await _transactionService.storeOutgoing(
      itemId: itemId,
      date: date,
      quantity: quantity,
      destination: destination,
      description: description,
    );
    await loadOutgoing();
  }

  void clearError() {
    _incomingError = null;
    _outgoingError = null;
    notifyListeners();
  }
}

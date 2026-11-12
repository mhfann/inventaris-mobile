import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/category.dart';
import '../models/dashboard.dart';
import '../models/item.dart';
import '../models/room.dart';
import '../services/category_service.dart';
import '../services/dashboard_service.dart';
import '../services/item_service.dart';
import '../services/room_service.dart';

class ItemProvider extends ChangeNotifier {
  ItemProvider({
    ItemService? itemService,
    CategoryService? categoryService,
    RoomService? roomService,
    DashboardService? dashboardService,
  }) : _itemService = itemService ?? ItemService(),
       _categoryService = categoryService ?? CategoryService(),
       _roomService = roomService ?? RoomService(),
       _dashboardService = dashboardService ?? DashboardService();

  final ItemService _itemService;
  final CategoryService _categoryService;
  final RoomService _roomService;
  final DashboardService _dashboardService;

  List<Item> _items = [];
  List<Category> _categories = [];
  List<Room> _rooms = [];
  DashboardData? _dashboard;
  bool _loading = false;
  bool _dashboardLoading = false;
  int _itemsRequest = 0;
  bool _hasMore = false;
  int _page = 1;
  String _search = '';
  bool _lowStockOnly = false;
  String? _error;
  bool _referencesLoading = false;
  String? _referencesError;

  List<Item> get items => _items;
  List<Category> get categories => _categories;
  List<Room> get rooms => _rooms;
  DashboardData? get dashboard => _dashboard;
  bool get loading => _loading;
  bool get dashboardLoading => _dashboardLoading;
  bool get hasMore => _hasMore;
  bool get lowStockOnly => _lowStockOnly;
  String? get error => _error;

  /// Status muat & error khusus kategori + ruangan (data referensi).
  bool get referencesLoading => _referencesLoading;
  String? get referencesError => _referencesError;

  Future<void> loadItems({bool refresh = false}) async {
    // Muat halaman berikutnya diabaikan bila masih memuat; refresh selalu jalan.
    if (_loading && !refresh) return;
    final request = ++_itemsRequest;
    _loading = true;
    _error = null;
    if (refresh) {
      _page = 1;
      _items = [];
    }
    notifyListeners();

    try {
      final (items, hasMore) = await _itemService.all(
        search: _search,
        lowStock: _lowStockOnly ? true : null,
        page: _page,
        perPage: 15,
      );
      // Ada permintaan yang lebih baru: buang hasil lama ini.
      if (request != _itemsRequest) return;
      _items = refresh ? items : [..._items, ...items];
      _hasMore = hasMore;
      _page++;
    } catch (e) {
      if (request == _itemsRequest) {
        _error = e.toString();
        // Gagal memuat halaman berikutnya: hentikan muat otomatis supaya
        // tidak mencoba ulang terus-menerus. Refresh akan memulai lagi.
        if (!refresh) _hasMore = false;
      }
    } finally {
      if (request == _itemsRequest) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Aktifkan/nonaktifkan filter stok menipis pada daftar barang.
  Future<void> setLowStockOnly(bool value) async {
    if (_lowStockOnly == value) return;
    _lowStockOnly = value;
    _search = '';
    _items = [];
    _page = 1;
    notifyListeners();
    await loadItems(refresh: true);
  }

  /// Muat kategori dan ruangan. Bila gagal, daftar terakhir tetap dipakai
  /// dan pesannya tersedia lewat [referencesError].
  Future<void> loadReferences() async {
    _referencesLoading = true;
    _referencesError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _categoryService.all(),
        _roomService.all(),
      ]);
      _categories = results[0] as List<Category>;
      _rooms = results[1] as List<Room>;
    } catch (e) {
      _referencesError = e.toString();
    } finally {
      _referencesLoading = false;
      notifyListeners();
    }
  }

  Future<List<Item>> fetchAllItems() async {
    final (items, _) = await _itemService.all(
      search: '',
      page: 1,
      perPage: 1000,
    );
    return items;
  }

  /// Muat data dashboard. Error diteruskan ke pemanggil (DashboardScreen
  /// menyimpan pesan error-nya sendiri), jadi `_error` daftar barang tidak
  /// ikut berubah.
  Future<DashboardData> loadDashboard() async {
    _dashboardLoading = true;
    notifyListeners();
    try {
      _dashboard = await _dashboardService.fetch();
      return _dashboard!;
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearch(String value) async {
    _search = value.trim();
    _items = [];
    _page = 1;
    notifyListeners();
    await loadItems(refresh: true);
  }

  Future<Item> createItem(Map<String, dynamic> payload) async {
    final item = await _itemService.create(payload);
    await loadItems(refresh: true);
    return item;
  }

  Future<Item> updateItem(int id, Map<String, dynamic> payload) async {
    final item = await _itemService.update(id, payload);
    await loadItems(refresh: true);
    return item;
  }

  Future<void> deleteItem(int id) async {
    await _itemService.delete(id);
    await loadItems(refresh: true);
  }

  Future<void> createCategory(Map<String, dynamic> payload) async {
    await _categoryService.create(payload);
    await loadReferences();
  }

  Future<void> updateCategory(int id, Map<String, dynamic> payload) async {
    await _categoryService.update(id, payload);
    await loadReferences();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryService.delete(id);
    await loadReferences();
  }

  Future<void> createRoom(Map<String, dynamic> payload) async {
    await _roomService.create(payload);
    await loadReferences();
  }

  Future<void> updateRoom(int id, Map<String, dynamic> payload) async {
    await _roomService.update(id, payload);
    await loadReferences();
  }

  Future<void> deleteRoom(int id) async {
    await _roomService.delete(id);
    await loadReferences();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

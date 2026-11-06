import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/dashboard/data/models/dashboard_api_model.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory_store_item.dart';

/// View model backing the Stock Overview screen.
///
/// Loads the KPIs from `GET /dashboard/all` and the product rows from
/// `GET /products` with paging, search and client-side status filtering.
class InventoryOverviewViewModel extends BaseViewModel {
  final ProductPageFetcher _fetcher;
  InventoryOverviewViewModel({ProductPageFetcher? fetcher})
      : _fetcher = fetcher ?? _defaultFetcher;

  static Future<ProductPageResult> _defaultFetcher(
    int page,
    int perPage,
    String? search,
    CancelToken token,
  ) async {
    final resp = await ApiClient.instance.get(
      '/inventory-stores',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      cancelToken: token,
    );
    final data = resp.data;
    final List<dynamic> items = data is Map
        ? (data['data'] ?? const [])
        : (data is List ? data : const []);
    final meta = data is Map ? (data['meta'] as Map?) : null;
    final lastPage = (meta?['last_page'] as num?)?.toInt() ??
        (items.length < perPage ? page : page + 1);
    final rows = <InventoryStoreItem>[];
    for (final raw in items) {
      if (raw is Map<String, dynamic>) {
        final item = InventoryStoreItem.fromJson(raw);
        rows.add(item);
      }
    }
    final total = (meta?['total'] as num?)?.toInt() ?? rows.length;
    return ProductPageResult(rows: rows, lastPage: lastPage, total: total);
  }

  // ---- state ----
  DashboardStatsEntity? _stats;
  DashboardStatsEntity? get stats => _stats;

  final List<InventoryStoreItem> _rows = [];
  List<InventoryStoreItem> get rows => List.unmodifiable(_rows);

  String _search = '';
  String get search => _search;

  /// 'all' | 'in' | 'low' | 'out'
  String _statusFilter = 'all';
  String get statusFilter => _statusFilter;

  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _page < _lastPage;
  int get total => _total;

  List<InventoryStoreItem> get filteredRows {
    switch (_statusFilter) {
      case 'in':
        return _rows.where((r) => r.status == 'In Stock').toList();
      case 'low':
        return _rows.where((r) => r.status == 'Low Stock').toList();
      case 'out':
        return _rows.where((r) => r.status == 'Out of Stock').toList();
      default:
        return List.unmodifiable(_rows);
    }
  }

  int get totalStockUnits => _stats?.stockUnits ?? 0;

  Timer? _searchDebounce;

  // ---- loading ----

  Future<void> load() async {
    await runAsync((token) async {
      final dashboardResult = await ApiClient.instance.get(
        '/dashboard/all',
        queryParameters: const {'days': 30},
        cancelToken: token,
      );
      final dashboardJson = dashboardResult.data;
      if (dashboardJson is Map<String, dynamic>) {
        _stats = DashboardApiModel.fromJson(dashboardJson).toEntity().stats;
      }
      _rows.clear();
      _page = 1;
      _lastPage = 1;
      await _loadPage(token, 1, _search, replace: true);
      return null;
    });
  }

  Future<void> _loadPage(
    CancelToken token,
    int page,
    String search, {
    bool replace = false,
  }) async {
    final result = await _fetcher(page, 20, search, token);
    if (replace) {
      _rows
        ..clear()
        ..addAll(result.rows);
      _total = result.total;
    } else {
      _rows.addAll(result.rows);
    }
    _page = page;
    _lastPage = result.lastPage;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || isLoading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      await _loadPage(cancelToken, _page + 1, _search);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _rows.clear();
      _page = 1;
      _lastPage = 1;
      runAsync((token) async {
        await _loadPage(token, 1, _search, replace: true);
        return null;
      });
    });
  }

  void setStatusFilter(String value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
    // When a non-"all" filter is active, keep paging until the filtered list
    // has a usable number of rows (or there are no more pages), so the user
    // does not see an almost-empty table.
    _fillFilteredIfNeeded();
  }

  Future<void> _fillFilteredIfNeeded() async {
    while (_statusFilter != 'all' &&
        filteredRows.length < 12 &&
        hasMore &&
        !_loadingMore &&
        !isLoading) {
      await loadMore();
    }
  }

  Future<void> refresh() async {
    _rows.clear();
    _page = 1;
    _lastPage = 1;
    await load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

typedef ProductPageFetcher = Future<ProductPageResult> Function(
  int page,
  int perPage,
  String? search,
  CancelToken token,
);

class ProductPageResult {
  final List<InventoryStoreItem> rows;
  final int lastPage;
  final int total;
  const ProductPageResult(
      {required this.rows, required this.lastPage, this.total = 0});
}
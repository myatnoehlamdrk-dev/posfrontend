import 'dart:async';

import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/data/models/product_api_model.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

/// One category chip in the quick-sale filter row.
class SaleCategoryChip {
  final String id;
  final String name;

  const SaleCategoryChip({required this.id, required this.name});
}

/// The product side of the quick-sale screen: the category filter, the search
/// box and the page-by-page product feed.
///
/// The cart itself is deliberately *not* here. It lives in `SaleViewModel`, the
/// same object the new-sale screen drives, so a line added on this screen and a
/// line added there are the same thing and go through the same submission path
/// (draft order, idempotency key, offline outbox). This class only decides
/// *which* products are on screen and in what order they arrive.
///
/// Two things shape the implementation:
///
///  * **the feed is keyed by category.** Picking a chip, or editing the search
///    box, starts a new feed rather than filtering the loaded one — the server
///    already knows how to filter, and the pages that arrive afterwards have to
///    belong to the same filter. [_revision] is bumped on every restart so a
///    response from the previous filter is dropped instead of appended to the
///    new one.
///  * **a restart does not blank the grid.** The old products stay up until the
///    replacement page lands, so switching category (or refreshing stock after
///    a sale) is a swap rather than a skeleton flash.
class QuickSaleViewModel extends BaseViewModel {
  QuickSaleViewModel({
    ProductRemoteDataSource? remoteDataSource,
    CategoryRemoteDataSource? categorySource,
  }) : _remote = remoteDataSource ?? ProductRemoteDataSource(),
       _categorySource = categorySource ?? CategoryRemoteDataSource();

  final ProductRemoteDataSource _remote;
  final CategoryRemoteDataSource _categorySource;

  /// Products per request. The grid is scroll-lazy: the next page is asked for
  /// when the list comes within [_prefetchDistance] of its end, so a page has
  /// to be big enough to fill a screenful and small enough to keep up with a
  /// fast flick.
  static const int pageSize = 20;

  /// How close to the end of the list the next page is requested.
  static const double prefetchDistance = 300;

  List<SaleCategoryChip> _categories = [];
  List<SaleCategoryChip> get categories => List.unmodifiable(_categories);

  SaleCategoryChip? _selected;
  SaleCategoryChip? get selected => _selected;

  /// True once a chip other than "All" has been picked. The screen uses it to
  /// decide whether the cart surface has been revealed.
  bool get hasSelection => _selected != null;

  final List<CatalogProductView> _products = [];
  /// The live list. Callers only ever read it, and the grid asks for it on
  /// every frame of a scroll — so no per-access copy.
  List<CatalogProductView> get products => _products;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get isLoadingMore => _loadingMore;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.trim().isNotEmpty;

  bool get isEmpty => _products.isEmpty && !isLoading && !hasError;

  /// Bumped on every restart of the feed. A response carrying an older
  /// revision belongs to a filter the user has already left and is dropped.
  int _revision = 0;

  Timer? _debounce;

  /// Categories and the first page of products, in parallel. A category
  /// failure is not fatal: the chips render from an empty list and "All" still
  /// works, so the screen stays usable instead of erroring over a filter row.
  ///
  /// Loading is switched on *before* either fetch, not at the start of the
  /// product one — otherwise the first frame — no products, not loading yet —
  /// reads as "No products in this category" and flashes the empty state over
  /// what is merely a fetch in flight.
  Future<void> load() async {
    setLoading(true);
    await Future.wait([_loadCategories(), reload()]);
  }

  Future<void> _loadCategories() async {
    try {
      // The plain categories list, not `/categories/with-products`: the chips
      // carry only an id and a name, and the with-products shape drags every
      // category's preview products through a join just to be discarded here.
      final models = await _categorySource.getCategories(
        cancelToken: cancelToken,
      );
      final chips = <SaleCategoryChip>[
        for (final c in models)
          if (c.id.isNotEmpty && c.name.isNotEmpty)
            SaleCategoryChip(id: c.id, name: c.name),
      ];
      // "Uncategorized" is a bucket for products nobody filed, not a category
      // a cashier browses by — same exclusion the catalog applies.
      chips.removeWhere((c) => c.name == 'Uncategorized');
      _categories = chips;
      notifyListeners();
    } catch (_) {
      // Non-fatal. See [load].
    }
  }

  /// Debounced so a typed query fires one request after the finger pauses
  /// rather than one per keystroke.
  void setSearchQuery(String value) {
    _searchQuery = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), reload);
  }

  /// Picks a chip (or `null` for "All") and restarts the feed under it.
  Future<void> selectCategory(SaleCategoryChip? category) async {
    if (_selected?.id == category?.id) return;
    _selected = category;
    notifyListeners();
    await reload();
  }

  /// Restart the feed from page one under the current category and query.
  Future<void> reload() async {
    final rev = ++_revision;
    _page = 1;
    _hasMore = false;
    _loadingMore = false;
    resetError();
    setLoading(true);
    try {
      await _fetch(rev: rev, replace: true);
    } finally {
      if (rev == _revision) setLoading(false);
    }
  }

  /// Pull-to-refresh, and the stock refresh after a sale completes.
  Future<void> refresh() => reload();

  /// The next page of the current feed. Ignored while one is already running,
  /// while the first page is still landing, or when the feed is exhausted —
  /// the scroll listener fires on every frame near the end.
  Future<void> loadMore() async {
    if (_loadingMore || isLoading || !_hasMore) return;
    final rev = _revision;
    _loadingMore = true;
    notifyListeners();
    try {
      await _fetch(rev: rev, replace: false);
    } finally {
      if (rev == _revision) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  int _page = 1;

  Future<void> _fetch({required int rev, required bool replace}) async {
    try {
      final response = await _remote.getProducts(
        categoryId: _selected?.id,
        search: _searchQuery.trim(),
        page: _page,
        perPage: pageSize,
        cancelToken: cancelToken,
      );
      if (rev != _revision) return;

      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => ProductApiModel.fromJson(json).toEntity(),
      );

      final newItems = paginated.data
          .map(
            (e) => CatalogProductView(
              id: e.id,
              name: e.name,
              brand: e.brand,
              sku: e.sku,
              price: e.price,
              stock: e.stock,
              isSet: e.isSet,
              category: e.category,
              packageId: e.packageId,
              icon: CatalogProductView.iconFor(e.category),
              color: CatalogProductView.colorFor(e.category),
              imageUrl: e.imageUrl,
              variants: e.variants
                  .map(
                    (v) => ProductVariant(
                      size: v.size,
                      color: v.color,
                      quantity: v.quantity,
                      price: v.price,
                    ),
                  )
                  .toList(),
              createdBy: e.createdBy,
            ),
          )
          .toList();

      // The old page stays on screen until here, which is what makes a
      // category switch a swap rather than a blank.
      if (replace) _products.clear();
      _products.addAll(newItems);
      _page++;
      _hasMore = _page <= paginated.lastPage;
      notifyListeners();
    } on ApiException catch (e) {
      if (rev == _revision) setError(e.message);
    } catch (e) {
      if (rev == _revision) setError(formatApiError(e));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

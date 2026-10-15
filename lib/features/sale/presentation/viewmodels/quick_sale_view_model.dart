import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/models/paginated_response.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/data/models/product_api_model.dart';
import 'package:posfrontend/features/product/domain/entities/product.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

/// One category chip in the quick-sale filter row.
class SaleCategoryChip {
  final String id;
  final String name;

  const SaleCategoryChip({required this.id, required this.name});
}

/// One fetched feed — a category (or search result) as it was last answered by
/// the server — kept so a chip can show it again without a round trip.
class _FeedSnapshot {
  _FeedSnapshot({
    required List<CatalogProductView> items,
    required this.nextPage,
    required this.hasMore,
  }) : items = List.of(items);

  /// Mutable on purpose: a silent revalidation refreshes the head of the list
  /// in place. Never handed out directly — [_QuickSaleViewModel] copies it
  /// into the visible list and back on every write.
  final List<CatalogProductView> items;
  int nextPage;
  bool hasMore;

  /// Refreshes the first page's worth of items, keeping whatever deeper pages
  /// are already held — a silent revalidation that must not shrink a feed the
  /// cashier has scrolled into.
  void replaceHead(List<CatalogProductView> page) {
    final head = items.length < page.length ? items.length : page.length;
    items.replaceRange(0, head, page);
  }
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
/// Three things shape the implementation:
///
///  * **the feed is keyed by category.** [_FeedSnapshot]s are cached per
///    `category|search` key ([feedKey]), so a chip the cashier has visited —
///    or that the background warm-up has already filled — swaps its products
///    onto the screen synchronously, with no loading flag and no spinner. Only
///    a key nothing is known about falls back to the skeleton path.
///  * **a cache hit still revalidates, silently.** Page one is refetched in
///    the background and swapped in place when it lands; the error is only
///    surfaced when there is nothing on screen to show instead. Stock stays
///    fresh without the tap ever *looking* like a network call.
///  * **a restart does not blank the grid.** The old products stay up until
///    the replacement page lands, so switching category (or refreshing stock
///    after a sale) is a swap rather than a skeleton flash.
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

  /// Distinct feeds kept in memory. Enough for every category a shop is
  /// likely to file plus recent searches; capped so a long session typing
  /// queries cannot grow the map without bound.
  static const int _maxCachedFeeds = 48;

  List<SaleCategoryChip> _categories = [];

  /// Precomputed once per categories fetch: this getter is read on every
  /// rebuild of the chip row, and a fresh `List.unmodifiable` per access is a
  /// per-frame allocation for nothing.
  List<SaleCategoryChip> _categoriesView = const [];
  List<SaleCategoryChip> get categories => _categoriesView;

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

  /// What is on screen right now, as one string. Both the cache key and the
  /// screen's feed identity (it resets the scroll when this changes).
  String get feedKey => '${_selected?.id ?? ''}|${_searchQuery.trim()}';

  /// The key of the feed actually *on screen*. [feedKey] moves with every
  /// keystroke; this one only moves when a restart takes over — the one
  /// moment the grid may remount and the scroll start over. Keying the grid
  /// by [feedKey] instead made the list jump to the top on every character
  /// typed, over the previous feed's still-visible cards.
  String _settledFeedKey = '';
  String get settledFeedKey => _settledFeedKey;

  /// True while a typed query is waiting out its debounce: the request has
  /// not fired yet, so an empty product list in this window is "still
  /// coming", not "no results".
  bool get isDebouncing => _debounce?.isActive ?? false;

  /// Bumped on every restart of the feed. A response carrying an older
  /// revision belongs to a filter the user has already left and is dropped.
  int _revision = 0;

  /// True while a silent revalidation is in flight: it owns [_revision] and
  /// page one, so a scroll-triggered [loadMore] must not race it with an
  /// append of the very pages it is about to replace.
  bool _revalidating = false;

  final Map<String, _FeedSnapshot> _cache = {};

  /// The token every product request of the current feed shares. A new one is
  /// minted (and the old cancelled) on each restart, so a cashier tapping
  /// across chips leaves one request in flight, not one per tap.
  CancelToken? _feedToken;

  /// Separate from [_feedToken] on purpose: the background warm-up outlives
  /// individual taps and is cancelled only by [dispose].
  CancelToken? _warmToken;

  Timer? _debounce;

  /// Categories and the first page of products, in parallel. A category
  /// failure is not fatal: the chips render from an empty list and "All" still
  /// works, so the screen stays usable instead of erroring over a filter row.
  ///
  /// Loading is switched on *before* either fetch, not at the start of the
  /// product one — otherwise the first frame — no products, not loading yet —
  /// reads as "No products in this category" and flashes the empty state over
  /// what is merely a fetch in flight.
  ///
  /// Once both land, every other category's first page is warmed in the
  /// background so even a chip's *first* tap is instant.
  Future<void> load() async {
    setLoading(true);
    await Future.wait([_loadCategories(), reload()]);
    unawaited(_warmFeeds());
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
      _categoriesView = List.unmodifiable(chips);
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
    _debounce = Timer(const Duration(milliseconds: 300), _restartFeed);
  }

  /// Picks a chip (or `null` for "All") and restarts the feed under it.
  Future<void> selectCategory(SaleCategoryChip? category) async {
    if (_selected?.id == category?.id) return;
    _selected = category;
    // A category nobody has visited clears the old category's cards on a
    // miss: a skeleton says "this one is loading" where a stale grid would
    // read as the tap not registering.
    await _restartFeed(clearOnMiss: true);
  }

  /// The common restart path for a chip tap and a settled search query: show
  /// what is already fetched the moment it exists, fetch otherwise.
  ///
  /// The cached branch is the whole point of the cache — one notify, no
  /// loading flag, no skeleton — followed by a revalidation the cashier never
  /// sees as a load.
  Future<void> _restartFeed({bool clearOnMiss = false}) async {
    _settledFeedKey = feedKey;
    final cached = _cache[feedKey];
    if (cached == null) {
      // A settled *search* clears the previous feed's cards before fetching:
      // over a slow link they would stay up — and tappable — for a second or
      // more, and a cashier adding "what was on screen" books the wrong item.
      // The skeleton says "your query is loading" instead.
      await reload(clear: clearOnMiss || isSearching);
      return;
    }
    _showSnapshot(cached);
    resetError();
    notifyListeners();
    unawaited(_revalidate());
  }

  /// Installs a snapshot as the visible feed. Synchronous: by the time this
  /// returns, the grid can build the new category's cards.
  void _showSnapshot(_FeedSnapshot snapshot) {
    _products
      ..clear()
      ..addAll(snapshot.items);
    _page = snapshot.nextPage;
    _hasMore = snapshot.hasMore;
    _loadingMore = false;
  }

  /// Restart the feed from page one under the current category and query.
  /// Always hits the server (pull-to-refresh, post-sale refresh, retry) and
  /// overwrites whatever the cache held. [clear] drops the visible products
  /// first — used by a category miss, where keeping the previous category's
  /// cards up would make the tap look ignored.
  Future<void> reload({bool clear = false}) async {
    _settledFeedKey = feedKey;
    final rev = ++_revision;
    _page = 1;
    _hasMore = false;
    _loadingMore = false;
    _revalidating = false;
    resetError();
    setLoading(true);
    if (clear) {
      _products.clear();
      // Belt and braces: [setLoading] may have been a no-op if a fetch was
      // already in flight, and this mutation still needs a rebuild.
      notifyListeners();
    }
    try {
      await _fetch(rev: rev, page: 1, replace: true, token: _mintFeedToken());
    } finally {
      if (rev == _revision) setLoading(false);
    }
  }

  /// Pull-to-refresh, and the stock refresh after a sale completes.
  Future<void> refresh() => reload();

  /// Refetch page one under the current key *without* the loading flag: the
  /// cached products stay on screen and are swapped in place when the answer
  /// lands. That is what makes a chip tap feel local while stock still keeps
  /// up with the server.
  ///
  /// When the visible list runs deeper than one page the cashier has already
  /// scrolled into cached territory, so only the head of the *cache* is
  /// refreshed — they are not yanked back to the top mid-browse.
  Future<void> _revalidate() async {
    final rev = ++_revision;
    final fitsPageOne = _products.length <= pageSize;
    _revalidating = true;
    try {
      await _fetch(
        rev: rev,
        page: 1,
        replace: fitsPageOne,
        silent: true,
        headOnly: !fitsPageOne,
        token: _mintFeedToken(),
      );
    } finally {
      if (rev == _revision) _revalidating = false;
    }
  }

  /// The next page of the current feed. Ignored while one is already running,
  /// while the first page is still landing, while a revalidation owns the
  /// feed, or when the feed is exhausted — the scroll listener fires on every
  /// frame near the end.
  Future<void> loadMore() async {
    if (_loadingMore || _revalidating || isLoading || !_hasMore) return;
    final rev = _revision;
    _loadingMore = true;
    notifyListeners();
    try {
      await _fetch(
        rev: rev,
        page: _page,
        replace: false,
        token: _feedToken ?? cancelToken,
      );
    } finally {
      if (rev == _revision) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  int _page = 1;

  Future<void> _fetch({
    required int rev,
    required int page,
    required bool replace,
    required CancelToken token,
    bool silent = false,
    bool headOnly = false,
  }) async {
    // Captured before the await: a keystroke changes [_searchQuery] right
    // away but only bumps [_revision] once the debounce settles, so a
    // response landing in that window still belongs to *this* key and must
    // be cached under it, never under whatever the box says now.
    //
    // Normalized to `''` like [feedKey]: interpolating a null id directly
    // yields the literal "null", which made the "All" view's cache key
    // ('null|') a different namespace from its feed key ('|') — the cache
    // never hit on a restart back to All, and the superseded-key guard
    // below would reject every response in the default view.
    final categoryId = _selected?.id ?? '';
    final search = _searchQuery.trim();
    final key = '$categoryId|$search';
    try {
      final response = await _remote.getProducts(
        categoryId: categoryId,
        search: search,
        page: page,
        perPage: pageSize,
        cancelToken: token,
      );
      if (rev != _revision) return;

      final paginated = PaginatedResponse.fromJson(
        response,
        (json) => ProductApiModel.fromJson(json).toEntity(),
      );
      final newItems = paginated.data.map(_toView).toList();
      final nextPage = page + 1;
      final hasMore = nextPage <= paginated.lastPage;

      // The text (or chip) moved on while this response was in flight: it
      // answers a query the cashier no longer has on screen. Hand it to the
      // cache for the key it actually answered — backspacing into a typed
      // prefix then finds it instantly — but never render it as the answer
      // to the current one.
      final currentKey = '${_selected?.id ?? ''}|${_searchQuery.trim()}';
      if (key != currentKey) {
        if (replace) {
          _putCache(
            key,
            _FeedSnapshot(
              items: newItems,
              nextPage: nextPage,
              hasMore: hasMore,
            ),
          );
        }
        return;
      }

      if (headOnly) {
        // The visible list keeps its extra cached pages; only the cache's
        // page-one slice is brought up to date for the next visit.
        _cache[key]?.replaceHead(newItems);
        return;
      }

      // The old page stays on screen until here, which is what makes a
      // category switch a swap rather than a blank.
      if (replace) _products.clear();
      _products.addAll(newItems);
      _page = nextPage;
      _hasMore = hasMore;
      _putVisibleInCache(key);
      notifyListeners();
    } on CancelledException {
      // Superseded by a newer restart, or the screen went away. Either way
      // the newer answer (or nothing at all) is what should show — never an
      // error for a request this class chose to abandon.
    } on ApiException catch (e) {
      if (_shouldSurfaceError(rev, silent)) setError(e.message);
    } catch (e) {
      if (_shouldSurfaceError(rev, silent)) setError(formatApiError(e));
    }
  }

  /// A failed fetch is worth saying out loud only when it is current *and*
  /// has nothing to show over: a silent revalidation that left the cashier's
  /// cached products on screen keeps its failure to itself.
  bool _shouldSurfaceError(int rev, bool silent) =>
      rev == _revision && !(silent && _products.isNotEmpty);

  CatalogProductView _toView(ProductEntity e) => CatalogProductView(
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
  );

  // ------------------------------------------------------------------ cache

  /// Copies the visible feed into its cache slot, creating or updating it.
  /// Called after every successful non-head fetch, so what a chip shows next
  /// time is exactly what the server last said. [key] is the key the fetch
  /// was *requested* with (see [_fetch]).
  void _putVisibleInCache(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _putCache(
        key,
        _FeedSnapshot(items: _products, nextPage: _page, hasMore: _hasMore),
      );
      return;
    }
    entry.items
      ..clear()
      ..addAll(_products);
    entry.nextPage = _page;
    entry.hasMore = _hasMore;
  }

  void _putCache(String key, _FeedSnapshot snapshot) {
    _cache[key] = snapshot;
    if (_cache.length <= _maxCachedFeeds) return;
    // Insertion-ordered: drop the coldest key that is not the one just
    // written, so the feed on screen is never evicted by its own write.
    final coldest = _cache.keys.firstWhere((k) => k != key, orElse: () => '');
    if (coldest.isNotEmpty) _cache.remove(coldest);
  }

  /// First page of every not-yet-cached category, fetched one at a time in
  /// the background: no loading flag, no screen involvement, and it stops
  /// dead when the screen is disposed ([_warmToken]). It is what makes the
  /// *first* tap on a chip instant too — by the time the cashier reaches for
  /// a category, its products are usually already here.
  Future<void> _warmFeeds() async {
    _warmToken ??= CancelToken();
    final token = _warmToken!;
    for (final category in List.of(_categories)) {
      final key = '${category.id}|';
      if (_cache.containsKey(key)) continue;
      try {
        final response = await _remote.getProducts(
          categoryId: category.id,
          page: 1,
          perPage: pageSize,
          cancelToken: token,
        );
        final paginated = PaginatedResponse.fromJson(
          response,
          (json) => ProductApiModel.fromJson(json).toEntity(),
        );
        // A tap on this chip while its warm-up was in flight may already have
        // cached it (or something fresher): never overwrite a visit.
        if (_cache.containsKey(key)) continue;
        _putCache(
          key,
          _FeedSnapshot(
            items: paginated.data.map(_toView).toList(),
            nextPage: 2,
            hasMore: 2 <= paginated.lastPage,
          ),
        );
      } on AppException {
        // Cancelled (screen closed) or the network gave up. Warming is a
        // best-effort head start — the miss path still fetches on tap.
        return;
      } catch (_) {
        return;
      }
    }
  }

  /// Mints the token the next restart's requests share, cancelling the
  /// requests of the feed being left behind.
  CancelToken _mintFeedToken() {
    final previous = _feedToken;
    if (previous != null && !previous.isCancelled) previous.cancel();
    return _feedToken = CancelToken();
  }

  @override
  void dispose() {
    // Bumped first: any fetch still in flight now fails its revision check
    // and stays silent, instead of notifying a disposed ChangeNotifier.
    _revision++;
    _debounce?.cancel();
    final warm = _warmToken;
    if (warm != null && !warm.isCancelled) warm.cancel();
    final feed = _feedToken;
    if (feed != null && !feed.isCancelled) feed.cancel();
    super.dispose();
  }
}

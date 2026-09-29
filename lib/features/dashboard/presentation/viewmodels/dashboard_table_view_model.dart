import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Drives one "View all" table: first page, pull-to-refresh, load-more, search,
/// and the most/least toggle.
///
/// [fixedQuery] is the part of the request that does not change, such as
/// `low=1` for the low-stock table. [direction] is a tab rather than a filter,
/// so switching it is a reload from page 1 instead of an append.
class DashboardTableViewModel extends BaseViewModel {
  static const int perPage = 15;

  final DashboardRepository _repository;
  final String endpoint;
  final Map<String, dynamic> fixedQuery;

  List<DashboardTableRow> _rows = [];
  List<DashboardTableRow> get rows => _rows;

  int _page = 1;
  int get page => _page;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  int _total = 0;
  int get total => _total;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// Distinguishes "never loaded" from "loaded and empty", which is the
  /// difference between a spinner and an empty-state message.
  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  String _search = '';
  String get search => _search;

  String? _direction;
  String? get direction => _direction;

  DashboardTableViewModel({
    required DashboardRepository repository,
    required this.endpoint,
    this.fixedQuery = const {},
    String? direction,
  })  : _repository = repository,
        _direction = direction;

  bool get hasMore => _page < _lastPage;

  /// Guards against a second request while one is in flight, which matters here
  /// because scroll-driven load-more fires far more often than pages turn over.
  bool get _isBusy => isLoading || _isLoadingMore;

  Future<void> load() async {
    _page = 1;
    await _fetch(replace: true);
  }

  Future<void> refresh() async {
    _page = 1;
    await _fetch(replace: true);
  }

  Future<void> loadMore() async {
    if (_isBusy || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await _fetch(replace: false);
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Debounced by the screen; the view model just re-runs the first page so that
  /// a search never leaves stale rows from the previous term on screen.
  Future<void> applySearch(String term) async {
    final trimmed = term.trim();
    if (trimmed == _search) return;
    _search = trimmed;
    _page = 1;
    await _fetch(replace: true);
  }

  Future<void> setDirection(String direction) async {
    if (direction == _direction) return;
    _direction = direction;
    _page = 1;
    await _fetch(replace: true);
  }

  Future<void> _fetch({required bool replace}) async {
    if (replace) {
      setLoading(true);
    }
    resetError();

    final targetPage = replace ? 1 : _page + 1;

    final result = await runAsync(
      (token) => _repository.getTable(
        endpoint: endpoint,
        page: targetPage,
        perPage: perPage,
        query: {
          ...fixedQuery,
          if (_search.isNotEmpty) 'search': _search,
          if (_direction != null) 'direction': _direction,
        },
      ),
      // Loading state is managed here so that load-more and first-load do not
      // fight over the same flag.
      showLoading: false,
    );

    if (result != null) {
      _rows = replace ? result.rows : [..._rows, ...result.rows];
      _page = result.page;
      _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      _total = result.total;
    }

    _hasLoaded = true;
    if (replace) setLoading(false);
    notifyListeners();
  }
}

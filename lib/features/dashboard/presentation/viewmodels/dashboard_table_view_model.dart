import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Drives one "View all" table: first page, pull-to-refresh, infinite scroll,
/// and the most/least toggle.
///
/// [fixedQuery] is the part of the request that does not change, such as
/// `low=1` for the low-stock table. [direction] is a tab rather than a filter,
/// so switching it is a reload from page 1 instead of an append. [month] (the
/// sales table only) works the same way.
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

  String? _direction;
  String? get direction => _direction;

  /// `YYYY-MM` (sales table only), or null for all time. Defaults to the current
  /// month when one is passed in, which is what the sales table wants.
  String? _month;
  String? get month => _month;

  DashboardTableViewModel({
    required DashboardRepository repository,
    required this.endpoint,
    this.fixedQuery = const {},
    String? direction,
    String? month,
  }) : _repository = repository,
       _direction = direction,
       _month = month;

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

  Future<void> setDirection(String direction) async {
    if (direction == _direction) return;
    _direction = direction;
    _page = 1;
    await _fetch(replace: true);
  }

  Future<void> setMonth(String? month) async {
    if (month == _month) return;
    _month = month;
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
          if (_direction != null) 'direction': _direction,
          if (_month != null) 'month': _month,
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

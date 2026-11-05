import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final DashboardRepository _repository;

  DashboardViewModel({required DashboardRepository repository})
    : _repository = repository;

  DashboardEntity? _data;
  DashboardEntity? get data => _data;

  List<int> _years = [];
  List<int> get years => _years;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  List<MonthlySalesEntity> _monthlySales = [];
  List<MonthlySalesEntity> get monthlySales => _monthlySales;

  bool _isLoadingMonthly = false;
  bool get isLoadingMonthly => _isLoadingMonthly;

  String? _monthlyError;
  String? get monthlyError => _monthlyError;

  /// The look-back window of `/dashboard/all`, in days. Fixed now that the
  /// header's period picker is gone: the backend folds it into
  /// `category_quantity`, so it scopes the quantity chart and the Items Sold
  /// tile, while the all-time figures stay all-time.
  static const int _windowDays = 30;

  Map<String, TablePage> _tablePreviews = const {};

  /// First page of rows behind each inline preview table, keyed by
  /// [DashboardTablePreviews.requests].
  Map<String, TablePage> get tablePreviews => _tablePreviews;

  bool _previewsLoaded = false;
  bool get previewsLoaded => _previewsLoaded;

  SummaryTrendsEntity? _trends;

  /// The arrows beside the Sales Summary figures, or null when the two
  /// windows could not be compared and the card should show plain numbers.
  SummaryTrendsEntity? get trends => _trends;

  /// One daily series per KPI tile, keyed by the tile's [MetricTrendKey] —
  /// the raw shape the tile's mini line is drawn from.
  ///
  /// Revenue comes from the real daily chart. The other three have no daily
  /// history in the API at all, so they carry a generated walk that ends
  /// where its arrow points: a line that contradicted the sign above it
  /// would be worse than no line.
  Map<MetricTrendKey, List<double>> _sparklines = const {};
  Map<MetricTrendKey, List<double>> get sparklines => _sparklines;

  /// Whether [trends] has finished loading.
  ///
  /// "Not fetched yet" and "fetched and failed" both read as null in the
  /// data, so the screen needs this to tell them apart: the tile reserves its
  /// badge row until this is true, and the grid does not jump when the
  /// arrows land.
  bool _trendsLoaded = false;
  bool get trendsLoaded => _trendsLoaded;

  Future<void> load() async {
    final result = await runAsync(
      (token) => _repository.getDashboardData(days: _windowDays),
      errorPrefix: 'Failed to load dashboard',
    );
    if (result != null) _data = result;
    await Future.wait([
      loadMonthlySales(year: _selectedYear),
      _loadTablePreviews(),
      _loadTrends(),
    ]);
  }

  Future<void> loadMonthlySales({required int year}) async {
    _selectedYear = year;
    _isLoadingMonthly = true;
    _monthlyError = null;
    notifyListeners();
    try {
      final result = await _repository.getMonthlySales(year: year);
      if (result.years.isNotEmpty) _years = result.years;
      _monthlySales = result.months;
    } catch (e) {
      _monthlyError = formatApiError(e);
    }
    _isLoadingMonthly = false;
    notifyListeners();
  }

  /// The four inline tables, fetched in one pass.
  ///
  /// Deliberately not through [runAsync]: that sets the screen's global
  /// loading flag, and a preview arriving late would blank a dashboard that
  /// is already showing real numbers. Each request fails independently, so a
  /// single unavailable table leaves the other three filled and this one with
  /// an empty page to render as "Nothing to show".
  Future<void> _loadTablePreviews() async {
    final entries = await Future.wait(
      DashboardTablePreviews.requests.map((request) async {
        try {
          final page = await _repository.getTable(
            endpoint: request.endpoint,
            page: 1,
            perPage: DashboardTablePreviews.rowsPerPage,
            query: request.query,
          );
          return MapEntry(request.key, page);
        } catch (_) {
          return MapEntry(request.key, TablePage.empty);
        }
      }),
    );

    _tablePreviews = Map.fromEntries(entries);
    _previewsLoaded = true;
    notifyListeners();
  }

  /// The changes shown beside the Sales Summary figures.
  ///
  /// The API reports no period-over-period change anywhere, so both windows
  /// are fetched here and differenced:
  ///
  ///   * `/dashboard/sales-chart?days=60` split at the 30-day mark gives
  ///     revenue and order counts for the current window and the one before
  ///     it — and from those two, the average order value.
  ///   * `/dashboard/all?days=60` gives units across both windows; the
  ///     dashboard's own 30-day figure is the current half, so subtracting it
  ///     leaves the previous window's units.
  ///
  /// A failure leaves [trends] null rather than raising the screen's error
  /// state: the summary's numbers are the point, and a missing arrow is a
  /// smaller loss than a retry prompt over a dashboard that is otherwise
  /// healthy.
  Future<void> _loadTrends() async {
    final dashboard = _data;
    if (dashboard == null) {
      _trends = null;
      _sparklines = const {};
      _trendsLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final chartFuture = _repository.getSalesChart(days: _windowDays * 2);
      final unitsFuture = _repository.getItemsSold(days: _windowDays * 2);
      await Future.wait([chartFuture, unitsFuture]);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentFrom = today.subtract(const Duration(days: _windowDays));
      final previousFrom = today.subtract(
        Duration(days: _windowDays * 2),
      );

      var revenueCurrent = 0.0;
      var revenuePrevious = 0.0;
      var ordersCurrent = 0;
      var ordersPrevious = 0;

      final chartPoints = await chartFuture;

      // The tile's line: one point per day of the current window, missing
      // days left at zero so the shape is the shape of the calendar rather
      // than of the days that happened to record a sale.
      final revenueSeries = List<double>.filled(_windowDays, 0);
      for (final point in chartPoints) {
        if (point.date.isBefore(previousFrom)) continue;
        if (point.date.isBefore(currentFrom)) {
          revenuePrevious += point.total;
          ordersPrevious += point.orders;
        } else {
          revenueCurrent += point.total;
          ordersCurrent += point.orders;
          final day = point.date.difference(currentFrom).inDays;
          if (day >= 0 && day < _windowDays) {
            revenueSeries[day] = point.total.toDouble();
          }
        }
      }

      // The 60-day window contains the 30-day one, so the difference is
      // exactly the previous window's units — no drift to guard against.
      final unitsCurrent = dashboard.stats.itemsSold;
      final unitsOverBothWindows = await unitsFuture;
      final unitsPrevious =
          unitsOverBothWindows - unitsCurrent > 0
          ? unitsOverBothWindows - unitsCurrent
          : 0;

      double averageOrder(double revenue, int orders) =>
          orders <= 0 ? 0 : revenue / orders;

      final revenueTrend = TrendEntity.compare(
        current: revenueCurrent,
        previous: revenuePrevious,
      );
      final itemsTrend = TrendEntity.compare(
        current: unitsCurrent.toDouble(),
        previous: unitsPrevious.toDouble(),
      );

      // Demo figures for the two tiles whose history the API does not keep:
      // the product count only exists as "now", so there is nothing to
      // difference. Fixed numbers rather than a fetch that could not succeed.
      const productsTrend = TrendEntity(
        direction: TrendDirection.up,
        percent: 12,
      );
      const lowStockTrend = TrendEntity(
        direction: TrendDirection.up,
        percent: 40,
        inverted: true,
      );

      _trends = SummaryTrendsEntity(
        revenue: revenueTrend,
        orders: TrendEntity.compare(
          current: ordersCurrent.toDouble(),
          previous: ordersPrevious.toDouble(),
        ),
        avgOrderValue: TrendEntity.compare(
          current: averageOrder(revenueCurrent, ordersCurrent),
          previous: averageOrder(revenuePrevious, ordersPrevious),
        ),
        itemsSold: itemsTrend,
        products: productsTrend,
        lowStock: lowStockTrend,
      );

      _sparklines = {
        MetricTrendKey.revenue: revenueSeries,
        MetricTrendKey.itemsSold: _demoSeries(itemsTrend, seed: 1),
        MetricTrendKey.products: _demoSeries(productsTrend, seed: 2),
        MetricTrendKey.lowStock: _demoSeries(lowStockTrend, seed: 3),
      };
    } catch (_) {
      _trends = null;
      _sparklines = const {};
    }
    _trendsLoaded = true;
    notifyListeners();
  }

  /// A stand-in line for a metric with no daily history: a walk that ends
  /// where its arrow points, seeded so the same tile always draws the same
  /// shape instead of flickering between reloads.
  List<double> _demoSeries(TrendEntity trend, {required int seed}) {
    const points = 24;
    var value = 50.0 + seed * 7;
    var state = seed * 2654435761;
    final drift = switch (trend.direction) {
      TrendDirection.up => 1.4,
      TrendDirection.down => -1.4,
      TrendDirection.flat => 0.0,
    };

    final values = <double>[];
    for (var i = 0; i < points; i++) {
      values.add(value);
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      final jitter = ((state % 1000) / 1000 - 0.5) * 7;
      value += drift + jitter;
      if (value < 3) value = 3;
    }
    return values;
  }
}

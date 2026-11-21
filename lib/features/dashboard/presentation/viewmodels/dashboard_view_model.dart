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
  /// `category_quantity`, so it scopes the quantity chart and the preview
  /// tables. The card figures come from `month_summary`, not this window.
  static const int _windowDays = 30;

  Map<String, TablePage> _tablePreviews = const {};

  /// First page of rows behind each inline preview table, keyed by
  /// [DashboardTablePreviews.requests].
  Map<String, TablePage> get tablePreviews => _tablePreviews;

  bool _previewsLoaded = false;
  bool get previewsLoaded => _previewsLoaded;

  SummaryTrendsEntity? _trends;

  /// The arrows beside the Sales Summary figures and the KPI tiles, built from
  /// the API's calendar-month comparison. Null only when the dashboard itself
  /// failed to load and the card has no numbers to annotate.
  SummaryTrendsEntity? get trends => _trends;

  /// One series per KPI tile, keyed by the tile's [MetricTrendKey] — the raw
  /// shape the tile's mini line is drawn from.
  ///
  /// Each series is the metric's calendar-month value over the last year, so
  /// all four tiles read as a month-by-month trend and the last point lines up
  /// with the percentage above it.
  Map<MetricTrendKey, List<double>> _sparklines = const {};
  Map<MetricTrendKey, List<double>> get sparklines => _sparklines;

  /// Whether [trends] has been built from the loaded dashboard yet.
  ///
  /// The arrows come with the dashboard payload, so this flips true in the
  /// same pass the cards first get their numbers. Until then the tile reserves
  /// its badge row, and the grid does not jump when the arrows appear.
  bool _trendsLoaded = false;
  bool get trendsLoaded => _trendsLoaded;

  /// Top payment method by transaction count.
  ({String method, int count, double percent, List<({String method, int count, double percent})> distribution})?
      _topPayment;
  ({String method, int count, double percent, List<({String method, int count, double percent})> distribution})?
      get topPayment => _topPayment;

  /// Full payment distribution (all methods), sorted by count descending.
  List<({String method, int count, double percent})> get paymentDistribution =>
      _topPayment?.distribution ?? const [];

  Future<void> load() async {
    final result = await runAsync(
      (token) => _repository.getDashboardData(days: _windowDays),
      errorPrefix: 'Failed to load dashboard',
    );
    if (result != null) _data = result;
    _buildMonthlyTrends();
    await Future.wait([
      loadMonthlySales(year: _selectedYear),
      _loadTablePreviews(),
      _loadTopPayment(),
    ]);
  }

  Future<void> _loadTopPayment() async {
    try {
      _topPayment = await _repository.getTopPaymentMethod(days: _windowDays);
    } catch (_) {
      // Non-critical: top payment is optional
    }
    notifyListeners();
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
            perPage: request.perPage,
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

  /// Derives the arrows and sparklines from the calendar-month figures the
  /// dashboard payload already carries.
  ///
  /// Nothing is fetched here: `/dashboard/all` returns this month's figures
  /// and last month's side by side, so an arrow can never disagree with the
  /// value printed above it. If an older backend omits `month_summary` the
  /// figures arrive as zeroes and the arrows read flat rather than invented.
  void _buildMonthlyTrends() {
    final summary = _data?.monthSummary;

    if (summary == null) {
      _trends = null;
      _sparklines = const {};
      _trendsLoaded = false;
      notifyListeners();
      return;
    }

    _trends = SummaryTrendsEntity(
      revenue: summary.revenue.trend(),
      orders: summary.orders.trend(),
      avgOrderValue: summary.avgOrderValue.trend(),
      itemsSold: summary.itemsSold.trend(),
      products: summary.products.trend(),
      // More low stock is worse: the arrow follows the count, only the colour
      // and the tooltip word flip.
      lowStock: summary.lowStock.trend(inverted: true),
    );

    // Every tile has a real month-by-month line now. The figure's series ends
    // at the current month, so the line's last move matches the arrow.
    _sparklines = {
      if (summary.revenue.series.length > 1)
        MetricTrendKey.revenue: summary.revenue.series,
      if (summary.itemsSold.series.length > 1)
        MetricTrendKey.itemsSold: summary.itemsSold.series,
      if (summary.products.series.length > 1)
        MetricTrendKey.products: summary.products.series,
      if (summary.lowStock.series.length > 1)
        MetricTrendKey.lowStock: summary.lowStock.series,
      if (summary.orders.series.length > 1)
        MetricTrendKey.orders: summary.orders.series,
      if (summary.avgOrderValue.series.length > 1)
        MetricTrendKey.avgOrderValue: summary.avgOrderValue.series,
    };

    _trendsLoaded = true;
    notifyListeners();
  }
}

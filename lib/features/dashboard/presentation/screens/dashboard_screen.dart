import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_table_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:posfrontend/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_text.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_card.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/count_up_text.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';
import 'package:posfrontend/features/sale/presentation/screens/quick_sale_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/stock_add_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardViewModel _viewModel;
  final CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(repository: DashboardRepositoryImpl());
    _viewModel.load();
    _loadProfileImage();
    _checkDailyStockReport();
  }

  /// App-open catch-up for the daily stock summary: the schedule slot is the
  /// preferred send time; when it was missed the server dispatches the report
  /// once today's schedule time has passed. Keeps re-checking (10 min) until
  /// the server confirms today's claim — `before_schedule` and `dispatched`
  /// are not final, only `already_sent` is. Fire-and-forget: a failed call
  /// costs nothing because the next open still owns the day.
  static DateTime? _lastReportCheck;
  Timer? _reportRetryTimer;

  Future<void> _checkDailyStockReport() async {
    final now = DateTime.now();
    if (_lastReportCheck != null &&
        now.difference(_lastReportCheck!) < const Duration(minutes: 2)) {
      return;
    }
    _lastReportCheck = now;

    try {
      final resp = await ApiClient.instance.post(
        '/notifications/daily-report/check',
      );
      final data = resp.data;
      final reason = (data is Map<String, dynamic>) ? data['reason'] : null;

      if (reason == 'already_sent') {
        _reportRetryTimer?.cancel();
        return;
      }

      // Not done yet — before today's schedule slot, or the report was just
      // dispatched. Keep checking while this session stays open so a missed
      // schedule slot is caught up the same day, not only on next launch.
      if (mounted) {
        _reportRetryTimer?.cancel();
        _reportRetryTimer = Timer(
          const Duration(minutes: 10),
          _checkDailyStockReport,
        );
      }
    } catch (_) {
      // Non-critical: never block or surface this to the user.
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final dio = ApiClient.instance;
      final resp = await dio.get('/auth/profile', cancelToken: _cancelToken);
      final data = resp.data;
      final image = (data is Map<String, dynamic>) ? (data['image'] ?? '') : '';
      if (image is String && image.isNotEmpty && mounted) {
        // Resolved here rather than trusted: this writes into the shared
        // avatar notifier the whole app bar reads, and it fetches the raw
        // JSON instead of going through the profile model that would have
        // done it — so an avatar kept on the backend's own /uploads was
        // being handed to the widget as a path nothing could fetch.
        ProfileImageNotifier.instance.update(resolveMediaUrl(image) ?? image);
      }
    } catch (_) {
      // Profile image fetch failure is non-critical
    }
  }

  @override
  void dispose() {
    _reportRetryTimer?.cancel();
    if (!_cancelToken.isCancelled) _cancelToken.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppShell(
      active: DrawerDestination.dashboard,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Dashboard'),
              // No hamburger on a wide window: the sidebar is already on screen.
              showMenuButton: !isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return RefreshableBody(
                    onRefresh: () => _viewModel.load(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: _buildBody(context, p),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_viewModel.isLoading && _viewModel.data == null)
          const DashboardSkeleton()
        else if (_viewModel.hasError)
          ErrorRetryView(
            message: _viewModel.errorMessage ?? 'Something went wrong',
            onRetry: _viewModel.load,
          )
        else if (_viewModel.data == null)
          const DashboardSkeleton()
        else ...[
          _buildHeader(context, p),
          const SizedBox(height: 12),
          ..._sections(context, p, _viewModel.data!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context, AppPalette p) {
    final shopName = ShopScope.shopOf(context)?.name.trim() ?? '';
    final heading = shopName.isEmpty ? context.l10n.t('Dashboard') : shopName;
    return Text(
      heading,
      style: GoogleFonts.spaceGrotesk(
        fontSize: AppTypography.displaySmallSize - 4,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  // -------------------------------------------------------------- sections

  /// The cards currently on screen, in the design's order, each followed by
  /// its gap. Hero bento + Monthly Sales + Sales Summary + rest.
  List<Widget> _sections(
    BuildContext context,
    AppPalette p,
    DashboardEntity d,
  ) {
    final out = <Widget>[];
    void section(Widget child) {
      out.add(child);
      out.add(const SizedBox(height: 24));
    }

    // Unified Hero Bento Container (replaces KPI grid)
    section(_HeroBentoContainer(
      totalSales: d.stats.totalSales,
      revenueTrend: _viewModel.trends?.revenue,
      revenueSparkline: _viewModel.sparklines[MetricTrendKey.revenue],
      totalProducts: d.stats.totalProducts,
      totalItemsSold: d.stats.totalItemsSold,
      outStockCount: d.stats.outStock,
      totalProductsForOutStock: d.stats.totalProducts,
      onNewSaleTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuickSaleScreen()),
      ),
      onRestockTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StockAddScreen()),
      ),
    ));

    // Bottom: Sales Summary (35%) + Monthly Sales (65%)
    section(
      _equalHeightPair(
        (fill, _) => Column(
          children: [
            _SalesKpiCard(
              icon: Icons.receipt_long_rounded,
              iconColor: Color(0xFF2563EB),
              label: 'Total Orders',
              value: d.stats.salesCount.withCommas(),
              trend: _viewModel.trends?.orders,
              subtitle: '~${(d.stats.salesCount / 30).toStringAsFixed(1)} orders / day',
              rightVisual: _LineChartMini(
                values: _viewModel.sparklines[MetricTrendKey.orders] ?? [],
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 12),
            _SalesKpiCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: Color(0xFFF87171),
              label: 'Avg. Order Value',
              value: 'MMK ${d.stats.avgOrderValue.withCommas()}',
              trend: _viewModel.trends?.avgOrderValue,
              subtitle: '${((_viewModel.data?.monthSummary.avgOrderValue.current ?? 0) / (d.stats.salesCount > 0 ? d.stats.salesCount : 1)).toStringAsFixed(2)} items/order',
              rightVisual: _MiniBarChart(
                values: [8, 10, 22, 34, 24, 14, 6, 4],
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            _SalesKpiCard(
              icon: Icons.credit_card_rounded,
              iconColor: Color(0xFF8B5CF6),
              label: 'Top Payment',
              value: _viewModel.topPayment != null
                  ? '${_viewModel.topPayment!.method} ${_viewModel.topPayment!.percent.round()}%'
                  : 'N/A',
              trend: null,
              subtitle: null,
              rightVisual: _PaymentCapsule(
                percent: _viewModel.topPayment?.percent ?? 0,
                color: Color(0xFF8B5CF6),
                method: _viewModel.topPayment?.method ?? 'Cash',
                count: _viewModel.topPayment?.count ?? 98,
              ),
            ),
          ],
        ),
        (fill, _) => _monthlySalesCard(context, p, fill: fill),
        leftFlex: 35,
        rightFlex: 65,
      ),
    );

    // Category Allocation + Stock Status (swapped: Stock Status moved up)
    section(
      _equalHeightPair(
        (fill, width) => _categoryAllocationCard(
          context,
          p,
          d,
          fill: fill,
          bodyWidth: width - 32,
        ),
        (fill, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StockStatusCard(stats: d.stats),
            const SizedBox(height: 12),
            _PackageStockStatusCard(stats: d.stats),
          ],
        ),
        leftFlex: 60,
        rightFlex: 40,
      ),
    );

    // Product Trend + Quantity Sold (swapped: Quantity Sold moved down)
    final trend = _productTrendCard(context, p, d);
    section(_pair(trend, _quantitySoldCard(context, p, d)));

    // Low Stock + Not Sold
    section(_pair(_lowStockPreview(context, p), _notSoldPreview(context, p)));

    // Recent Sales + Recent Products
    final recentSales = _recentSalesPreview(context, p);
    final recentProducts = _recentProductsPreview(context, p);
    section(_pair(recentSales, recentProducts));

    out.add(const _Footer());
    return out;
  }

  /// Two cards side by side on a wide window, stacked on a narrow one. The
  /// optional flex ratio lets one side take more of the width than the other.
  Widget _pair(
    Widget left,
    Widget right, {
    int leftFlex = 1,
    int rightFlex = 1,
    double gap = 24,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              SizedBox(height: gap),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }

  void _openSummaryTable(DashboardTableKey? key) {
    final route = switch (key) {
      DashboardTableKey.products => DashboardTableScreen.route(
        spec: DashboardTables.products,
      ),
      DashboardTableKey.inStock => DashboardTableScreen.route(
        spec: DashboardTables.inStock,
      ),
      DashboardTableKey.lowStock => DashboardTableScreen.route(
        spec: DashboardTables.lowStock,
        query: const {'low': 1},
      ),
      DashboardTableKey.sales => DashboardTableScreen.route(
        spec: DashboardTables.sales,
      ),
      null => null,
    };

    if (route == null) return;
    Navigator.of(context).push(route);
  }

  // -------------------------------------------------------- monthly + summary

  Widget _monthlySalesCard(
    BuildContext context,
    AppPalette p, {
    bool fill = false,
  }) {
    var years = _viewModel.years.isEmpty
        ? [DateTime.now().year]
        : _viewModel.years;
    if (!years.contains(_viewModel.selectedYear)) {
      years = [_viewModel.selectedYear, ...years];
    }

    return _PanelCard(
      title: context.l10n.t('Monthly Sales'),
      fill: fill,
      trailing: _YearDropdown(
        years: years,
        value: _viewModel.selectedYear,
        onChanged: (year) => _viewModel.loadMonthlySales(year: year),
      ),
      child: _viewModel.isLoadingMonthly
          ? const MonthlySalesChartSkeleton()
          : _viewModel.monthlySales.isEmpty
          ? SizedBox(
              height: 200,
              child: AppEmptyState(
                title: context.l10n.t('No sales data'),
                icon: Icons.bar_chart_outlined,
              ),
            )
          : _MonthlySalesChart(
              items: _viewModel.monthlySales,
              palette: p,
              expand: fill,
            ),
    );
  }

  /// Two cards side by side on a wide window, both the same height, stacked on
  /// a narrow one.
  ///
  /// The row takes the taller card's intrinsic height and
  /// [CrossAxisAlignment.stretch] makes the shorter card match, so the two
  /// panels line up along the bottom instead of ending wherever their contents
  /// happen to end. Each builder receives `fill`, true when the cards are
  /// stretched into that shared height, so a card can hand the spare height to
  /// its body — a chart grows into it, a list spreads its rows — rather than
  /// leaving a blank strip under the shorter card. It also receives the width
  /// the card will get, for bodies that choose their shape from their own
  /// width: under IntrinsicHeight a nested LayoutBuilder cannot be measured, so
  /// the decision has to be made before the card is built. On a narrow window
  /// the cards stack and keep their natural heights.
  Widget _equalHeightPair(
    Widget Function(bool fill, double width) left,
    Widget Function(bool fill, double width) right, {
    int leftFlex = 1,
    int rightFlex = 1,
    double gap = 24,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left(false, constraints.maxWidth),
              SizedBox(height: gap),
              right(false, constraints.maxWidth),
            ],
          );
        }
        final totalFlex = leftFlex + rightFlex;
        final available = constraints.maxWidth - gap;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: leftFlex,
                child: left(true, available * leftFlex / totalFlex),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: rightFlex,
                child: right(true, available * rightFlex / totalFlex),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------- category sections

  Widget _categoryAllocationCard(
    BuildContext context,
    AppPalette p,
    DashboardEntity d, {
    bool fill = false,
    double? bodyWidth,
  }) {
    final items = d.categoryDistribution;
    final total = items.fold<int>(0, (sum, e) => sum + e.productCount);

    return _PanelCard(
      title: context.l10n.t('Product Allocation by Category'),
      fill: fill,
      padding: const EdgeInsets.all(12),
      titlePadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      trailing: _ViewAllLink(
        onTap: () => Navigator.of(
          context,
        ).push(DashboardTableScreen.route(spec: DashboardTables.products)),
      ),
      child: items.isEmpty
          ? SizedBox(
              height: 200,
              child: AppEmptyState(
                title: context.l10n.t('No category data'),
                icon: Icons.pie_chart_outline,
              ),
            )
          : bodyWidth != null
          ? _allocationBody(p, items, total, bodyWidth)
          : LayoutBuilder(
              builder: (context, constraints) =>
                  _allocationBody(p, items, total, constraints.maxWidth),
            ),
    );
  }

  /// The donut and legend side by side while the legend keeps a workable width
  /// beside it, stacked below that.
  ///
  /// The width is passed in rather than measured so the equal-height row can
  /// decide the shape before laying the card out: a nested LayoutBuilder cannot
  /// be measured by IntrinsicHeight.
  Widget _allocationBody(
    AppPalette p,
    List<CategoryDistributionEntity> items,
    int total,
    double width,
  ) {
    final donut = _CategoryDonut(items: items, total: total, palette: p);
    final legend = _CategoryLegend(items: items, total: total, palette: p);
    if (width >= 560) {
      return Row(
        // Centred rather than top-aligned so the donut sits level with the
        // legend when the card is stretched to match its neighbour.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Center(child: donut)),
          const SizedBox(width: 20),
          Container(width: 1, height: 200, color: p.border),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: legend),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: donut),
        const SizedBox(height: 16),
        legend,
      ],
    );
  }

  Widget _quantitySoldCard(
    BuildContext context,
    AppPalette p,
    DashboardEntity d, {
    bool fill = false,
  }) {
    final items = d.categoryQuantity;
    return _PanelCard(
      title: context.l10n.t('Quantity Sold by Category'),
      fill: fill,
      trailing: _TagChip(label: context.l10n.t('By Quantity')),
      child: items.isEmpty
          ? SizedBox(
              height: 240,
              child: AppEmptyState(
                title: context.l10n.t('No sales data'),
                icon: Icons.bar_chart_outlined,
              ),
            )
          : _HorizontalCategoryChart(items: items, palette: p, expand: fill),
    );
  }

  // ------------------------------------------------------------- trend/stock

  Widget _productTrendCard(
    BuildContext context,
    AppPalette p,
    DashboardEntity d,
  ) {
    final tiles = [
      _TrendTile(
        title: context.l10n.t('Most Bought'),
        tint: p.successBg,
        titleColor: p.successFg,
        items: d.mostBought,
        onViewAll: () => Navigator.of(context).push(
          DashboardTableScreen.route(
            spec: DashboardTables.bought,
            showDirectionToggle: true,
          ),
        ),
      ),
      _TrendTile(
        title: context.l10n.t('Least Bought'),
        tint: p.warningBg,
        titleColor: p.warningFg,
        items: d.leastBought,
        onViewAll: () => Navigator.of(context).push(
          DashboardTableScreen.route(
            spec: DashboardTables.leastBought,
            showDirectionToggle: true,
            initialDirection: 'asc',
          ),
        ),
      ),
      _TrendTile(
        title: context.l10n.t('No Sales'),
        tint: p.dangerBg,
        titleColor: p.dangerFg,
        items: d.noBought,
        onViewAll: () => Navigator.of(
          context,
        ).push(DashboardTableScreen.route(spec: DashboardTables.noBought)),
      ),
    ];

    return _PanelCard(
      title: context.l10n.t('Product Trend'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget rowOf(List<Widget> children) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: children[i]),
              ],
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  tiles[i],
                ],
              ],
            );
          }
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                rowOf([tiles[0], tiles[1]]),
                const SizedBox(height: 16),
                tiles[2],
              ],
            );
          }
          return rowOf(tiles);
        },
      ),
    );
  }

  // -------------------------------------------------------- preview tables

  Widget _lowStockPreview(BuildContext context, AppPalette p) {
    return _PreviewTableCard(
      title: context.l10n.t('Low Stock Items'),
      columns: DashboardTablePreviews.lowStockItems.columns,
      page: _viewModel.tablePreviews['lowStockItems'],
      loaded: _viewModel.previewsLoaded,
      onViewAll: () => Navigator.of(context).push(
        DashboardTableScreen.route(
          spec: DashboardTables.lowStock,
          query: const {'low': 1},
        ),
      ),
    );
  }

  Widget _notSoldPreview(BuildContext context, AppPalette p) {
    return _PreviewTableCard(
      title: context.l10n.t('Products Not Sold'),
      columns: DashboardTablePreviews.productsNotSold.columns,
      page: _viewModel.tablePreviews['productsNotSold'],
      loaded: _viewModel.previewsLoaded,
      onViewAll: () => Navigator.of(
        context,
      ).push(DashboardTableScreen.route(spec: DashboardTables.noBought)),
    );
  }

  Widget _recentSalesPreview(BuildContext context, AppPalette p) {
    return _PreviewTableCard(
      title: context.l10n.t('Recent Sales'),
      columns: DashboardTablePreviews.recentSales.columns,
      page: _viewModel.tablePreviews['recentSales'],
      loaded: _viewModel.previewsLoaded,
      onViewAll: () => Navigator.of(
        context,
      ).push(DashboardTableScreen.route(spec: DashboardTables.sales)),
    );
  }

  Widget _recentProductsPreview(BuildContext context, AppPalette p) {
    return _PreviewTableCard(
      title: context.l10n.t('Recent Products'),
      columns: DashboardTablePreviews.recentProducts.columns,
      page: _viewModel.tablePreviews['recentProducts'],
      loaded: _viewModel.previewsLoaded,
      onViewAll: () => Navigator.of(
        context,
      ).push(DashboardTableScreen.route(spec: DashboardTables.products)),
    );
  }
}

// ============================================================ shared pieces

/// Lays [children] out in a responsive grid: [maxColumns] across on wide
/// windows, two on medium, one on phones, with [gap] between cells.
///
/// Rows are always full-width and the last row's missing cells collapse to a
/// gap, so a five-item grid on a four-column window reads as four then one
/// rather than stretching five across.
Widget _responsiveGrid(
  List<Widget> children, {
  double wideAt = 1080,
  double mediumAt = 620,
  double gap = 16,
  int maxColumns = 4,
}) {
  if (children.isEmpty) return const SizedBox.shrink();
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= wideAt
          ? maxColumns
          : width >= mediumAt
          ? 2
          : 1;

      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += columns) {
        final end = i + columns > children.length
            ? children.length
            : i + columns;
        final slice = children.sublist(i, end);
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
        if (end < children.length) rows.add(SizedBox(height: gap));
      }
      return Column(children: rows);
    },
  );
}

class _KpiGrid extends StatelessWidget {
  final List<MetricEntity> metrics;
  final SummaryTrendsEntity? trends;
  final Map<MetricTrendKey, List<double>> sparklines;
  final bool trendsLoaded;
  final void Function(DashboardTableKey? key) onOpenTable;

  const _KpiGrid({
    required this.metrics,
    required this.trends,
    required this.sparklines,
    required this.trendsLoaded,
    required this.onOpenTable,
  });

  /// The arrow for one tile, or null when the tile declares no comparison
  /// or the windows could not be fetched.
  TrendEntity? _trendFor(MetricEntity metric) =>
      metric.trendKey == MetricTrendKey.none
      ? null
      : trends?.forMetric(metric.trendKey);

  @override
  Widget build(BuildContext context) {
    return _responsiveGrid(
      [
        for (final metric in metrics)
          _KpiCard(
            metric: metric,
            trend: _trendFor(metric),
            series: sparklines[metric.trendKey],
            // A tile that will show an arrow keeps its row until the answer
            // arrives, so the cards below do not shift when it does.
            reserveBadge:
                metric.trendKey != MetricTrendKey.none &&
                _trendFor(metric) == null &&
                !trendsLoaded,
            onOpenTable: onOpenTable,
          ),
      ],
      wideAt: 1080,
      mediumAt: 620,
      gap: 16,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final MetricEntity metric;
  final TrendEntity? trend;

  /// The tile's daily line, or null while it is still being fetched.
  final List<double>? series;
  final bool reserveBadge;
  final void Function(DashboardTableKey? key) onOpenTable;

  const _KpiCard({
    required this.metric,
    required this.trend,
    required this.series,
    required this.reserveBadge,
    required this.onOpenTable,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: metric.tableKey == null
          ? null
          : () => onOpenTable(metric.tableKey),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color(metric.iconBgValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                metric.icon,
                size: 22,
                color: Color(metric.iconColorValue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.t(metric.label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appText(size: AppTypography.labelSmallSize, color: p.textSecondary),
                        ),
                      ),
                      if (metric.tableKey != null)
                        Icon(Icons.chevron_right, size: 16, color: p.textMuted),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Scaled rather than truncated: `MMK 11,280,000` must stay
                  // whole, and an ellipsis would cut the very figure the card
                  // exists to show.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CountUpString(
                            value: metric.value,
                            maxLines: 1,
                            style: appText(
                              size: 24,
                              weight: FontWeight.w700,
                              color: p.textPrimary,
                              height: 1.05,
                            ).copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      if (series != null && series!.length > 1) ...[
                        const SizedBox(width: 8),
                        // The design's little line beside the figure: the
                        // metric's recent shape, tinted the same way as the
                        // arrow underneath it.
                        _Sparkline(values: series!, trend: trend),
                      ],
                    ],
                  ),
                  if (trend != null) ...[
                    const SizedBox(height: 6),
                    // The photo's `↑ 18% from last month`, in the same badge
                    // the Sales Summary rows use. Absent when the API keeps
                    // no history for this tile — a guessed arrow would be
                    // worse than none.
                    _TrendBadge(trend: trend!),
                  ] else if (reserveBadge)
                    // Same height as the badge above, held empty until the
                    // comparison arrives.
                    const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bordered panel with an optional heading and a trailing affordance (a
/// year picker, a "View all" link, a chip).
///
/// [titlePadding] exists so a table can run its header and row stripes edge
/// to edge while the heading keeps the normal inset: pass
/// `padding: EdgeInsets.zero` with a title padding and the table supplies its
/// own horizontal inset.
class _PanelCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? titlePadding;

  /// Whether the body should consume the card's whole remaining height.
  ///
  /// Only safe when the card is given a bounded height, i.e. it is stretched
  /// to match a sibling; on its own the body keeps its natural height.
  final bool fill;

  const _PanelCard({
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.titlePadding,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      width: double.infinity,
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: titlePadding ?? padding,
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(
                          size: 16,
                          weight: FontWeight.w700,
                          color: p.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ),
          if (title != null) const SizedBox(height: 8),
          if (fill)
            Expanded(
              child: Padding(padding: padding, child: child),
            )
          else
            Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.t('View all'),
              style: appText(
                size: AppTypography.labelSmallSize,
                weight: FontWeight.w600,
                color: p.accentText,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 14, color: p.accentText),
          ],
        ),
      ),
    );
  }
}

/// A small non-interactive label in a card header, e.g. "By Quantity".
class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Text(
        label,
        style: appText(
          size: AppTypography.labelSmallSize,
          weight: FontWeight.w600,
          color: p.textSecondary,
        ),
      ),
    );
  }
}

// ======================================================= sales summary panel

class _SummaryRowData {
  final IconData icon;
  final int bgValue;
  final int fgValue;
  final String label;
  final Widget value;

  /// The change behind this figure, drawn under it. Null when the comparison
  /// could not be fetched — the row still shows its number, without a sign.
  final TrendEntity? trend;

  const _SummaryRowData({
    required this.icon,
    required this.bgValue,
    required this.fgValue,
    required this.label,
    required this.value,
    this.trend,
  });
}

class _SalesSummaryCard extends StatelessWidget {
  final DashboardStatsEntity stats;
  final SummaryTrendsEntity? trends;

  /// Whether to spread the rows over the card's full height so this panel can
  /// stand level with the taller monthly chart beside it.
  final bool fill;

  const _SalesSummaryCard({
    required this.stats,
    required this.trends,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final valueStyle = appText(
      size: 14,
      weight: FontWeight.w700,
      color: p.textPrimary,
    );

    final rows = [
      _SummaryRowData(
        icon: Icons.receipt_long_outlined,
        bgValue: 0xFFDBEAFE,
        fgValue: 0xFF3B82F6,
        label: 'Total Orders',
        value: Text(stats.salesCount.withCommas(), style: valueStyle),
        trend: trends?.orders,
      ),
      _SummaryRowData(
        icon: Icons.shopping_bag_outlined,
        bgValue: 0xFFFEE2E2,
        fgValue: 0xFFEF4444,
        label: 'Avg. Order Value',
        value: PriceText(stats.avgOrderValue.toDouble(), style: valueStyle),
        trend: trends?.avgOrderValue,
      ),
      _SummaryRowData(
        icon: Icons.payment_outlined,
        bgValue: 0xFFF3E8FF,
        fgValue: 0xFF7952DB,
        label: 'Top Payment',
        value: Text('KBZpay 54%', style: valueStyle),
        trend: null,
      ),
    ];

    return _PanelCard(
      title: context.l10n.t('Sales Summary'),
      fill: fill,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: fill
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: p.border),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(rows[i].bgValue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    rows[i].icon,
                    size: 18,
                    color: Color(rows[i].fgValue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    context.l10n.t(rows[i].label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(size: AppTypography.labelMediumSize, color: p.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                // Tight, so the column takes its whole share of the row and
                // every figure — and every percentage under it — ends on the
                // same right edge. Loose let the column shrink to its widest
                // child and sit at the left of the flex area, so rows with
                // different values drifted out of line. The money still scales
                // down inside this bounded box instead of pushing the row past
                // the card. The sign sits under the figure rather than beside
                // it: a row that already carries `MMK 11,280,000` has no room
                // left for an arrow.
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      rows[i].value,
                      if (rows[i].trend != null) ...[
                        const SizedBox(height: 2),
                        _TrendBadge(trend: rows[i].trend!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single summary card for Sales Summary section.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final String label;
  final String value;
  final TrendEntity? trend;
  final Widget? rightVisual;
  final String? subtitle;

  const _SummaryCard({
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.label,
    required this.value,
    this.trend,
    this.rightVisual,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: fgColor),
              ),
              const SizedBox(width: 12),
              // Center Metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: appText(size: AppTypography.labelMediumSize, color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          value,
                          style: appText(
                            size: 18,
                            weight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        if (trend != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            trend!.direction == TrendDirection.up
                                ? Icons.trending_up
                                : trend!.direction == TrendDirection.down
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                            size: 16,
                            color: trend!.isBullish ? p.successFg : p.dangerFg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trend!.percent?.abs().toStringAsFixed(1)}%',
                            style: appText(
                              size: AppTypography.labelSmallSize,
                              weight: FontWeight.w600,
                              color: trend!.isBullish ? p.successFg : p.dangerFg,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              // Right Visual
              if (rightVisual != null) ...[
                const SizedBox(width: 12),
                rightVisual!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini sparkline for summary cards.
class _MiniSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _MiniSparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 30,
      child: CustomPaint(
        painter: _MiniSparklinePainter(values, color),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _MiniSparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = max - min < 1e-6 ? 1.0 : max - min;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - (values[i] - min) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini progress ring for summary cards.
class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _MiniProgressRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: appText(
              size: 10,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment percentage badge for summary cards.
class _PaymentPercentBadge extends StatelessWidget {
  final double percent;
  final Color color;

  const _PaymentPercentBadge({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${percent.round()}%',
          style: appText(
            size: 12,
            weight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Pill badge for summary cards.
class _PillBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _PillBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: appText(
          size: AppTypography.labelSmallSize,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Payment radial progress for summary cards (180-degree semi-circular arc gauge).
class _PaymentProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  final String method;
  final int count;

  const _PaymentProgressBar({
    required this.percent,
    required this.color,
    required this.method,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 70,
      height: 45,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Semi-circular arc gauge
          SizedBox(
            width: 70,
            height: 40,
            child: CustomPaint(
              painter: _SemiCircleGaugePainter(percent / 100, color, p.border),
            ),
          ),
          // Percentage text
          Positioned(
            bottom: 0,
            child: Text(
              '${percent.round()}%',
              style: appText(
                size: 11,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          // 0% and 100% labels
          Positioned(
            bottom: 0,
            left: 0,
            child: Text(
              '0%',
              style: appText(size: 8, color: p.textMuted),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              '100%',
              style: appText(size: 8, color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemiCircleGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _SemiCircleGaugePainter(this.progress, this.color, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    // Background track (180 degrees from left to right)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // pi (left side, 180 degrees)
      3.14159, // pi (sweep to right side)
      false,
      bgPaint,
    );

    // Active progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // Start at left (pi)
      3.14159 * progress, // Sweep proportional to progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact dark KPI card for Sales Summary.
class _SalesKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final TrendEntity? trend;
  final String? subtitle;
  final Widget? rightVisual;
  final String? valueSuffix;

  const _SalesKpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trend,
    this.subtitle,
    this.rightVisual,
    this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF232736)),
      ),
      child: Row(
        children: [
          // Left Icon (44x44, 12px radius)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          // Center Metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: appText(
                    size: AppTypography.labelMediumSize,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: appText(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (valueSuffix != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        valueSuffix!,
                        style: appText(
                          size: AppTypography.labelSmallSize,
                          weight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (trend != null && trend!.percent != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (trend!.isBullish ? Color(0xFF10B981) : Color(0xFFEF4444)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trend!.direction == TrendDirection.up
                                  ? Icons.arrow_upward_rounded
                                  : trend!.direction == TrendDirection.down
                                      ? Icons.arrow_downward_rounded
                                      : Icons.remove_rounded,
                              size: 10,
                              color: trend!.isBullish ? Color(0xFF34D399) : Color(0xFFF87171),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${trend!.percent!.abs().toStringAsFixed(1)}%',
                              style: appText(
                                size: 10,
                                weight: FontWeight.w600,
                                color: trend!.isBullish ? Color(0xFF34D399) : Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Right Visual
          if (rightVisual != null) ...[
            const SizedBox(width: 12),
            rightVisual!,
          ],
        ],
      ),
    );
  }
}

/// Dark pill badge for Avg Order Value card.
class _DarkPillBadge extends StatelessWidget {
  final String text;

  const _DarkPillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: appText(
          size: AppTypography.labelSmallSize,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Mini 7-bar distribution chart.
class _MiniBarChart extends StatelessWidget {
  final List<int> values;
  final Color color;

  const _MiniBarChart({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values.map((v) {
        final height = maxVal > 0 ? (v / maxVal * 45).clamp(7.0, 45.0) : 7.0;
        return Container(
          width: 10,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}

/// Payment capsule with segmented progress bar.
class _PaymentCapsule extends StatelessWidget {
  final double percent;
  final Color color;
  final String method;
  final int count;

  const _PaymentCapsule({
    required this.percent,
    required this.color,
    required this.method,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capsule progress container
          Container(
            height: 16,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Color(0xFF0B0D12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF64748B)),
            ),
            child: Row(
              children: [
                // Purple bar (Cash)
                Expanded(
                  flex: (percent * 0.96).round().clamp(1, 96),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Cyan segment (KPay)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Legend Row
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${method.substring(0, 4)} ${count}',
                style: appText(
                  size: AppTypography.labelSmallSize,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFF38BDF8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'KPay 1',
                style: appText(
                  size: AppTypography.labelSmallSize,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Line chart with gradient fill for Total Orders card.
class _LineChartMini extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _LineChartMini({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 50,
      child: CustomPaint(
        painter: _LineChartPainter(values, color),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _LineChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = max - min < 1e-6 ? 1.0 : max - min;

    // Find peak index
    var peakIndex = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peakIndex]) peakIndex = i;
    }

    final peakX = size.width * peakIndex / (values.length - 1);
    final peakY = size.height * (1 - (values[peakIndex] - min) / span);

    // Gradient fill path
    final fillPath = Path();
    final linePath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - (values[i] - min) / span);
      if (i == 0) {
        fillPath.moveTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0.0),
      ],
    );

    final fillRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(fillRect)
        ..style = PaintingStyle.fill,
    );

    // Draw line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw glowing dot at peak
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(peakX, peakY), 6, glowPaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(peakX, peakY), 4, dotPaint);

    // White inner dot
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(peakX, peakY), 2, innerPaint);

    // Dashed vertical line at peak
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(peakX, y),
        Offset(peakX, y + dashHeight),
        dashPaint,
      );
      y += dashHeight + dashSpace;
    }

    // Peak tooltip
    final tooltipText = 'Peak: ${values[peakIndex].round()}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: appText(
          size: 10,
          weight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipX = (peakX - textPainter.width / 2).clamp(0.0, size.width - textPainter.width);
    final tooltipY = peakY - textPainter.height - 12;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX - 4, tooltipY - 2, textPainter.width + 8, textPainter.height + 4),
      const Radius.circular(4),
    );

    final tooltipPaint = Paint()..color = Color(0xFF0B0D12);
    canvas.drawRRect(tooltipRect, tooltipPaint);

    final borderPaint = Paint()
      ..color = Color(0xFF232736)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(tooltipRect, borderPaint);

    textPainter.paint(canvas, Offset(tooltipX, tooltipY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The bullish/bearish sign under a summary figure: an arrow and the size of
/// the move, green up and red down.
///
/// The percentage is unsigned because the arrow already carries the sign —
/// `▼ 12.4%` reads faster than `-12.4%` next to a red arrow. The word lives
/// in the tooltip rather than on the surface: four labels printed down a
/// narrow card would crowd the figures they describe.
class _TrendBadge extends StatelessWidget {
  final TrendEntity trend;

  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // The arrow follows the number; the colour follows whether that direction
    // is good news. Low Stock Items rising is a warning, so it draws red
    // while pointing up.
    final (color, icon, label) = switch (trend.direction) {
      TrendDirection.up =>
        trend.isBullish
            ? (p.successFg, Icons.trending_up, 'Bullish')
            : (p.dangerFg, Icons.trending_up, 'Bearish'),
      TrendDirection.down =>
        trend.isBearish
            ? (p.dangerFg, Icons.trending_down, 'Bearish')
            : (p.successFg, Icons.trending_down, 'Bullish'),
      TrendDirection.flat => (p.textMuted, Icons.trending_flat, 'No change'),
    };

    return Tooltip(
      message: context.l10n.t(label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (trend.percent != null) ...[
            const SizedBox(width: 3),
            Text(
              '${trend.percent!.abs().toStringAsFixed(1)}%',
              style: appText(
                size: AppTypography.labelSmallSize,
                weight: FontWeight.w700,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================ total sales hero card

/// A prominent hero card for Total Sales: large figure, month-over-month trend,
/// and a 12-month sparkline. Taps through to the full sales table.
class _TotalSalesHeroCard extends StatelessWidget {
  final int totalSales;
  final TrendEntity? trend;
  final List<double>? sparkline;
  final VoidCallback onTap;

  const _TotalSalesHeroCard({
    required this.totalSales,
    required this.trend,
    required this.sparkline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.selectionTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    size: 26,
                    color: p.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.t('Total Sales'),
                        style: appText(
                          size: AppTypography.labelMediumSize,
                          weight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                      if (trend != null) ...[
                        const SizedBox(height: 4),
                        _TrendBadge(trend: trend!),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: p.textMuted),
              ],
            ),
            const SizedBox(height: 20),
            // Main figure — scaled so it never truncates
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpString(
                value: totalSales.toString(),
                style: appText(
                  size: 40,
                  weight: FontWeight.w800,
                  color: p.textPrimary,
                  height: 1.05,
                ).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // 12-month sparkline
            if (sparkline != null && sparkline!.length > 1) ...[
              const SizedBox(height: 16),
              _HeroSparkline(values: sparkline!, trend: trend),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('12-month trend'),
                style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================ hero bento container

/// Unified Hero Bento Container: single large rounded container split 40/60.
/// Left = Total Sales hero with gradient. Right = 3 nested metric cards.
class _HeroBentoContainer extends StatelessWidget {
  final int totalSales;
  final TrendEntity? revenueTrend;
  final List<double>? revenueSparkline;
  final int totalProducts;
  final int totalItemsSold;
  final int outStockCount;
  final int totalProductsForOutStock;
  final VoidCallback onNewSaleTap;
  final VoidCallback onRestockTap;

  const _HeroBentoContainer({
    required this.totalSales,
    required this.revenueTrend,
    required this.revenueSparkline,
    required this.totalProducts,
    required this.totalItemsSold,
    required this.outStockCount,
    required this.totalProductsForOutStock,
    required this.onNewSaleTap,
    required this.onRestockTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 40,
              child: _HeroLeftSection(
                totalSales: totalSales,
                trend: revenueTrend,
                sparkline: revenueSparkline,
                onNewSaleTap: onNewSaleTap,
              ),
            ),
            Container(width: 1, color: p.border),
            Expanded(
              flex: 60,
              child: _HeroRightSection(
                totalProducts: totalProducts,
                totalItemsSold: totalItemsSold,
                outStockCount: outStockCount,
                totalProductsForOutStock: totalProductsForOutStock,
                onRestockTap: onRestockTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Left section: Total Sales hero with violet gradient background.
class _HeroLeftSection extends StatelessWidget {
  final int totalSales;
  final TrendEntity? trend;
  final List<double>? sparkline;
  final VoidCallback onNewSaleTap;

  const _HeroLeftSection({
    required this.totalSales,
    required this.trend,
    required this.sparkline,
    required this.onNewSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E1065),
            p.surface,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.t('Total Sales'),
            style: appText(
              size: AppTypography.labelMediumSize,
              weight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: appText(
                size: 36,
                weight: FontWeight.w800,
                color: p.textPrimary,
                height: 1.05,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              children: [
                TextSpan(
                  text: 'MMK ',
                  style: appText(
                    size: 18,
                    weight: FontWeight.w600,
                    color: p.textSecondary,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                TextSpan(text: totalSales.withCommas()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (trend != null && trend!.percent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.successFg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: p.successFg.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 12, color: p.successFg),
                  const SizedBox(width: 4),
                  Text(
                    '+${trend!.percent!.abs().toStringAsFixed(1)}% vs last month',
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      weight: FontWeight.w600,
                      color: p.successFg,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Sparkline directly below pill
          SizedBox(
            height: 52,
            width: double.infinity,
            child: CustomPaint(painter: _SalesSparklinePainter()),
          ),
          const SizedBox(height: 16),
          // Compact left-aligned button
          SizedBox(
            child: ElevatedButton.icon(
              onPressed: onNewSaleTap,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'New Sale',
                style: appText(
                  size: AppTypography.labelMediumSize,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right section: 3 equal-width cards side-by-side.
class _HeroRightSection extends StatelessWidget {
  final int totalProducts;
  final int totalItemsSold;
  final int outStockCount;
  final int totalProductsForOutStock;
  final VoidCallback onRestockTap;

  const _HeroRightSection({
    required this.totalProducts,
    required this.totalItemsSold,
    required this.outStockCount,
    required this.totalProductsForOutStock,
    required this.onRestockTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const cardBg = Color(0x990B0E17);
    const cardBorder = Color(0xFF1E293B);
    const cardRadius = 12.0;

    // Calculate out of stock percentage
    final outStockPercent = totalProductsForOutStock > 0
        ? (outStockCount / totalProductsForOutStock).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _NestedMetricCard(
              label: context.l10n.t('Total Products'),
              value: totalProducts.toString(),
              backgroundColor: cardBg,
              borderColor: cardBorder,
              radius: cardRadius,
              child: _StockLevelBar(
                lowStock: 9,
                midStock: 15,
                highStock: 11,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _NestedMetricCard(
              label: context.l10n.t('Total Items Sold'),
              value: totalItemsSold.toString(),
              badge: '+22.4%',
              badgeColor: p.successFg,
              backgroundColor: cardBg,
              borderColor: cardBorder,
              radius: cardRadius,
              child: _CircularProgressRing(progress: 0.72, label: 'of monthly goal'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _NestedMetricCard(
              label: context.l10n.t('Out of Stock Alerts'),
              value: '$outStockCount items',
              backgroundColor: cardBg,
              borderColor: cardBorder,
              radius: cardRadius,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CircularProgressRing(
                    progress: outStockPercent,
                    color: p.dangerFg,
                    label: '${(outStockPercent * 100).round()}% out',
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRestockTap,
                    style: TextButton.styleFrom(
                      foregroundColor: p.dangerFg,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Restock',
                          style: appText(
                            size: AppTypography.labelSmallSize,
                            weight: FontWeight.w600,
                            color: p.dangerFg,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: p.dangerFg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable nested metric card.
class _NestedMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final Widget child;
  final String? badge;
  final Color? badgeColor;
  final bool pushToBottom;

  const _NestedMetricCard({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.radius,
    required this.child,
    this.badge,
    this.badgeColor,
    this.pushToBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: appText(
                    size: AppTypography.labelMediumSize,
                    weight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ),
              if (badge != null && badgeColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor!.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: badgeColor!.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badge!,
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      weight: FontWeight.w600,
                      color: badgeColor!,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: appText(
                size: 36,
                weight: FontWeight.w800,
                color: p.textPrimary,
                height: 1.05,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 12),
          if (pushToBottom) const Spacer(),
          child,
        ],
      ),
    );
  }
}

/// Horizontal segmented stock-level bar with legend.
class _StockLevelBar extends StatelessWidget {
  final int lowStock;
  final int midStock;
  final int highStock;

  const _StockLevelBar({
    required this.lowStock,
    required this.midStock,
    required this.highStock,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = lowStock + midStock + highStock;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (lowStock > 0)
              Expanded(
                flex: lowStock,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: p.dangerFg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            if (midStock > 0)
              Expanded(
                flex: midStock,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            if (highStock > 0)
              Expanded(
                flex: highStock,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: p.successFg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendDot(color: p.dangerFg, label: 'Low', count: lowStock),
            _LegendDot(color: p.primary, label: 'Mid', count: midStock),
            _LegendDot(color: p.successFg, label: 'High', count: highStock),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendDot({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
        ),
      ],
    );
  }
}

/// Payment method data for the bar chart.
class _PaymentMethod {
  final String name;
  final int percent;
  final Color color;

  const _PaymentMethod({required this.name, required this.percent, required this.color});
}

/// Horizontal bar showing payment method distribution.
class _PaymentMethodBar extends StatelessWidget {
  final List<_PaymentMethod> methods;

  const _PaymentMethodBar({required this.methods});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented bar
        Row(
          children: [
            for (final method in methods)
              Expanded(
                flex: method.percent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: method.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final method in methods)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: method.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${method.name} ${method.percent}%',
                    style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Clean circular progress ring.
class _CircularProgressRing extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;

  const _CircularProgressRing({required this.progress, this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ringColor = color ?? p.successFg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: p.border,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: appText(
                  size: AppTypography.labelSmallSize,
                  weight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: appText(
              size: AppTypography.labelSmallSize,
              color: p.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Larger sparkline for the hero card — full width, taller, with area fill.
class _HeroSparkline extends StatelessWidget {
  final List<double> values;
  final TrendEntity? trend;

  const _HeroSparkline({required this.values, required this.trend});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final color = switch (trend?.direction) {
      TrendDirection.up => trend!.isBullish ? p.successFg : p.dangerFg,
      TrendDirection.down => trend!.isBearish ? p.dangerFg : p.successFg,
      _ => p.textMuted,
    };

    return SizedBox(
      height: 80,
      child: CustomPaint(painter: _HeroSparklinePainter(values, color, p)),
    );
  }
}

class _HeroSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final AppPalette palette;

  _HeroSparklinePainter(this.values, this.color, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = max - min < 1e-6 ? 1.0 : max - min;

    const pad = 2.0;
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = pad + width * i / (values.length - 1);
      final y = pad + height * (1 - (values[i] - min) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Area fill
    final areaPath = Path.from(path);
    areaPath.lineTo(pad + width, pad + height);
    areaPath.lineTo(pad, pad + height);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots on each point
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = pad + width * i / (values.length - 1);
      final y = pad + height * (1 - (values[i] - min) / span);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      // White inner dot for pop
      canvas.drawCircle(Offset(x, y), 1.8, Paint()..color = palette.scaffoldBg);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroSparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color || oldDelegate.palette != palette;
}

/// The little line beside a KPI figure: the metric's recent shape drawn as a
/// bare polyline, tinted the way the tile's arrow points.
///
/// Deliberately not a chart — no axes, no grid, no labels. It exists so the
/// tile reads as "this moved" at a glance, which is what the design's spark
/// in the corner does.
class _Sparkline extends StatelessWidget {
  final List<double> values;
  final TrendEntity? trend;

  const _Sparkline({required this.values, required this.trend});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final color = switch (trend?.direction) {
      TrendDirection.up => trend!.isBullish ? p.successFg : p.dangerFg,
      TrendDirection.down => trend!.isBearish ? p.dangerFg : p.successFg,
      _ => p.textMuted,
    };

    return SizedBox(
      width: 64,
      height: 26,
      child: CustomPaint(painter: _SparklinePainter(values, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;

    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    // A flat series still wants a line, just not one pinned to an edge where
    // the stroke would be half-clipped.
    final span = max - min < 1e-6 ? 1.0 : max - min;

    // Inset by the stroke width so the round caps are not cut off.
    const pad = 1.5;
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = pad + width * i / (values.length - 1);
      final y = pad + height * (1 - (values[i] - min) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ============================================================ category donut

class _CategoryDonut extends StatelessWidget {
  final List<CategoryDistributionEntity> items;
  final int total;
  final AppPalette palette;

  const _CategoryDonut({
    required this.items,
    required this.total,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 64,
              startDegreeOffset: -90,
              sections: [
                for (final item in items)
                  PieChartSectionData(
                    value: item.productCount.toDouble(),
                    color: Color(item.colorValue),
                    radius: 56,
                    showTitle: false,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          SizedBox(
            width: 112,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total.withCommas(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: appText(
                    size: 26,
                    weight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.t('Products'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: appText(size: AppTypography.labelSmallSize, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<CategoryDistributionEntity> items;
  final int total;
  final AppPalette palette;

  const _CategoryLegend({
    required this.items,
    required this.total,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    double percentOf(CategoryDistributionEntity e) =>
        total <= 0 ? 0 : (e.productCount / total) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 4),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(items[i].colorValue),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  items[i].category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(
                    size: AppTypography.labelSmallSize,
                    weight: FontWeight.w500,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 32,
                child: Text(
                  items[i].productCount.withCommas(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: appText(
                    size: AppTypography.labelSmallSize,
                    weight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: Text(
                  '${percentOf(items[i]).toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: appText(size: AppTypography.labelSmallSize, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ============================================================== stock status

class _StockStatusRow {
  final IconData icon;
  final int tintValue;
  final int colorValue;
  final String label;
  final int count;

  const _StockStatusRow({
    required this.icon,
    required this.tintValue,
    required this.colorValue,
    required this.label,
    required this.count,
  });
}

class _StockStatusCard extends StatelessWidget {
  final DashboardStatsEntity stats;

  const _StockStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _StockStatusPanel(
      title: context.l10n.t('Product Stock Status'),
      total: stats.totalProducts,
      trailing: _ViewAllLink(
        onTap: () => Navigator.of(
          context,
        ).push(DashboardTableScreen.route(spec: DashboardTables.inStock)),
      ),
      rows: [
        _StockStatusRow(
          icon: Icons.check_circle_outline,
          tintValue: 0xFFDCFCE7,
          colorValue: 0xFF16A34A,
          label: 'In Stock',
          count: stats.inStock,
        ),
        _StockStatusRow(
          icon: Icons.warning_amber_outlined,
          tintValue: 0xFFFEF3C7,
          colorValue: 0xFFF59E0B,
          label: 'Low Stock',
          count: stats.lowStock,
        ),
        _StockStatusRow(
          icon: Icons.cancel_outlined,
          tintValue: 0xFFFEE2E2,
          colorValue: 0xFFEF4444,
          label: 'Out of Stock',
          count: stats.outStock,
        ),
      ],
    );
  }
}

/// Package-level stock, read from the dashboard API.
///
/// Each active package's stock is the summed available stock of the products
/// assigned to it. The API buckets them into in-stock / low / out, so the rows
/// here are real figures — nothing is generated on the client.
class _PackageStockStatusCard extends StatelessWidget {
  final DashboardStatsEntity stats;

  const _PackageStockStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _StockStatusPanel(
      title: context.l10n.t('Package Stock Status'),
      total: stats.totalPackages,
      rows: [
        _StockStatusRow(
          icon: Icons.check_circle_outline,
          tintValue: 0xFFDCFCE7,
          colorValue: 0xFF16A34A,
          label: 'In Stock',
          count: stats.packagesInStock,
        ),
        _StockStatusRow(
          icon: Icons.warning_amber_outlined,
          tintValue: 0xFFFEF3C7,
          colorValue: 0xFFF59E0B,
          label: 'Low Stock',
          count: stats.packagesLowStock,
        ),
        _StockStatusRow(
          icon: Icons.cancel_outlined,
          tintValue: 0xFFFEE2E2,
          colorValue: 0xFFEF4444,
          label: 'Out of Stock',
          count: stats.packagesOutStock,
        ),
      ],
    );
  }
}

class _StockStatusPanel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<_StockStatusRow> rows;

  /// The number the bars and percentages divide by.
  final int total;

  const _StockStatusPanel({
    required this.title,
    required this.rows,
    required this.total,
    this.trailing,
  });

  double _shareOf(int value) =>
      total <= 0 ? 0 : (value / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _PanelCard(
      title: title,
      trailing: trailing,
      padding: const EdgeInsets.all(12),
      titlePadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(rows[i].tintValue),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    rows[i].icon,
                    size: 16,
                    color: Color(rows[i].colorValue),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: Text(
                    context.l10n.t(rows[i].label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(
                      size: AppTypography.labelMediumSize,
                      weight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DistributionBar(
                    fraction: _shareOf(rows[i].count),
                    color: Color(rows[i].colorValue),
                    trackColor: p.chipBg,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text(
                    rows[i].count.withCommas(),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: appText(
                      size: AppTypography.labelMediumSize,
                      weight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(_shareOf(rows[i].count) * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: appText(size: AppTypography.labelSmallSize, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================== trend tiles

class _TrendTile extends StatelessWidget {
  final String title;
  final Color tint;
  final Color titleColor;
  final List<ProductItemEntity> items;
  final VoidCallback onViewAll;

  const _TrendTile({
    required this.title,
    required this.tint,
    required this.titleColor,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(
                    size: AppTypography.labelMediumSize,
                    weight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.chevron_right, size: 18, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              context.l10n.t('Nothing to show'),
              style: appText(size: AppTypography.labelSmallSize, color: p.textSecondary),
            ),
          for (final item in items)
            Padding(
              key: ValueKey(item.name),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _ProductThumb(item: item, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appText(
                            size: AppTypography.labelMediumSize,
                            weight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.sold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appText(size: AppTypography.labelSmallSize, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final ProductItemEntity item;
  final double size;

  const _ProductThumb({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.image.isNotEmpty
          ? Image.network(
              item.image,
              key: ValueKey(item.image),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                item.icon,
                size: size * 0.5,
                color: p.textSecondary,
              ),
            )
          : Icon(item.icon, size: size * 0.5, color: p.textSecondary),
    );
  }
}

// ========================================================== preview tables

/// The first few rows of one dashboard table, inline, with a way out to the
/// full screen.
///
/// Cells are laid out by flex proportional to the spec's column widths rather
/// than at those widths: a preview sits in half a row, so the columns share
/// whatever width the card has instead of scrolling sideways. The full
/// screen behind "View all" still uses the absolute widths, where there is a
/// scroll view to carry them.
class _PreviewTableCard extends StatelessWidget {
  final String title;
  final List<TableColumn> columns;
  final TablePage? page;
  final bool loaded;
  final VoidCallback onViewAll;

  /// Horizontal inset for the header and row stripes, matching the card's
  /// normal padding while the stripes themselves run edge to edge.
  static const double _inset = 16;

  const _PreviewTableCard({
    required this.title,
    required this.columns,
    required this.page,
    required this.loaded,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = page?.rows ?? const <DashboardTableRow>[];

    return _PanelCard(
      title: title,
      trailing: _ViewAllLink(onTap: onViewAll),
      padding: EdgeInsets.zero,
      titlePadding: const EdgeInsets.fromLTRB(_inset, 16, _inset, 0),
      child: !loaded
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: _inset),
              child: _PreviewTableSkeleton(columns: columns),
            )
          : rows.isEmpty
          ? SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  context.l10n.t('Nothing to show'),
                  style: appText(size: AppTypography.labelMediumSize, color: p.textMuted),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: p.surfaceAlt,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _inset,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      _numberCell(
                        context,
                        p,
                        Text(
                          context.l10n.t('#'),
                          maxLines: 1,
                          style: _headerStyle(p),
                        ),
                      ),
                      for (final column in columns)
                        _flexCell(
                          column,
                          Text(
                            context.l10n.t(column.label),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _headerStyle(p),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: p.border),
                  Container(
                    color: i.isEven
                        ? Colors.transparent
                        : p.surfaceAlt.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _inset,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _numberCell(
                          context,
                          p,
                          Text(
                            (i + 1).toString(),
                            maxLines: 1,
                            style: appText(size: AppTypography.labelMediumSize, color: p.textMuted),
                          ),
                        ),
                        for (final column in columns)
                          _flexCell(
                            column,
                            _value(context, p, column, rows[i]),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  static TextStyle _headerStyle(AppPalette p) => appText(
    size: AppTypography.labelSmallSize,
    weight: FontWeight.w700,
    letterSpacing: 0.2,
    color: p.textSecondary,
  );

  /// The row-number column. Fixed flex so the numbers sit above their column
  /// on every row and every card.
  Widget _numberCell(BuildContext context, AppPalette p, Widget child) =>
      Expanded(
        flex: 30,
        child: Padding(padding: const EdgeInsets.only(right: 8), child: child),
      );

  Widget _flexCell(TableColumn column, Widget child) => Expanded(
    flex: column.width.round(),
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Align(
        alignment: column.align == TableColumnAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: child,
      ),
    ),
  );

  Widget _value(
    BuildContext context,
    AppPalette p,
    TableColumn column,
    DashboardTableRow row,
  ) {
    // Money goes through PriceText, like every other money surface: it scales
    // to the cell instead of ellipsizing `MMK 1,234,5...`.
    if (column.kind == TableValueKind.currency) {
      return PriceText(
        row.number(column.fieldKey),
        style: appText(
          size: AppTypography.labelMediumSize,
          weight: FontWeight.w600,
          color: p.textPrimary,
        ),
      );
    }

    return Text(
      row.display(column),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: column.align == TableColumnAlign.right
          ? TextAlign.right
          : TextAlign.left,
      style: appText(
        size: AppTypography.labelMediumSize,
        color: p.textPrimary,
        weight: column.kind == TableValueKind.text
            ? FontWeight.w400
            : FontWeight.w600,
      ),
    );
  }
}

/// Inert blocks in the shape of a preview table: a header row plus five data
/// rows. No sweep of its own — four concurrent sweeps on one screen is the
/// thing `SkeletonSweep` exists to avoid, and these are replaced within a
/// second of the dashboard itself appearing.
class _PreviewTableSkeleton extends StatelessWidget {
  final List<TableColumn> columns;

  const _PreviewTableSkeleton({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 30,
              child: SkeletonBox(height: 10, width: 14, radius: 5),
            ),
            for (final column in columns) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: column.width.round(),
                child: SkeletonBox(height: 10, radius: 5),
              ),
            ],
          ],
        ),
        for (var i = 0; i < 5; i++) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 30,
                child: SkeletonBox(height: 12, width: 18, radius: 6),
              ),
              for (final column in columns) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: column.width.round(),
                  child: SkeletonBox(height: 12, radius: 6),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ==================================================================== footer

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8,
        children: [
          Text(
            '© ${DateTime.now().year} Simple POS. All rights reserved.',
            style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
          ),
          Text(
            context.l10n.t('Simple POS. Greater Business.'),
            style: appText(
              size: AppTypography.labelSmallSize,
              weight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================= controls

class _YearDropdown extends StatelessWidget {
  final List<int> years;
  final int value;
  final ValueChanged<int> onChanged;

  const _YearDropdown({
    required this.years,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: years.contains(value) ? value : years.first,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: appText(size: AppTypography.labelMediumSize, color: p.textSecondary),
          items: years
              .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
              .toList(),
          onChanged: (v) {
            if (v != null && v != value) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ========================================================== monthly chart

/// Twelve monthly columns with the money scale on the left, matching the
/// design's vertical bars. The old chart drew the same data horizontally,
/// which put the months down the side and the money along the bottom — a
/// different reading of the same numbers, and not the one the design asks for.
class _MonthlySalesChart extends StatelessWidget {
  final List<MonthlySalesEntity> items;
  final AppPalette palette;

  /// Grows with the card instead of holding a fixed height, so the chart can
  /// fill a panel that was stretched to match the summary beside it. The usual
  /// height stays as the floor.
  final bool expand;

  const _MonthlySalesChart({
    required this.items,
    required this.palette,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final chart = CustomPaint(
      painter: _MonthlySalesChartPainter(items, palette),
    );

    if (expand) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 200),
        child: SizedBox(width: double.infinity, child: chart),
      );
    }

    return SizedBox(height: 200, width: double.infinity, child: chart);
  }
}

class _MonthlySalesChartPainter extends CustomPainter {
  final List<MonthlySalesEntity> items;
  final AppPalette palette;

  _MonthlySalesChartPainter(this.items, this.palette);

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sorted = [...items]..sort((a, b) => a.month.compareTo(b.month));
    if (sorted.isEmpty) return;

    final maxVal = sorted.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal <= 0 ? 1.0 : maxVal * 1.15;

    final axisStyle = appText(
      size: AppTypography.labelSmallSize,
      color: palette.textSecondary,
    );

    // The money gutter sizes itself from its widest figure instead of a fixed
    // 52pt: on a phone that column eats the bars' room, and a five-character
    // value ("1.2M") still has to fit inside it.
    const ticks = 4;
    final tickLabels = <TextPainter>[
      for (var t = 0; t <= ticks; t++)
        TextPainter(
          text: TextSpan(
            text: _formatValue(chartMax * (t / ticks)),
            style: axisStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    var tickWidth = 0.0;
    for (final tp in tickLabels) {
      if (tp.width > tickWidth) tickWidth = tp.width;
    }

    const rightPad = 16.0;
    const topPad = 30.0;
    const bottomPad = 32.0;
    final leftPad = (tickWidth + 12).clamp(30.0, 64.0);
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    // Money scale on the left, with a horizontal rule at each step so a bar's
    // height can be read without a tooltip.
    for (var t = 0; t <= ticks; t++) {
      final y = plot.bottom - (t / ticks) * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);

      final tp = tickLabels[t];
      final x = (plot.left - tp.width - 8).clamp(0.0, double.infinity);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    }

    // Twelve fixed slots whether or not every month has a sale, so the axis
    // never shifts as data arrives.
    final slotWidth = plot.width / 12;
    final barWidth = (slotWidth * 0.5).clamp(6.0, 40.0);

    // Month labels. Twelve 12pt abbreviations do not fit once a slot is
    // narrower than one of them — which is every phone — so they overlapped
    // into a smear. Step over the axis instead, anchored so December keeps its
    // label and the gap before it stays even.
    final monthPainters = <TextPainter>[
      for (final label in _monthLabels)
        TextPainter(
          text: TextSpan(text: label, style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    var widestMonth = 0.0;
    for (final tp in monthPainters) {
      if (tp.width > widestMonth) widestMonth = tp.width;
    }
    const minLabelGap = 6.0;
    final monthStep = (widestMonth + minLabelGap) > slotWidth
        ? ((widestMonth + minLabelGap) / slotWidth).ceil()
        : 1;

    for (var m = 11 % monthStep; m < 12; m += monthStep) {
      final tp = monthPainters[m];
      final x = (plot.left + slotWidth * (m + 0.5) - tp.width / 2)
          .clamp(plot.left, plot.right - tp.width);
      tp.paint(canvas, Offset(x, plot.bottom + 8));
    }

    final currentMonth = DateTime.now().month;
    final mutedBarPaint = Paint()..color = AppColors.brandPurple.withValues(alpha: 0.4);
    final valueLabels = <_MonthlyValueLabel>[];
    for (final entry in sorted) {
      if (entry.month < 1 || entry.month > 12) continue;
      final centreX = plot.left + slotWidth * ((entry.month - 1) + 0.5);
      final height = (entry.total / chartMax) * plot.height;
      final rect = Rect.fromLTWH(
        centreX - barWidth / 2,
        plot.bottom - height,
        barWidth,
        height,
      );
      // Highlight current month in bright purple, past months in muted
      final Paint paint;
      if (entry.month == currentMonth) {
        paint = Paint()..color = palette.primary;
      } else {
        paint = mutedBarPaint;
      }
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );

      // A month with no sale gets no figure: a row of "0"s is noise.
      if (entry.total <= 0) continue;

      final vp = TextPainter(
        text: TextSpan(
          text: _formatValue(entry.total.toDouble()),
          style: appText(
            size: AppTypography.labelSmallSize,
            weight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Value above the bar, dropped when the bar is tall enough that the
      // label would leave the plot — a clipped figure is worse than none.
      final y = plot.bottom - height - vp.height - 5;
      if (y < plot.top - 6) continue;
      final x = (centreX - vp.width / 2).clamp(plot.left, plot.right - vp.width);
      valueLabels.add(
        _MonthlyValueLabel(
          Rect.fromLTWH(x, y, vp.width, vp.height),
          vp,
          entry.total,
        ),
      );
    }

    // Tallest first, so when a phone-width plot cannot hold all twelve figures
    // the ones worth reading survive and the rest are dropped instead of
    // printed on top of each other.
    valueLabels.sort((a, b) => b.value.compareTo(a.value));
    final taken = <Rect>[];
    for (final label in valueLabels) {
      final box = label.rect.inflate(3);
      if (taken.any(box.overlaps)) continue;
      taken.add(box);
      label.painter.paint(canvas, label.rect.topLeft);
    }
  }

  String _formatValue(double value) {
    if (value >= 1000000) return '${_trim(value / 1000000)}M';
    if (value >= 1000) return '${_trim(value / 1000)}k';
    return value.round().toString();
  }

  String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  bool shouldRepaint(covariant _MonthlySalesChartPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.palette != palette;
}

/// A bar's value figure, kept as a laid-out painter plus the box it wants, so
/// the paint pass can decide which ones fit before drawing any of them.
class _MonthlyValueLabel {
  final Rect rect;
  final TextPainter painter;
  final int value;

  const _MonthlyValueLabel(this.rect, this.painter, this.value);
}

// ====================================================== category quantity bar

class _HorizontalCategoryChart extends StatelessWidget {
  final List<CategoryQuantityEntity> items;
  final AppPalette palette;

  /// Grows with the card instead of holding a fixed height, so the bars can
  /// fill a panel stretched to match the allocation card beside it. The
  /// computed height stays as the floor.
  final bool expand;

  const _HorizontalCategoryChart({
    required this.items,
    required this.palette,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final chartH = (items.length * 36.0 + 40.0).clamp(240.0, 520.0);
    final chart = CustomPaint(
      painter: _HorizontalCategoryChartPainter(items, palette),
    );

    if (expand) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: chartH),
        child: SizedBox(width: double.infinity, child: chart),
      );
    }

    return SizedBox(height: chartH, width: double.infinity, child: chart);
  }
}

class _HorizontalCategoryChartPainter extends CustomPainter {
  final List<CategoryQuantityEntity> items;
  final AppPalette palette;

  _HorizontalCategoryChartPainter(this.items, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final sorted = [...items]
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    if (sorted.isEmpty) return;

    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 32.0;

    var leftPad = 64.0;
    for (final e in sorted) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.category,
          style: appText(size: AppTypography.labelSmallSize, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width + 12 > leftPad) leftPad = tp.width + 12;
    }
    leftPad = leftPad.clamp(56.0, 180.0).toDouble();

    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final values = sorted.map((e) => e.totalQuantity.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal <= 0 ? 1.0 : maxVal * 1.1;

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final x = plot.left + (t / ticks) * plot.width;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      final value = chartMax * (t / ticks);
      final tp = TextPainter(
        text: TextSpan(
          text: _formatQuantity(value),
          style: appText(size: AppTypography.labelSmallSize, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 8));
    }

    final n = sorted.length;
    final rowH = plot.height / n;
    final barH = (rowH * 0.6).clamp(6.0, 22.0);
    final barPaint = Paint()..color = AppColors.brandPurple;

    for (var i = 0; i < n; i++) {
      final e = sorted[i];
      final cy = plot.top + rowH * (i + 0.5);
      final barW = (e.totalQuantity / chartMax) * plot.width;

      final lp = TextPainter(
        text: TextSpan(
          text: e.category,
          style: appText(size: AppTypography.labelSmallSize, color: palette.textSecondary),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 8);
      lp.paint(canvas, Offset(plot.left - lp.width - 8, cy - lp.height / 2));

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(plot.left, cy - barH / 2, barW, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);

      final vp = TextPainter(
        text: TextSpan(
          text: _formatQuantity(e.totalQuantity.toDouble()),
          style: appText(
            size: AppTypography.labelSmallSize,
            weight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final vx = (plot.left + barW + 6).clamp(plot.left, plot.right - vp.width);
      if (vx >= plot.left) {
        vp.paint(canvas, Offset(vx, cy - vp.height / 2));
      }
    }
  }

  String _formatQuantity(double value) {
    if (value >= 1000000) {
      return '${_trim(value / 1000000)}M';
    }
    if (value >= 1000) {
      return '${_trim(value / 1000)}k';
    }
    return value.round().toString();
  }

  String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  bool shouldRepaint(covariant _HorizontalCategoryChartPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.palette != palette;
}

/// A category's share of the largest category as an animated, rounded bar on
/// a low-contrast track.
///
/// Used by both the allocation legend and the stock-status rows: in each case
/// the bar compares a part against the largest part (or, for stock, against
/// the whole), and the tween means a refresh animates the bars rather than
/// snapping them.
class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF64748B)),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ sales sparkline painter

/// Smooth sparkline with cubic bezier curve and gradient fill.
/// Violet stroke (#C4B5FD, 2.2px) with vertical gradient fill (#A78BFA → transparent).
class _SalesSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sample data points for the sparkline (normalized 0-1)
    final points = <Offset>[
      Offset(0.0, 0.65),
      Offset(0.08, 0.55),
      Offset(0.16, 0.70),
      Offset(0.24, 0.45),
      Offset(0.32, 0.50),
      Offset(0.40, 0.30),
      Offset(0.48, 0.35),
      Offset(0.56, 0.15),
      Offset(0.64, 0.25),
      Offset(0.72, 0.10),
      Offset(0.80, 0.18),
      Offset(0.88, 0.05),
      Offset(0.96, 0.12),
      Offset(1.0, 0.08),
    ];

    // Scale to canvas size
    final scaledPoints = points.map((p) => Offset(
      p.dx * size.width,
      p.dy * size.height,
    )).toList();

    // Build smooth path with cubic bezier curves
    final path = Path();
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);

    for (var i = 0; i < scaledPoints.length - 1; i++) {
      final p0 = scaledPoints[i];
      final p1 = scaledPoints[i + 1];

      // Control points for smooth curve
      final cp1 = Offset(
        p0.dx + (p1.dx - p0.dx) * 0.4,
        p0.dy,
      );
      final cp2 = Offset(
        p1.dx - (p1.dx - p0.dx) * 0.4,
        p1.dy,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Gradient fill path (close the path at the bottom)
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0x47A78BFA), // #A78BFA with 28% opacity
        const Color(0x00A78BFA), // transparent
      ],
    );

    final fillRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fillPaint = Paint()
      ..shader = gradient.createShader(fillRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw the line stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFC4B5FD) // #C4B5FD
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

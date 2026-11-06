import 'dart:async';

import 'package:dio/dio.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';
import 'package:posfrontend/features/dashboard/domain/entities/dashboard_tables.dart';
import 'package:posfrontend/features/dashboard/presentation/screens/dashboard_table_screen.dart';
import 'package:posfrontend/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:posfrontend/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Which group of sections the header's tab is showing.
///
/// The design puts three tabs in the page header; they are filters over the
/// same dashboard rather than three dashboards, so a tab only decides which
/// cards are on screen. Every card still reads the one payload already
/// loaded — switching tabs costs no request.
enum _DashboardTab { overview, sales, inventory }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardViewModel _viewModel;
  final CancelToken _cancelToken = CancelToken();

  _DashboardTab _tab = _DashboardTab.overview;

  static const Map<_DashboardTab, String> _tabLabels = {
    _DashboardTab.overview: 'Overview',
    _DashboardTab.sales: 'Sales',
    _DashboardTab.inventory: 'Inventory',
  };

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
          const SizedBox(height: 24),
          ..._sections(context, p, _viewModel.data!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context, AppPalette p) {
    // The page's own name stays in the top bar; this heading names the shop
    // the numbers below belong to. Falls back to the page name while the
    // shop is still loading (or when a device has none), so the header is
    // never blank. Reading it through the scope also means the heading
    // repaints itself the moment the shop arrives — no manual refresh.
    final shopName = ShopScope.shopOf(context)?.name.trim() ?? '';
    final heading = shopName.isEmpty
        ? context.l10n.t('Dashboard')
        : shopName;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.t("Here's what's happening with your store today."),
          style: TextStyle(fontSize: 13, color: p.textSecondary),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              _buildTabBar(context, p),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleBlock,
            const SizedBox(height: 16),
            _buildTabBar(context, p),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context, AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in _DashboardTab.values)
            GestureDetector(
              onTap: () => setState(() => _tab = tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _tab == tab ? p.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.t(_tabLabels[tab]!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _tab == tab ? Colors.white : p.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- sections

  /// The cards currently on screen, in the design's order, each followed by
  /// its gap. Tabs drop sections rather than restyle them, so a card is built
  /// exactly the same way on every tab that shows it.
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

    final showSales = _tab != _DashboardTab.inventory;
    final showInventory = _tab != _DashboardTab.sales;

    section(
      _KpiGrid(
        metrics: d.metrics,
        trends: _viewModel.trends,
        sparklines: _viewModel.sparklines,
        trendsLoaded: _viewModel.trendsLoaded,
        onOpenTable: _openSummaryTable,
      ),
    );

    if (showSales) {
      section(
        _equalHeightPair(
          (fill, _) => _monthlySalesCard(context, p, fill: fill),
          (fill, _) => _SalesSummaryCard(
            stats: d.stats,
            trends: _viewModel.trends,
            fill: fill,
          ),
          leftFlex: 2,
        ),
      );
    }

    if (showSales && showInventory) {
      section(
        _equalHeightPair(
          // The pair already knows each card's width, so the allocation card
          // can choose its side-by-side or stacked shape without a nested
          // LayoutBuilder (which IntrinsicHeight cannot measure).
          (fill, width) => _categoryAllocationCard(
            context,
            p,
            d,
            fill: fill,
            bodyWidth: width - 32,
          ),
          (fill, _) => _quantitySoldCard(context, p, d, fill: fill),
        ),
      );
    } else if (showInventory) {
      section(_categoryAllocationCard(context, p, d));
    } else {
      section(_quantitySoldCard(context, p, d));
    }

    final trend = _productTrendCard(context, p, d);
    final stock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StockStatusCard(stats: d.stats),
        const SizedBox(height: 24),
        const _InventoryStockStatusCard(),
      ],
    );
    if (showSales && showInventory) {
      section(_pair(trend, stock));
    } else if (showSales) {
      section(trend);
    } else {
      section(stock);
    }

    if (showInventory) {
      section(_pair(_lowStockPreview(context, p), _notSoldPreview(context, p)));
    }

    final recentSales = _recentSalesPreview(context, p);
    final recentProducts = _recentProductsPreview(context, p);
    if (showSales && showInventory) {
      section(_pair(recentSales, recentProducts));
    } else if (showSales) {
      section(recentSales);
    } else {
      section(recentProducts);
    }

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
              height: 260,
              child: Center(child: Text(context.l10n.t('No sales data'))),
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
      trailing: _ViewAllLink(
        onTap: () => Navigator.of(
          context,
        ).push(DashboardTableScreen.route(spec: DashboardTables.products)),
      ),
      child: items.isEmpty
          ? SizedBox(
              height: 200,
              child: Center(child: Text(context.l10n.t('No category data'))),
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
          donut,
          const SizedBox(width: 20),
          Container(width: 1, height: 200, color: p.border),
          const SizedBox(width: 20),
          Expanded(child: legend),
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
              child: Center(child: Text(context.l10n.t('No sales data'))),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          boxShadow: p.cardElevation,
        ),
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
                          style: TextStyle(
                            fontSize: 12.5,
                            color: p.textSecondary,
                          ),
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
                          child: Text(
                            metric.value,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                              letterSpacing: -0.4,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.cardElevation,
      ),
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ),
          if (title != null) const SizedBox(height: 14),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
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
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: p.textPrimary,
    );

    final rows = [
      _SummaryRowData(
        icon: Icons.attach_money,
        bgValue: 0xFFF3E8FF,
        fgValue: 0xFF7952DB,
        label: 'Total Revenue',
        value: PriceText(stats.totalSales.toDouble(), style: valueStyle),
        trend: trends?.revenue,
      ),
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
        icon: Icons.shopping_cart_outlined,
        bgValue: 0xFFDCFCE7,
        fgValue: 0xFF16A34A,
        label: 'Items Sold',
        value: Text(stats.itemsSold.withCommas(), style: valueStyle),
        trend: trends?.itemsSold,
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
                    style: TextStyle(fontSize: 13, color: p.textSecondary),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 54,
              startDegreeOffset: -90,
              sections: [
                for (final item in items)
                  PieChartSectionData(
                    value: item.productCount.toDouble(),
                    color: Color(item.colorValue),
                    radius: 46,
                    showTitle: false,
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          ),
          SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total.withCommas(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.t('Products'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: palette.textSecondary),
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
            const SizedBox(height: 8),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(items[i].colorValue),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i].category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: p.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  items[i].productCount.withCommas(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: Text(
                  '${percentOf(items[i]).toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
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

/// Demo card for the inventory side of stock.
///
/// The dashboard API only reports product stock, so these figures stand in
/// until inventory amounts are exposed. The shape is the same as the product
/// card, so wiring real data in later only means replacing the rows.
class _InventoryStockStatusCard extends StatelessWidget {
  const _InventoryStockStatusCard();

  static const _total = 120;
  static const _inStock = 86;
  static const _lowStock = 22;
  static const _outStock = 12;

  @override
  Widget build(BuildContext context) {
    return _StockStatusPanel(
      title: context.l10n.t('Inventory Stock Status'),
      total: _total,
      rows: [
        _StockStatusRow(
          icon: Icons.inventory_2_outlined,
          tintValue: 0xFFDCFCE7,
          colorValue: 0xFF16A34A,
          label: 'In Stock',
          count: _inStock,
        ),
        _StockStatusRow(
          icon: Icons.warning_amber_outlined,
          tintValue: 0xFFFEF3C7,
          colorValue: 0xFFF59E0B,
          label: 'Low Stock',
          count: _lowStock,
        ),
        _StockStatusRow(
          icon: Icons.cancel_outlined,
          tintValue: 0xFFFEE2E2,
          colorValue: 0xFFEF4444,
          label: 'Out of Stock',
          count: _outStock,
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
                  width: 86,
                  child: Text(
                    context.l10n.t(rows[i].label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
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
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.sold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textSecondary,
                          ),
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
          ? CachedProductImage(
              url: item.image,
              width: size,
              height: size,
              memCacheWidth: (size * 3).round(),
              errorWidget: Icon(
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
                  style: TextStyle(fontSize: 13, color: p.textMuted),
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
                            style: TextStyle(
                              fontSize: 12.5,
                              color: p.textMuted,
                            ),
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

  static TextStyle _headerStyle(AppPalette p) => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
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
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
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
      style: TextStyle(
        fontSize: 12.5,
        color: p.textPrimary,
        fontWeight: column.kind == TableValueKind.text
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
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          Text(
            context.l10n.t('Simple POS. Greater Business.'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
          style: TextStyle(fontSize: 13, color: p.textSecondary),
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
        constraints: const BoxConstraints(minHeight: 280),
        child: SizedBox(width: double.infinity, child: chart),
      );
    }

    return SizedBox(height: 280, width: double.infinity, child: chart);
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

    const leftPad = 52.0;
    const rightPad = 16.0;
    const topPad = 30.0;
    const bottomPad = 32.0;
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final maxVal = sorted.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal <= 0 ? 1.0 : maxVal * 1.15;

    final gridPaint = Paint()
      ..color = palette.border
      ..strokeWidth = 1;

    // Money scale on the left, with a horizontal rule at each step so a bar's
    // height can be read without a tooltip.
    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final y = plot.bottom - (t / ticks) * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);

      final label = _formatValue(chartMax * (t / ticks));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plot.left - tp.width - 8, y - tp.height / 2));
    }

    // Twelve fixed slots whether or not every month has a sale, so the axis
    // never shifts as data arrives.
    final slotWidth = plot.width / 12;
    final barWidth = (slotWidth * 0.5).clamp(6.0, 40.0);

    for (var m = 0; m < 12; m++) {
      final tp = TextPainter(
        text: TextSpan(
          text: _monthLabels[m],
          style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          plot.left + slotWidth * (m + 0.5) - tp.width / 2,
          plot.bottom + 8,
        ),
      );
    }

    final barPaint = Paint()..color = AppColors.brandPurple;
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
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        barPaint,
      );

      // Value above the bar, dropped when the bar is tall enough that the
      // label would leave the plot — a clipped figure is worse than none.
      final vp = TextPainter(
        text: TextSpan(
          text: _formatValue(entry.total.toDouble()),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = plot.bottom - height - vp.height - 5;
      if (y >= plot.top - 6) {
        vp.paint(canvas, Offset(centreX - vp.width / 2, y));
      }
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
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
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
          style: TextStyle(fontSize: 10, color: palette.textSecondary),
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
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
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
      height: 8,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

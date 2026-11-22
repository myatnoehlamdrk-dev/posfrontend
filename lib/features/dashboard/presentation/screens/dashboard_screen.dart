import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

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
import 'package:posfrontend/features/dashboard/presentation/widgets/dashboard_style.dart';
import 'package:posfrontend/features/dashboard/presentation/widgets/product_row_thumb.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_text.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';
import 'package:posfrontend/shared/widgets/profile_image_notifier.dart';
import 'package:posfrontend/shared/widgets/error_retry_view.dart';
import 'package:posfrontend/shared/widgets/hover_spotlight.dart';
import 'package:posfrontend/shared/widgets/shop_scope.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';
import 'package:posfrontend/features/sale/presentation/screens/quick_sale_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/products_catalog_screen.dart';
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
      backgroundColor: Colors.transparent,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // One soft violet bloom behind the content. It gives the
                  // page depth without competing with the cards.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DashboardStyle.pageGlow(context),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      final gutter = MediaQuery.sizeOf(context).width < 600
                          ? 16.0
                          : 24.0;
                      return RefreshableBody(
                        onRefresh: () => _viewModel.load(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: DashboardStyle.maxContentWidth,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: gutter,
                                vertical: 12,
                              ),
                              child: _buildBody(context, p),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
          const SizedBox(height: 6),
          ..._sections(context, p, _viewModel.data!),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context, AppPalette p) {
    final shopName = ShopScope.shopOf(context)?.name.trim() ?? '';
    final heading = shopName.isEmpty ? context.l10n.t('Dashboard') : shopName;
    final today = MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime.now());

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$today  ·  ${context.l10n.t('Business overview')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appText(
            size: AppTypography.labelSmallSize,
            color: p.textMuted,
          ),
        ),
      ],
    );

    final refreshControl = _viewModel.isLoading
        ? SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.textSecondary,
                ),
              ),
            ),
          )
        : DashboardIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.l10n.t('Refresh'),
            onTap: _viewModel.load,
          );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [refreshControl],
    );

    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    return isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              actions,
            ],
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
    var reveal = 0;

    void add(Widget child, {double gap = DashboardStyle.gap}) {
      out.add(DashboardReveal(index: reveal++, child: child));
      out.add(SizedBox(height: gap));
    }

    void group(String label) {
      out.add(const SizedBox(height: 4));
      out.add(DashboardSectionLabel(label: context.l10n.t(label)));
      out.add(const SizedBox(height: 12));
    }

    // The revenue line is real: the API's daily series when it has one, and
    // otherwise the month-by-month series the summary already carries. The
    // painter handles a missing/one-point series without collapsing the card.
    final revenueSpark =
        _viewModel.sparklines[MetricTrendKey.revenue] ?? const <double>[];
    final revenueSeries = revenueSpark.isNotEmpty
        ? revenueSpark
        : d.monthSummary.revenue.series;

    final monthOrders = d.monthSummary.orders.current;
    final dayOfMonth = DateTime.now().day.clamp(1, 31);
    final ordersPerDay = monthOrders > 0 ? monthOrders / dayOfMonth : 0.0;
    final itemsPerOrder = monthOrders > 0
        ? d.monthSummary.itemsSold.current / monthOrders
        : 0.0;

    // Hero bento.
    add(
      _HeroBentoContainer(
        totalSales: d.stats.totalSales,
        revenueTrend: _viewModel.trends?.revenue,
        revenueSparkline: revenueSeries,
        stats: d.stats,
        itemsSoldTrend: _viewModel.trends?.itemsSold,
        itemsSoldSeries: d.monthSummary.itemsSold.series,
        onRestockTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StockAddScreen())),
        onNewSaleTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QuickSaleScreen())),
      ),
      gap: 28,
    );

    group('Performance');

    add(
      _equalHeightPair(
        (fill, width) => Column(
          children: [
            _SalesKpiCard(
              icon: Icons.receipt_long_rounded,
              iconColor: p.infoFg,
              label: context.l10n.t('Total Orders'),
              value: d.stats.salesCount.withCommas(),
              trend: _viewModel.trends?.orders,
              subtitle: monthOrders > 0
                  ? '${ordersPerDay.toStringAsFixed(1)} '
                        '${context.l10n.t('orders / day')}'
                  : context.l10n.t('No orders yet this month'),
              rightVisual: _LineChartMini(
                values:
                    _viewModel.sparklines[MetricTrendKey.orders] ??
                    const <double>[],
                color: p.infoFg,
              ),
              showVisual: width >= 380,
            ),
            const SizedBox(height: 12),
            _SalesKpiCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: p.accentText,
              label: context.l10n.t('Avg. Order Value'),
              value: 'MMK ${d.stats.avgOrderValue.withCommas()}',
              trend: _viewModel.trends?.avgOrderValue,
              subtitle: monthOrders > 0
                  ? '${itemsPerOrder.toStringAsFixed(2)} '
                        '${context.l10n.t('items / order')}'
                  : null,
              rightVisual: _MiniBarChart(
                values: d.monthSummary.avgOrderValue.series
                    .map((value) => value.round())
                    .toList(),
                color: p.accentText,
              ),
              showVisual: width >= 380,
            ),
            const SizedBox(height: 12),
            _SalesKpiCard(
              icon: Icons.credit_card_rounded,
              iconColor: p.successFg,
              label: context.l10n.t('Top Payment'),
              value: _viewModel.topPayment != null
                  ? '${_viewModel.topPayment!.method} '
                        '${_viewModel.topPayment!.percent.round()}%'
                  : context.l10n.t('No payments yet'),
              trend: null,
              subtitle: (_viewModel.topPayment?.count ?? 0) > 0
                  ? '${_viewModel.topPayment!.count} '
                        '${context.l10n.t('payments')}'
                  : null,
              rightVisual: _PaymentCapsule(
                segments: _viewModel.paymentDistribution,
              ),
              showVisual: width >= 380,
            ),
          ],
        ),
        (fill, width) => _monthlySalesCard(context, p, fill: fill),
        leftFlex: 35,
        rightFlex: 65,
      ),
    );

    group('Inventory');

    add(
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

    group('Products');
    add(
      _pair(_productTrendCard(context, p, d), _quantitySoldCard(context, p, d)),
    );

    group('Needs attention');
    add(_pair(_lowStockPreview(context, p), _notSoldRiskCard(context, p)));

    group('Recent activity');
    add(
      _pair(
        _recentSalesPreview(context, p),
        _recentProductsPreview(context, p),
      ),
    );

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
      // Neutral, not red. Red is reserved for stock problems (low/out of
      // stock); a product simply not selling yet is information, not an alarm.
      _TrendTile(
        title: context.l10n.t('No Sales'),
        tint: p.chipBg,
        titleColor: p.textSecondary,
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
      showThumbnail: true,
      stockPill: true,
      restock: true,
      onViewAll: () => Navigator.of(context).push(
        DashboardTableScreen.route(
          spec: DashboardTables.lowStock,
          query: const {'low': 1},
        ),
      ),
    );
  }

  /// Products that have never sold, plotted as a bubble risk matrix.
  ///
  /// A table of name/price/creator answered "what are these products"; this
  /// card has to answer "which dead stock should I clear first". Days idle and
  /// the stock tied up are the two axes, and severity is encoded twice — the
  /// bubble grows with age and its glow warms from amber to coral as the
  /// product passes 36 and then 45 days without a sale.
  Widget _notSoldRiskCard(BuildContext context, AppPalette p) {
    final page = _viewModel.tablePreviews['productsNotSold'];
    return _PanelCard(
      title: context.l10n.t('Products Not Sold'),
      badgeLabel: context.l10n.t('${page?.rows.length ?? 0}'),
      trailing: _ViewAllLink(
        onTap: () => Navigator.of(
          context,
        ).push(DashboardTableScreen.route(spec: DashboardTables.noBought)),
      ),
      child: !_viewModel.previewsLoaded
          ? const _BubbleRiskSkeleton()
          : page == null || page.rows.isEmpty
          ? SizedBox(
              height: 260,
              child: AppEmptyState(
                title: context.l10n.t('Nothing to show'),
                icon: Icons.scatter_plot_outlined,
              ),
            )
          : _BubbleRiskMatrix(rows: page.rows, palette: p),
    );
  }

  Widget _recentSalesPreview(BuildContext context, AppPalette p) {
    final page = _viewModel.tablePreviews['recentSales'];
    final total = page?.total ?? page?.rows.length ?? 0;
    return _PreviewTableCard(
      title: context.l10n.t('Recent Sales'),
      columns: DashboardTablePreviews.recentSales.columns,
      page: page,
      loaded: _viewModel.previewsLoaded,
      receiptIcon: true,
      badgeLabel: total > 0 ? context.l10n.t('$total sales') : null,
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

  /// Small label in the card header next to the title, e.g. a total or a count.
  final String? badgeLabel;

  const _PanelCard({
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.titlePadding,
    this.fill = false,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return HoverSpotlight(
      radius: BorderRadius.circular(DashboardStyle.cardRadius),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(DashboardStyle.cardRadius),
        border: Border.all(color: p.border),
        boxShadow: DashboardStyle.cardShadow(context),
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
                  if (title != null) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appText(
                              size: 15,
                              weight: FontWeight.w700,
                              color: p.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: 8),
                            _TagChip(label: badgeLabel!),
                          ],
                        ],
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(999),
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

/// Compact KPI card for the Sales Summary column.
class _SalesKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final TrendEntity? trend;
  final String? subtitle;
  final Widget? rightVisual;

  /// Whether the trailing chart fits. Decided by the caller, which already
  /// knows the column width: this card sits under an `IntrinsicHeight` pair,
  /// where a nested `LayoutBuilder` cannot be measured.
  final bool showVisual;

  const _SalesKpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trend,
    this.subtitle,
    this.rightVisual,
    this.showVisual = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final trendColor = switch (trend?.direction) {
      TrendDirection.up => trend!.isBullish ? p.successFg : p.dangerFg,
      TrendDirection.down => trend!.isBearish ? p.dangerFg : p.successFg,
      _ => p.textSecondary,
    };
    final trendIcon = switch (trend?.direction) {
      TrendDirection.up => Icons.arrow_upward_rounded,
      TrendDirection.down => Icons.arrow_downward_rounded,
      _ => Icons.remove_rounded,
    };

    return HoverSpotlight(
      radius: BorderRadius.circular(18),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: DashboardStyle.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(
                    size: AppTypography.labelSmallSize,
                    weight: FontWeight.w500,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style:
                              appText(
                                size: 22,
                                weight: FontWeight.w700,
                                color: p.textPrimary,
                                letterSpacing: -0.4,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(trendIcon, size: 11, color: trendColor),
                            if (trend!.percent != null) ...[
                              const SizedBox(width: 2),
                              Text(
                                '${trend!.percent!.abs().toStringAsFixed(1)}%',
                                style: appText(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: trendColor,
                                ),
                              ),
                            ],
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(size: 11, color: p.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (showVisual && rightVisual != null) ...[
            const SizedBox(width: 12),
            rightVisual!,
          ],
        ],
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
    if (values.isEmpty) return const SizedBox.shrink();
    // The series can be a full year; a KPI tile only has room for the recent
    // shape, so keep the last eight points.
    final shown = values.length > 8
        ? values.sublist(values.length - 8)
        : values;
    final maxVal = shown.reduce((a, b) => a > b ? a : b);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: shown.map((v) {
        final height = maxVal > 0 ? (v / maxVal * 42).clamp(6.0, 42.0) : 6.0;
        return Container(
          width: 9,
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

/// Segmented bar showing the full payment distribution.
class _PaymentCapsule extends StatelessWidget {
  final List<({String method, int count, double percent})> segments;

  const _PaymentCapsule({required this.segments});

  Color _colorFor(String method, AppPalette p) {
    final name = method.toLowerCase();
    if (name.contains('cash')) return p.successFg;
    if (name.contains('kpay')) return p.infoFg;
    if (name.contains('wave')) return p.accentText;
    if (name.contains('other')) return p.textMuted;
    return p.primary;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (segments.isEmpty) {
      return Text(
        context.l10n.t('No payments yet'),
        style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
      );
    }
    final total = segments.fold<int>(0, (sum, s) => sum + s.count);
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Color(0xFF0B0D12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF64748B)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: segment.count > 0 ? segment.count : 1,
                      child: Container(color: _colorFor(segment.method, p)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final segment in segments)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _colorFor(segment.method, p),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${segment.method} ${segment.percent.toStringAsFixed(0)}%',
                      style: appText(
                        size: 10,
                        weight: FontWeight.w600,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$total ${context.l10n.t('payments')}',
              style: appText(size: 10, color: p.textMuted),
            ),
          ],
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
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      width: 112,
      height: 44,
      child: CustomPaint(painter: _LineChartPainter(values, color)),
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
      colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
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

    // Peak value label, kept inside the chart bounds so a large peak can never
    // push the annotation off-canvas.
    final valueText = 'Peak: ${values[peakIndex].round()}';
    final tp = TextPainter(
      text: TextSpan(
        text: valueText,
        style: appText(size: 8, weight: FontWeight.w700, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (peakX - tp.width / 2).clamp(0.0, size.width - tp.width);
    var labelY = peakY - tp.height - 6;
    labelY = labelY.clamp(0.0, size.height - tp.height - 4);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX - 3, labelY - 2, tp.width + 6, tp.height + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      labelRect,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      labelRect,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    tp.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

// ============================================================ hero bento container

/// Unified Hero Bento Container: single large rounded container split 40/60.
/// Left = Total Sales hero with gradient. Right = 3 nested metric cards.
class _HeroBentoContainer extends StatelessWidget {
  final int totalSales;
  final TrendEntity? revenueTrend;
  final List<double> revenueSparkline;
  final DashboardStatsEntity stats;
  final TrendEntity? itemsSoldTrend;
  final List<double> itemsSoldSeries;
  final VoidCallback onRestockTap;

  /// Floating "New Sale" action for the Total Sales hero, pinned top-right.
  final VoidCallback? onNewSaleTap;

  const _HeroBentoContainer({
    required this.totalSales,
    required this.revenueTrend,
    required this.revenueSparkline,
    required this.stats,
    required this.itemsSoldTrend,
    required this.itemsSoldSeries,
    required this.onRestockTap,
    this.onNewSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return HoverSpotlight(
      radius: BorderRadius.circular(DashboardStyle.cardRadius),
      child: Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(DashboardStyle.cardRadius),
        border: Border.all(color: p.border),
        boxShadow: DashboardStyle.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = _HeroLeftSection(
            totalSales: totalSales,
            trend: revenueTrend,
            sparkline: revenueSparkline,
            onNewSaleTap: onNewSaleTap,
          );
          final stacked = constraints.maxWidth < 860;
          final rightWidth = stacked
              ? constraints.maxWidth
              : (constraints.maxWidth - 1) * (58 / 100);
          final right = _HeroRightSection(
            stats: stats,
            itemsSoldTrend: itemsSoldTrend,
            itemsSoldSeries: itemsSoldSeries,
            onRestockTap: onRestockTap,
            // The three cards decide for themselves between a row and a stack
            // from the width they were actually given — no nested LayoutBuilder,
            // which cannot live under an IntrinsicHeight.
            compact: rightWidth < 560,
            stretch: !stacked,
          );

          // Stacked below the two-column breakpoint rather than squeezing the
          // three metric cards into a phone's width.
          if (stacked) {
            return Column(
              children: [
                left,
                Divider(height: 1, color: p.border),
                right,
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 42, child: left),
                Container(width: 1, color: p.border),
                Expanded(flex: 58, child: right),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Left section: Total Sales hero with a palette-aware violet wash.
class _HeroLeftSection extends StatelessWidget {
  final int totalSales;
  final TrendEntity? trend;
  final List<double> sparkline;

  /// Floating "New Sale" action pinned to the top-right of the hero.
  final VoidCallback? onNewSaleTap;

  const _HeroLeftSection({
    required this.totalSales,
    required this.trend,
    required this.sparkline,
    this.onNewSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    final newSaleTap = onNewSaleTap;
    final p = context.palette;
    final change = trend?.percent;
    final good = trend?.isBullish ?? true;
    final trendColor = good ? p.successFg : p.dangerFg;
    final trendIcon = switch (trend?.direction) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      _ => Icons.trending_flat_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: DashboardStyle.heroGradient(context)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A soft bloom in the corner. Painted, not blurred, so it costs one
          // radial gradient instead of a saveLayer.
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.primary.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.35
                            : 0.16,
                      ),
                      p.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.t('Total Sales'),
                    style: appText(
                      size: AppTypography.labelMediumSize,
                      weight: FontWeight.w600,
                      color: p.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style:
                        appText(
                          size: 38,
                          weight: FontWeight.w800,
                          color: p.textPrimary,
                          height: 1.05,
                          letterSpacing: -1,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                    children: [
                      TextSpan(
                        text: 'MMK ',
                        style:
                            appText(
                              size: 18,
                              weight: FontWeight.w600,
                              color: p.textSecondary,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      TextSpan(text: totalSales.withCommas()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: trendColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 13, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        '${trend!.direction == TrendDirection.down ? '−' : '+'}'
                        '${change.abs().toStringAsFixed(1)}% '
                        '${context.l10n.t('vs last month')}',
                        style: appText(
                          size: AppTypography.labelSmallSize,
                          weight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                height: 66,
                width: double.infinity,
                child: ChartReveal(
                  grow: true,
                  duration: const Duration(milliseconds: 800),
                  child: _HeroSparkline(values: sparkline, trend: trend),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${context.l10n.t('Revenue trend')} · '
                '${context.l10n.t('last 12 months')}',
                style: appText(
                  size: 11,
                  weight: FontWeight.w500,
                  color: p.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          if (newSaleTap != null)
            Positioned(
              top: 24,
              right: 24,
              child: _HeroNewSaleButton(onTap: newSaleTap),
            ),
        ],
      ),
    );
  }
}

/// Floating "New Sale" pill anchored to the hero card's top-right corner.
class _HeroNewSaleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroNewSaleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: p.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'New Sale',
                style: appText(
                  size: AppTypography.labelMediumSize,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "View details" action row used inside the hero's nested metric cards,
/// styled like the Out of Stock card's Restock link.
class _HeroCardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroCardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: appText(
                size: AppTypography.labelSmallSize,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// Right section: three nested metric cards.
class _HeroRightSection extends StatelessWidget {
  final DashboardStatsEntity stats;
  final TrendEntity? itemsSoldTrend;
  final List<double> itemsSoldSeries;
  final VoidCallback onRestockTap;

  /// Stack the three cards instead of laying them out in a row.
  final bool compact;

  /// When true the parent will stretch the section to the row's height, so the
  /// row can use `crossAxisAlignment: stretch`. In stacked mode the cards size
  /// themselves, so the row falls back to their natural heights.
  final bool stretch;

  const _HeroRightSection({
    required this.stats,
    required this.itemsSoldTrend,
    required this.itemsSoldSeries,
    required this.onRestockTap,
    this.compact = false,
    this.stretch = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final outPercent = stats.totalProducts > 0
        ? (stats.outStock / stats.totalProducts).clamp(0.0, 1.0)
        : 0.0;
    final itemsChange = itemsSoldTrend?.percent;

    final cards = <Widget>[
      _NestedMetricCard(
        label: context.l10n.t('Total Products'),
        value: stats.totalProducts.withCommas(),
        badge: stats.lowStock > 0
            ? '${stats.lowStock} ${context.l10n.t('low')}'
            : null,
        badgeColor: stats.lowStock > 0 ? p.warningFg : null,
        action: _HeroCardAction(
          label: context.l10n.t('View products'),
          icon: Icons.inventory_2_outlined,
          color: p.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductsCatalogScreen()),
          ),
        ),
        child: _StockLevelBar(stats: stats),
      ),
      _NestedMetricCard(
        label: context.l10n.t('Total Items Sold'),
        value: stats.totalItemsSold.withCommas(),
        badge: itemsChange != null
            ? '${itemsSoldTrend!.direction == TrendDirection.down ? '−' : '+'}'
                  '${itemsChange.abs().toStringAsFixed(1)}%'
            : null,
        badgeColor: itemsChange == null
            ? null
            : (itemsSoldTrend!.isBullish ? p.successFg : p.dangerFg),
        action: _HeroCardAction(
          label: context.l10n.t('View sales'),
          icon: Icons.receipt_long_outlined,
          color: p.infoFg,
          onTap: () => Navigator.of(
            context,
          ).push(DashboardTableScreen.route(spec: DashboardTables.sales)),
        ),
        child: SizedBox(
          height: 30,
          width: double.infinity,
          child: itemsSoldSeries.length > 1
              ? CustomPaint(
                  painter: _SparklinePainter(itemsSoldSeries, p.accentText),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.t('No history yet'),
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      color: p.textMuted,
                    ),
                  ),
                ),
        ),
      ),
      _NestedMetricCard(
        label: context.l10n.t('Out of Stock Alerts'),
        value: '${stats.outStock} ${context.l10n.t('items')}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircularProgressRing(
              progress: outPercent,
              color: p.dangerFg,
              label:
                  '${(outPercent * 100).round()}% '
                  '${context.l10n.t('out')}',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRestockTap,
              style: TextButton.styleFrom(
                foregroundColor: p.dangerFg,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.t('Restock'),
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      weight: FontWeight.w600,
                      color: p.dangerFg,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: p.dangerFg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    final row = Row(
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ],
    );
    final body = compact
        ? Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          )
        : stretch
        ? row
        : IntrinsicHeight(child: row);

    return Padding(padding: const EdgeInsets.all(16), child: body);
  }
}

/// Reusable nested metric card. Reads the theme so it is a quiet inner surface
/// in light mode instead of a dark island inside a white card.
class _NestedMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;
  final String? badge;
  final Color? badgeColor;

  /// Optional action under the body — e.g. "View details", styled like the
  /// Out of Stock card's Restock link.
  final Widget? action;

  const _NestedMetricCard({
    required this.label,
    required this.value,
    required this.child,
    this.badge,
    this.badgeColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return HoverSpotlight(
      radius: BorderRadius.circular(AppRadius.lg),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appText(
                    size: AppTypography.labelSmallSize,
                    weight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ),
              if (badge != null && badgeColor != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor!.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: badgeColor!.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: appText(
                      size: 10,
                      weight: FontWeight.w600,
                      color: badgeColor!,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: appText(
                size: 30,
                weight: FontWeight.w700,
                color: p.textPrimary,
                height: 1.05,
                letterSpacing: -0.6,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
      ),
    );
  }
}

/// Horizontal segmented stock-level bar with legend, driven by real counts.
class _StockLevelBar extends StatelessWidget {
  final DashboardStatsEntity stats;

  const _StockLevelBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = stats.inStock + stats.lowStock + stats.outStock;
    if (total == 0) {
      return Text(
        context.l10n.t('No stock yet'),
        style: appText(size: AppTypography.labelSmallSize, color: p.textMuted),
      );
    }

    Widget segment(int value, Color color) {
      return Expanded(
        flex: value,
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (stats.inStock > 0) segment(stats.inStock, p.successFg),
            if (stats.inStock > 0 && (stats.lowStock > 0 || stats.outStock > 0))
              const SizedBox(width: 2),
            if (stats.lowStock > 0) segment(stats.lowStock, p.warningFg),
            if (stats.lowStock > 0 && stats.outStock > 0)
              const SizedBox(width: 2),
            if (stats.outStock > 0) segment(stats.outStock, p.dangerFg),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            _LegendDot(
              color: p.successFg,
              label: context.l10n.t('In'),
              count: stats.inStock,
            ),
            _LegendDot(
              color: p.warningFg,
              label: context.l10n.t('Low'),
              count: stats.lowStock,
            ),
            _LegendDot(
              color: p.dangerFg,
              label: context.l10n.t('Out'),
              count: stats.outStock,
            ),
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

  const _LegendDot({
    required this.color,
    required this.label,
    required this.count,
  });

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
          style: appText(
            size: AppTypography.labelSmallSize,
            color: p.textMuted,
          ),
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
                child: CustomPaint(
                  painter: _GradientProgressRingPainter(
                    progress: progress.clamp(0.0, 1.0),
                    color: ringColor,
                  ),
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

/// Progress ring with a soft gradient arc and a glow — a step up from the flat
/// `CircularProgressIndicator`, which has no gradient and no halo.
class _GradientProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GradientProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;
    final clamped = progress.clamp(0.0, 1.0);

    final arc = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color, color.withValues(alpha: 0.55)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * clamped,
      false,
      arc,
    );

    // Soft halo behind the arc so the ring reads as alive, not flat.
    final glow = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * clamped,
      false,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Larger sparkline for the hero card — full width, taller, with area fill.
/// Larger sparkline for the hero card — full width, taller, with area fill.
///
/// The renderer, not the data, owns the shape: it normalizes into the box,
/// downsamples a long series, smooths without overshooting, and draws a flat
/// line when there is not enough history. A real daily series can therefore
/// never collapse the card the way a raw plot would.
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

    return SizedBox.expand(
      child: CustomPaint(painter: _HeroSparklinePainter(values, color, p)),
    );
  }
}

class _HeroSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final AppPalette palette;

  _HeroSparklinePainter(this.values, this.color, this.palette);

  /// Keep the line readable at card width. A 90-day series squeezed into
  /// 300px is a smear, so it is resampled to at most this many points.
  static const int _maxPoints = 36;

  List<double> _sample() {
    if (values.length <= _maxPoints) return values;
    final step = (values.length - 1) / (_maxPoints - 1);
    return [
      for (var i = 0; i < _maxPoints; i++)
        values[(i * step).round().clamp(0, values.length - 1)],
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const pad = 6.0;
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;
    if (width <= 0 || height <= 0) return;

    final points = _sample();
    final hasShape = points.length > 1;

    // A flat series — including the no-history case — sits on the middle
    // baseline instead of pinning itself to an edge.
    var min = points.isEmpty ? 0.0 : points.first;
    var max = min;
    for (final v in points) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = max - min;
    final flat = !hasShape || span.abs() < 1e-6;

    Offset pointAt(int i) {
      if (flat) {
        return Offset(
          pad + width * i / (points.length <= 1 ? 1 : points.length - 1),
          pad + height * 0.55,
        );
      }
      final x = pad + width * i / (points.length - 1);
      final y = pad + height * (1 - (points[i] - min) / span);
      return Offset(x, y);
    }

    final count = points.isEmpty ? 2 : points.length;
    final first = pointAt(0);
    final path = Path()..moveTo(first.dx, first.dy);

    if (hasShape && !flat) {
      // Quadratic smoothing through segment midpoints: the control points are
      // the data points themselves, so the curve stays inside the series's
      // vertical range and never dips below its own baseline.
      var previous = first;
      for (var i = 1; i < count; i++) {
        final current = pointAt(i);
        final mid = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
        previous = current;
        if (i == count - 1) path.lineTo(current.dx, current.dy);
      }
    } else {
      final last = pointAt(count - 1);
      path.lineTo(last.dx, last.dy);
    }

    // Area fill.
    final areaPath = Path.from(path)
      ..lineTo(pad + width, pad + height)
      ..lineTo(pad, pad + height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: flat ? 0.08 : 0.22),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Only the latest point gets a marker; a dot on every point turns the
    // line into a beaded chain.
    final lastPoint = pointAt(count - 1);
    canvas.drawCircle(lastPoint, 4, Paint()..color = color);
    canvas.drawCircle(lastPoint, 1.8, Paint()..color = palette.surface);
  }

  @override
  bool shouldRepaint(covariant _HeroSparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.palette != palette;
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

class _CategoryDonut extends StatefulWidget {
  final List<CategoryDistributionEntity> items;
  final int total;
  final AppPalette palette;

  const _CategoryDonut({
    required this.items,
    required this.total,
    required this.palette,
  });

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return ChartReveal(
      child: SizedBox(
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
                pieTouchData: PieTouchData(
                  touchCallback: (_, PieTouchResponse? response) {
                    setState(
                      () => _touchedIndex =
                          response?.touchedSection?.touchedSectionIndex,
                    );
                  },
                ),
                sections: [
                  for (var i = 0; i < widget.items.length; i++)
                    PieChartSectionData(
                      value: widget.items[i].productCount.toDouble(),
                      color: Color(widget.items[i].colorValue),
                      radius: _touchedIndex == i ? 62 : 56,
                      showTitle: false,
                      borderSide: _touchedIndex == i
                          ? BorderSide(color: Colors.white, width: 2)
                          : BorderSide.none,
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
                    widget.total.withCommas(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: appText(
                      size: 26,
                      weight: FontWeight.w700,
                      color: p.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.t('Products'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  style: appText(
                    size: AppTypography.labelSmallSize,
                    color: p.textSecondary,
                  ),
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

/// Package-level stock, read from the dashboard API.
///
/// Each active package's stock is the summed available stock of the products
/// assigned to it. The API buckets them into in-stock / low / out, so the rows
/// here are real figures — nothing is generated on the client.

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
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              context.l10n.t('Nothing to show'),
              style: appText(
                size: AppTypography.labelSmallSize,
                color: p.textSecondary,
              ),
            ),
          for (final item in items)
            Padding(
              key: ValueKey(item.name),
              padding: const EdgeInsets.only(bottom: 6),
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
                          style: appText(
                            size: AppTypography.labelSmallSize,
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
          ? Image.network(
              item.image,
              key: ValueKey(item.image),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(item.icon, size: size * 0.5, color: p.textSecondary),
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

  /// Replaces the leading row number with each product's photo.
  final bool showThumbnail;

  /// Renders the stock cell as a severity pill instead of a status dot.
  /// Low Stock Items uses this; the lighter product tables use the dot.
  final bool stockPill;

  /// Adds a subtle Restock action at the end of each row. Low Stock Items.
  final bool restock;

  /// Adds a small receipt icon at the right edge of each row. Recent Sales.
  final bool receiptIcon;

  /// Small label in the card header next to the title, e.g. a total or a count.
  final String? badgeLabel;

  /// Horizontal inset for the header and row stripes, matching the card's
  /// normal padding while the stripes themselves run edge to edge.
  static const double _inset = 16;

  const _PreviewTableCard({
    required this.title,
    required this.columns,
    required this.page,
    required this.loaded,
    required this.onViewAll,
    this.showThumbnail = false,
    this.stockPill = false,
    this.restock = false,
    this.receiptIcon = false,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = page?.rows ?? const <DashboardTableRow>[];

    return _PanelCard(
      title: title,
      trailing: _ViewAllLink(onTap: onViewAll),
      badgeLabel: badgeLabel,
      padding: EdgeInsets.zero,
      titlePadding: const EdgeInsets.fromLTRB(_inset, 16, _inset, 0),
      child: !loaded
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: _inset),
              child: _PreviewTableSkeleton(
                columns: columns,
                showThumbnail: showThumbnail,
              ),
            )
          : rows.isEmpty
          ? SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  context.l10n.t('Nothing to show'),
                  style: appText(
                    size: AppTypography.labelMediumSize,
                    color: p.textMuted,
                  ),
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
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _numberCell(
                        context,
                        p,
                        showThumbnail
                            ? Icon(
                                Icons.photo_outlined,
                                size: 14,
                                color: p.textSecondary,
                              )
                            : Text(
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
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _numberCell(
                          context,
                          p,
                          showThumbnail
                              ? ProductRowThumb(
                                  url: rows[i].text('image'),
                                  size: 28,
                                )
                              : Text(
                                  (i + 1).toString(),
                                  maxLines: 1,
                                  style: appText(
                                    size: AppTypography.labelMediumSize,
                                    color: p.textMuted,
                                  ),
                                ),
                        ),
                        for (final column in columns)
                          _flexCell(
                            column,
                            _value(context, p, column, rows[i]),
                          ),
                        if (restock) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: rows[i].id),
                              ),
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.t('Restock'),
                                    style: appText(
                                      size: AppTypography.labelSmallSize,
                                      weight: FontWeight.w600,
                                      color: p.successFg,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 12,
                                    color: p.successFg,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (receiptIcon) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 14,
                            color: p.textMuted,
                          ),
                        ],
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

  /// The leading cell. Fixed flex so the numbers or photos sit above their
  /// column on every row and every card. A photo needs a slightly wider slot
  /// than a one- or two-digit row number.
  Widget _numberCell(BuildContext context, AppPalette p, Widget child) =>
      Expanded(
        flex: showThumbnail ? 34 : 30,
        child: Padding(
          padding: EdgeInsets.only(right: showThumbnail ? 4 : 8),
          child: child,
        ),
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

    Widget content;

    if (column.jsonKey == 'pay_method') {
      final method = row.text('pay_method');
      final emerald = method == 'Cash';
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: emerald ? p.successBg : p.chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: emerald ? p.successFg.withValues(alpha: 0.4) : p.border,
          ),
        ),
        child: Text(
          method,
          style: appText(
            size: AppTypography.labelSmallSize,
            weight: FontWeight.w600,
            color: emerald ? p.successFg : p.textSecondary,
          ),
        ),
      );
    } else if (column.jsonKey == 'category') {
      final category = row.text('category');
      if (category.isEmpty) {
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: p.chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.border),
          ),
          child: Text(
            context.l10n.t('Uncategorized'),
            style: appText(
              size: AppTypography.labelSmallSize,
              weight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
        );
      } else {
        content = Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appText(
            size: AppTypography.labelSmallSize,
            color: p.textSecondary,
            weight: FontWeight.w600,
          ),
        );
      }
    } else if (column.jsonKey == 'stock') {
      final stock = row.integer('stock');
      if (stockPill) {
        Color pillBg;
        Color pillFg;
        if (stock <= 1) {
          pillBg = p.dangerBg;
          pillFg = p.dangerFg;
        } else if (stock <= 3) {
          pillBg = p.warningBg;
          pillFg = p.warningFg;
        } else {
          pillBg = p.chipBg;
          pillFg = p.textSecondary;
        }
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: pillBg),
          ),
          child: Text(
            '$stock left',
            style: appText(
              size: AppTypography.labelSmallSize,
              weight: FontWeight.w600,
              color: pillFg,
            ),
          ),
        );
      } else {
        final low = stock <= 5;
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: low ? p.warningFg : p.successFg,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$stock',
              style: appText(
                size: AppTypography.labelMediumSize,
                color: p.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ],
        );
      }
    } else {
      content = Text(
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

    return content;
  }
}

// =========================================================== bubble risk matrix

/// One unsold product in the risk matrix.
class _RiskPoint {
  final String name;
  final int days;
  final int stock;
  final Color color;
  final double radius;

  /// Strength of the outer glow. Warmed up as the product crosses 36 and 45
  /// days without a sale.
  final double glow;

  const _RiskPoint({
    required this.name,
    required this.days,
    required this.stock,
    required this.color,
    required this.radius,
    required this.glow,
  });
}

/// Dead stock as a bubble scatter: days idle across, stock amount up, bubble
/// size and glow for severity.
///
/// A row is one product. Days idle is read from the API (`days_idle`, falling
/// back to `created_at` for an older backend) and the stock amount is the
/// product's available stock at the time the card loaded. Bubbles stay inside
/// the 0–60 day / 0–30 unit frame; a larger stock still prints its real figure
/// in the direct label so clamping the plot never hides the number.
class _BubbleRiskMatrix extends StatefulWidget {
  final List<DashboardTableRow> rows;
  final AppPalette palette;

  static const double _height = 272;

  const _BubbleRiskMatrix({required this.rows, required this.palette});

  @override
  State<_BubbleRiskMatrix> createState() => _BubbleRiskMatrixState();
}

class _BubbleRiskMatrixState extends State<_BubbleRiskMatrix> {
  _RiskPoint? _hover;

  Rect _plotRect(Size size) =>
      Rect.fromLTRB(46, 18, size.width - 16, size.height - 40);

  Offset _centre(
    _RiskPoint point,
    Rect plot,
    double maxStockAxis,
    double maxDaysAxis, {
    double jitter = 0,
  }) {
    var cx =
        plot.left +
        (point.days.clamp(0, maxDaysAxis) / maxDaysAxis) * plot.width;
    var cy =
        plot.bottom -
        (point.stock.clamp(0, maxStockAxis) / maxStockAxis) * plot.height;
    final maxR = 26.0;
    cx = cx.clamp(plot.left + maxR, plot.right - maxR).toDouble();
    cy = cy.clamp(plot.top + maxR, plot.bottom - maxR).toDouble();
    return Offset(cx + jitter, cy + jitter);
  }

  _RiskPoint? _nearest(
    Offset local,
    List<_RiskPoint> points,
    Rect plot,
    double maxStockAxis,
    double maxDaysAxis,
  ) {
    _RiskPoint? best;
    var bestDistance = double.infinity;
    for (final point in points) {
      final centre = _centre(point, plot, maxStockAxis, maxDaysAxis);
      final distance = (centre - local).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = point;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final points = <_RiskPoint>[];
    final now = DateTime.now();

    for (final row in widget.rows) {
      var days = row.integer('days_idle');
      if (row.data['days_idle'] == null) {
        final created = DateTime.tryParse(row.text('created_at'));
        if (created != null) {
          days = now.difference(created.toLocal()).inDays;
        }
      }
      if (days < 0) days = 0;

      final stock = row.integer('stock');
      final plotStock = stock.clamp(0, 30);
      final severity = days >= 45 ? 2 : (days >= 36 ? 1 : 0);
      final color = switch (severity) {
        2 => palette.dangerFg,
        1 => palette.warningFg,
        _ => palette.warningFg.withValues(alpha: 0.45),
      };

      points.add(
        _RiskPoint(
          name: row.text('name'),
          days: days,
          stock: stock,
          color: color,
          radius: (8 + (plotStock / 30) * 16).clamp(8, 24).toDouble(),
          glow: severity == 2
              ? 0.55
              : severity == 1
              ? 0.4
              : 0.25,
        ),
      );
    }

    double maxStockAxis = 0;
    if (points.isNotEmpty) {
      maxStockAxis = points
          .map((p) => p.stock.toDouble())
          .reduce((a, b) => a > b ? a : b);
    }
    final stockAxisMax = math.max(10.0, (maxStockAxis * 1.2).ceil().toDouble());

    double maxDaysAxis = 0;
    if (points.isNotEmpty) {
      maxDaysAxis = points
          .map((p) => p.days.toDouble())
          .reduce((a, b) => a > b ? a : b);
    }
    final daysAxisMax = maxDaysAxis + 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, _BubbleRiskMatrix._height);
            final plot = _plotRect(size);
            return Listener(
              onPointerMove: (PointerMoveEvent event) {
                if (event.kind != PointerDeviceKind.mouse) return;
                final box = context.findRenderObject() as RenderBox?;
                if (box == null || !box.hasSize) return;
                final local = box.globalToLocal(event.position);
                final hovered = _nearest(
                  local,
                  points,
                  plot,
                  stockAxisMax,
                  daysAxisMax,
                );
                if (_hover != hovered) {
                  setState(() => _hover = hovered);
                }
              },
              onPointerUp: (PointerUpEvent event) {
                if (event.kind == PointerDeviceKind.mouse) {
                  setState(() => _hover = null);
                }
              },
              child: SizedBox(
                height: _BubbleRiskMatrix._height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BubbleRiskPainter(
                    points: points,
                    palette: palette,
                    daysTitle: context.l10n.t('Days idle'),
                    stockTitle: context.l10n.t('Stock'),
                    maxStockAxis: stockAxisMax,
                    maxDaysAxis: daysAxisMax,
                    hovered: _hover,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        _BubbleRiskLegend(palette: palette),
      ],
    );
  }
}

class _BubbleRiskPainter extends CustomPainter {
  final List<_RiskPoint> points;
  final AppPalette palette;
  final String daysTitle;
  final String stockTitle;
  final double maxStockAxis;
  final double maxDaysAxis;
  final _RiskPoint? hovered;

  const _BubbleRiskPainter({
    required this.points,
    required this.palette,
    required this.daysTitle,
    required this.stockTitle,
    required this.maxStockAxis,
    required this.maxDaysAxis,
    required this.hovered,
  });

  static const double _maxRadius = 26;

  Offset _centre(
    _RiskPoint point,
    Rect plot,
    double maxStockAxis,
    double maxDaysAxis, {
    double jitter = 0,
  }) {
    var cx =
        plot.left +
        (point.days.clamp(0, maxDaysAxis) / maxDaysAxis) * plot.width;
    var cy =
        plot.bottom -
        (point.stock.clamp(0, maxStockAxis) / maxStockAxis) * plot.height;
    final maxR = _maxRadius;
    cx = cx.clamp(plot.left + maxR, plot.right - maxR).toDouble();
    cy = cy.clamp(plot.top + maxR, plot.bottom - maxR).toDouble();
    return Offset(cx + jitter, cy + jitter);
  }

  TextPainter _label(
    String text, {
    required Color color,
    double size = 10,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: appText(size: size, weight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(46, 18, size.width - 16, size.height - 40);
    if (plot.width <= 40 || plot.height <= 40) return;

    final gridPaint = Paint()
      ..color = palette.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    // Stock ticks: 0, 15, 30, 45, 60.
    for (var value = 0; value <= 60; value += 15) {
      final y = plot.bottom - (value / maxStockAxis) * plot.height;
      if (y < plot.top) break;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final tp = _label(value.toString(), color: palette.textMuted);
      tp.paint(canvas, Offset(plot.left - 8 - tp.width, y - tp.height / 2));
    }

    // Days idle ticks: 0d, 30d, 60d, 90d.
    for (var value = 0; value <= 90; value += 30) {
      final x = plot.left + (value / maxDaysAxis) * plot.width;
      if (x > plot.right) break;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      final tp = _label('${value}d', color: palette.textMuted);
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 7));
    }

    final midPaint = Paint()
      ..color = palette.borderStrong.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(plot.left + plot.width / 2, plot.top),
      Offset(plot.left + plot.width / 2, plot.bottom),
      midPaint,
    );
    canvas.drawLine(
      Offset(plot.left, plot.top + plot.height / 2),
      Offset(plot.right, plot.top + plot.height / 2),
      midPaint,
    );

    final axisPaint = Paint()
      ..color = palette.borderStrong.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    _paintAxisTitles(canvas, size, plot);

    final bubbleRects = <Rect>[
      for (var i = 0; i < points.length; i++)
        Rect.fromCircle(
          center: _centre(points[i], plot, maxStockAxis, maxDaysAxis),
          radius: points[i].radius + 3,
        ),
    ];

    final centres = <Offset>[
      for (final point in points)
        _centre(point, plot, maxStockAxis, maxDaysAxis),
    ];

    final seen = <String, int>{};
    final jitterByIndex = <int, double>{};
    for (var i = 0; i < points.length; i++) {
      final key = '${points[i].days}_${points[i].stock}';
      final count = seen[key] ?? 0;
      seen[key] = count + 1;
      if (count > 0) {
        jitterByIndex[i] = (count % 2 == 0 ? -7.0 : 7.0);
      }
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final centre = _centre(
        point,
        plot,
        maxStockAxis,
        maxDaysAxis,
        jitter: jitterByIndex[i] ?? 0,
      );

      canvas.drawCircle(
        centre,
        point.radius + 2,
        Paint()
          ..color = point.color.withValues(alpha: point.glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawCircle(
        centre,
        point.radius,
        Paint()..color = point.color.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        centre,
        point.radius,
        Paint()
          ..color = point.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    _paintDirectLabels(
      canvas,
      plot,
      points,
      centres,
      bubbleRects,
      maxStockAxis,
      maxDaysAxis,
    );

    if (hovered != null) {
      _paintHoverTooltip(canvas, plot, hovered, maxStockAxis, maxDaysAxis);
    }
  }

  void _paintAxisTitles(Canvas canvas, Size size, Rect plot) {
    final xTitle = _label(
      daysTitle,
      color: palette.textSecondary,
      size: 10.5,
      weight: FontWeight.w600,
    );
    xTitle.paint(
      canvas,
      Offset(plot.center.dx - xTitle.width / 2, size.height - 14),
    );

    final yTitle = _label(
      stockTitle,
      color: palette.textSecondary,
      size: 10.5,
      weight: FontWeight.w600,
    );
    canvas.save();
    canvas.translate(11, plot.center.dy);
    canvas.rotate(-math.pi / 2);
    yTitle.paint(canvas, Offset(-yTitle.width / 2, -yTitle.height / 2));
    canvas.restore();
  }

  void _paintDirectLabels(
    Canvas canvas,
    Rect plot,
    List<_RiskPoint> points,
    List<Offset> centres,
    List<Rect> bubbleRects,
    double maxStockAxis,
    double maxDaysAxis,
  ) {
    final orderedIndices = List<int>.generate(points.length, (i) => i)
      ..sort((a, b) => centres[a].dy.compareTo(centres[b].dy));

    var topRiskIndex = -1;
    for (var i = 0; i < points.length; i++) {
      if (topRiskIndex < 0 || points[i].days > points[topRiskIndex].days) {
        topRiskIndex = i;
      }
    }

    final placed = <Rect>[];
    for (final index in orderedIndices) {
      final point = points[index];
      final centre = centres[index];
      final tp = TextPainter(
        text: TextSpan(
          text: '${point.name} (${point.days}d · ${point.stock})',
          style: appText(
            size: 10.2,
            weight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 176);

      final width = tp.width;
      final height = tp.height;
      final left = (centre.dx - width / 2)
          .clamp(plot.left, math.max(plot.left, plot.right - width))
          .toDouble();

      final above = Rect.fromLTWH(
        left,
        centre.dy - point.radius - 6 - height,
        width,
        height,
      );
      final below = Rect.fromLTWH(
        left,
        centre.dy + point.radius + 6,
        width,
        height,
      );

      bool collides(Rect rect) =>
          placed.any(rect.overlaps) ||
          bubbleRects.any((bubble) => bubble.overlaps(rect));

      Rect chosen = above;
      bool free = above.top >= plot.top && !collides(above);
      if (!free) {
        chosen = below;
        free = below.bottom <= plot.bottom && !collides(below);
      }

      final shouldDraw =
          free || index == topRiskIndex || identical(point, hovered);
      if (shouldDraw) {
        final clamped = Rect.fromLTWH(
          chosen.left
              .clamp(plot.left, math.max(plot.left, plot.right - chosen.width))
              .toDouble(),
          chosen.top
              .clamp(plot.top, math.max(plot.top, plot.bottom - chosen.height))
              .toDouble(),
          chosen.width,
          chosen.height,
        );
        placed.add(clamped);
        tp.paint(canvas, Offset(clamped.left, clamped.top));
      }
    }
  }

  void _paintHoverTooltip(
    Canvas canvas,
    Rect plot,
    _RiskPoint? hovered,
    double maxStockAxis,
    double maxDaysAxis,
  ) {
    if (hovered == null) return;
    final centre = _centre(hovered, plot, maxStockAxis, maxDaysAxis);
    final tp = TextPainter(
      text: TextSpan(
        text: '${hovered.name} (${hovered.days}d · ${hovered.stock})',
        style: appText(
          size: 10.2,
          weight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 176);

    final width = tp.width;
    final height = tp.height;
    final left = (centre.dx - width / 2)
        .clamp(plot.left, math.max(plot.left, plot.right - width))
        .toDouble();
    var top = centre.dy - hovered.radius - 8 - height;
    if (top < plot.top) {
      top = centre.dy + hovered.radius + 8;
    }
    top = top
        .clamp(plot.top, math.max(plot.top, plot.bottom - height))
        .toDouble();

    final rect = Rect.fromLTWH(left, top, width, height);
    final chip = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(
      chip,
      Paint()..color = palette.surface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      chip,
      Paint()
        ..color = hovered.color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _BubbleRiskPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.palette != palette ||
      oldDelegate.daysTitle != daysTitle ||
      oldDelegate.stockTitle != stockTitle ||
      oldDelegate.maxStockAxis != maxStockAxis ||
      oldDelegate.maxDaysAxis != maxDaysAxis ||
      !identical(oldDelegate.hovered, hovered);
}

class _BubbleRiskLegend extends StatelessWidget {
  final AppPalette palette;

  const _BubbleRiskLegend({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RiskLegendDot(
          color: palette.warningFg.withValues(alpha: 0.5),
          label: context.l10n.t('Under 36d'),
        ),
        _RiskLegendDot(
          color: palette.warningFg,
          label: context.l10n.t('36d+ at risk'),
        ),
        _RiskLegendDot(
          color: palette.dangerFg,
          label: context.l10n.t('45d+ dead stock'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.textMuted, width: 1.2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              context.l10n.t('Bubble size = Stock'),
              style: appText(
                size: AppTypography.labelSmallSize,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RiskLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _RiskLegendDot({required this.color, required this.label});

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
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: appText(
            size: AppTypography.labelSmallSize,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }
}

class _BubbleRiskSkeleton extends StatelessWidget {
  const _BubbleRiskSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _BubbleRiskMatrix._height,
      child: SkeletonBox(height: _BubbleRiskMatrix._height, radius: 12),
    );
  }
}

/// Inert blocks in the shape of a preview table: a header row plus five data
/// rows. No sweep of its own — four concurrent sweeps on one screen is the
/// thing `SkeletonSweep` exists to avoid, and these are replaced within a
/// second of the dashboard itself appearing.
class _PreviewTableSkeleton extends StatelessWidget {
  final List<TableColumn> columns;

  /// Matches the real preview's leading cell: wider for a product photo, and a
  /// tall thin block for a row number.
  final bool showThumbnail;

  const _PreviewTableSkeleton({
    required this.columns,
    this.showThumbnail = false,
  });

  int get _leadFlex => showThumbnail ? 34 : 30;

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
              flex: _leadFlex,
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
                flex: _leadFlex,
                child: SkeletonBox(
                  height: showThumbnail ? 28 : 12,
                  width: showThumbnail ? 28 : 18,
                  radius: 6,
                ),
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
            style: appText(
              size: AppTypography.labelSmallSize,
              color: p.textMuted,
            ),
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
        borderRadius: BorderRadius.circular(DashboardStyle.controlRadius),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: years.contains(value) ? value : years.first,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: appText(
            size: AppTypography.labelMediumSize,
            color: p.textSecondary,
          ),
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
    final chart = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        painter: _MonthlySalesChartPainter(items, palette, progress),
      ),
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

  /// 0→1 draw-in. Bars grow from the baseline; value labels wait until the
  /// growth finishes so they are not left floating above a half-height bar.
  final double progress;

  _MonthlySalesChartPainter(this.items, this.palette, this.progress);

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
      final x = (plot.left + slotWidth * (m + 0.5) - tp.width / 2).clamp(
        plot.left,
        plot.right - tp.width,
      );
      tp.paint(canvas, Offset(x, plot.bottom + 8));
    }

    final currentMonth = DateTime.now().month;
    final mutedBarPaint = Paint()
      ..color = palette.primary.withValues(alpha: 0.34);
    final valueLabels = <_MonthlyValueLabel>[];
    for (final entry in sorted) {
      if (entry.month < 1 || entry.month > 12) continue;
      final centreX = plot.left + slotWidth * ((entry.month - 1) + 0.5);
      final height =
          (entry.total / chartMax) * plot.height * progress.clamp(0.0, 1.0);
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
      // Labels wait for the bars to finish growing.
      if (progress < 0.999) continue;

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
      final x = (centreX - vp.width / 2).clamp(
        plot.left,
        plot.right - vp.width,
      );
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
      oldDelegate.items != items ||
      oldDelegate.palette != palette ||
      oldDelegate.progress != progress;
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
    final chartH = (items.length * 36.0 + 40.0).clamp(200.0, 460.0);
    final chart = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        painter: _HorizontalCategoryChartPainter(items, palette, progress),
      ),
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
  final double progress;

  _HorizontalCategoryChartPainter(this.items, this.palette, this.progress);

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
          style: appText(
            size: AppTypography.labelSmallSize,
            color: palette.textSecondary,
          ),
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

    // Average line: a vertical dashed line at the mean quantity, with a small
    // label at the top so the eye can compare each bar against the average.
    final avgVal = values.isNotEmpty
        ? values.fold<double>(0, (a, b) => a + b) / values.length
        : 0.0;
    final avgX = plot.left + (avgVal / chartMax) * plot.width;
    final avgLinePaint = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    if (avgVal > 0 && avgX > plot.left && avgX < plot.right) {
      final dash = 4.0;
      final gap = 4.0;
      var y = plot.top;
      while (y < plot.bottom) {
        canvas.drawLine(
          Offset(avgX, y),
          Offset(avgX, (y + dash).clamp(0.0, plot.bottom)),
          avgLinePaint,
        );
        y += dash + gap;
      }
      final avgLabel = TextPainter(
        text: TextSpan(
          text: 'Avg ${_formatQuantity(avgVal)}',
          style: appText(
            size: AppTypography.labelSmallSize,
            weight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.drawRect(
        Rect.fromLTWH(
          avgX.clamp(plot.left + 1, plot.right - avgLabel.width - 1),
          plot.top - avgLabel.height - 4,
          avgLabel.width,
          avgLabel.height,
        ),
        Paint()..color = palette.surface.withValues(alpha: 0.85),
      );
      avgLabel.paint(
        canvas,
        Offset(
          avgX.clamp(plot.left + 1, plot.right - avgLabel.width - 1),
          plot.top - avgLabel.height - 4,
        ),
      );
    }

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
          style: appText(
            size: AppTypography.labelSmallSize,
            color: palette.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 8));
    }

    final n = sorted.length;
    final rowH = plot.height / n;
    final barH = (rowH * 0.6).clamp(6.0, 22.0);

    // Track behind every bar so empty categories still read as a row, and a
    // muted gradient so the muted bars stay on-brand instead of flat grey.
    final trackPaint = Paint()..color = palette.border.withValues(alpha: 0.45);

    for (var i = 0; i < n; i++) {
      final e = sorted[i];
      final cy = plot.top + rowH * (i + 0.5);

      // Stagger the draw-in so the bars cascade in rather than snapping as a
      // block — reads as one animated chart instead of a static one.
      final barProgress = ((progress - i * 0.07).clamp(0.0, 1.0));
      final barW = (e.totalQuantity / chartMax) * plot.width * barProgress;

      // Track.
      final trackRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(plot.left, cy - barH / 2, plot.width, barH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      final lp = TextPainter(
        text: TextSpan(
          text: e.category,
          style: appText(
            size: AppTypography.labelSmallSize,
            color: palette.textSecondary,
          ),
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
      final topBar = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primary.withValues(alpha: 0.55)],
        ).createShader(Rect.fromLTWH(0, 0, plot.right - plot.left, barH))
        ..style = PaintingStyle.fill;
      final mutedBar = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.40),
            palette.primary.withValues(alpha: 0.20),
          ],
        ).createShader(Rect.fromLTWH(0, 0, plot.right - plot.left, barH))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, i == 0 ? topBar : mutedBar);

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
      oldDelegate.items != items ||
      oldDelegate.palette != palette ||
      oldDelegate.progress != progress;
}

/// A category's share of the largest category as an animated, rounded bar on
/// a low-contrast track.
///
/// Used by both the allocation legend and the stock-status rows: in each case
/// the bar compares a part against the largest part (or, for stock, against
/// the whole), and the tween means a refresh animates the bars rather than
/// snapping them.

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

    if (total <= 0) {
      return _PanelCard(
        title: title,
        trailing: trailing,
        padding: const EdgeInsets.all(12),
        titlePadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: SizedBox(
          height: 80,
          child: AppEmptyState(
            title: context.l10n.t('No stock data'),
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );
    }

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
                    style: appText(
                      size: AppTypography.labelSmallSize,
                      color: p.textSecondary,
                    ),
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
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: trackColor.withValues(alpha: 0.6)),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0,
          end: fraction.isFinite ? fraction.clamp(0.0, 1.0).toDouble() : 0.0,
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.isFinite ? value.clamp(0.0, 1.0) : 0.0,
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

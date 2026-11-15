import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_controller_page.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_style.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/summary_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/overview/overview_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/overview/profit_trend_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/screens/money_flow_analysis_screen.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/month_filter_button.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_delta.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/finance_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

class SaleAnalysisScreen extends StatefulWidget {
  const SaleAnalysisScreen({super.key});

  @override
  State<SaleAnalysisScreen> createState() => _SaleAnalysisScreenState();
}

class _SaleAnalysisScreenState extends State<SaleAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;
  late final FinanceViewModel _vm;

  /// The month on screen. Opens on the current month rather than a date that
  /// was frozen into the source when the screen was written.
  DateTime _overviewMonth = _nowMonth();

  static DateTime _nowMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Earliest month the picker can reach: January of the first year the
  /// account has data for, falling back to the selected year while the
  /// finance data is still loading.
  DateTime get _firstMonth {
    var year = _overviewMonth.year;
    for (final y in _vm.years) {
      if (y < year) year = y;
    }
    return DateTime(year, 1);
  }

  /// Latest month the picker can reach: there is no data for future months.
  DateTime get _lastMonth => _nowMonth();

  /// Bumped whenever fee rules may have changed (e.g. tab switch back from
  /// Operation Fee) so the embedded screens refetch their figures.
  int _dataRevision = 0;

  /// The Overview card carrying the theme highlight. Tapping another card
  /// moves it; it starts on Net profit, the headline figure.
  int _overviewHighlightedCard = 9;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _vm = FinanceViewModel(repository: DashboardRepositoryImpl());
    _vm.load(year: _overviewMonth.year);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Rules can be edited in the Operation Fee tab, so reload when the user
    // comes back to Overview or Money Flow.
    setState(() => _dataRevision++);
    _vm.load(year: _overviewMonth.year);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final p = context.palette;
        return AppShell(
          active: DrawerDestination.saleAnalysis,
          scaffoldKey: _scaffoldKey,
          backgroundColor: p.scaffoldBg,
          wrap: (_, shell) => shell,
          body: (context, isWide) => SafeArea(
            child: Column(
              children: [
                AppScreenTopBar(
                  title: 'Finance',
                  showMenuButton: !isWide,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Money Flow'),
                    Tab(text: 'Operation Fee'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverview(),
                      MoneyFlowAnalysisScreen(
                        embedded: true,
                        refreshToken: _dataRevision,
                      ),
                      const OperationFeeControllerPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- overview

  Widget _buildOverview() {
    final p = context.palette;
    // Real figures only: the month exists on screen if the API returned it.
    final realMonth = _vm.monthFor(_overviewMonth);
    final data = realMonth == null
        ? null
        : OverviewMonth(
            month: _overviewMonth,
            revenue: realMonth.inflow,
            cogsValue: _vm.cogsFor(_overviewMonth.month).toDouble(),
            operationFee: realMonth.operationFee,
            unitsSold: _vm.unitsFor(_overviewMonth.month),
            transactions: _vm.txnsFor(_overviewMonth.month),
          );
    final previousReal = _vm.previousMonthOf(_overviewMonth);
    final previous = previousReal == null
        ? null
        : OverviewMonth(
            month: previousReal.month,
            revenue: previousReal.inflow,
            cogsValue: _vm
                .cogsFor(previousReal.month.month)
                .toDouble(),
            operationFee: previousReal.operationFee,
            unitsSold: _vm.unitsFor(previousReal.month.month),
            transactions: _vm.txnsFor(previousReal.month.month),
          );

    return Container(
      color: p.scaffoldBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1100;
          final isTablet = width >= 700;
          final pagePadding = isDesktop
              ? 32.0
              : isTablet
              ? 24.0
              : 16.0;
          final columns = isDesktop
              ? 5
              : isTablet
              ? 2
              : 1;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              pagePadding,
              pagePadding,
              pagePadding + 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _overviewHeading(isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 20),
                    if (data == null)
                      _vm.isLoading
                          ? _OverviewSkeleton(columns: columns)
                          : _emptyOverview(p)
                    else ...[
                      _overviewCards(
                        data: data,
                        previous: previous,
                        columns: columns,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All amounts in MMK.',
                        style: ofText(size: 11, color: p.textMuted),
                      ),
                      const SizedBox(height: 20),
                      _profitTrendCard(data),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _overviewHeading({required bool isDesktop, required bool isTablet}) {
    final p = context.palette;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales overview',
          style: ofText(
            size: 27,
            weight: FontWeight.w700,
            color: p.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'One month at a time, with the profit trend across the whole year.',
          style: ofText(size: 13, color: p.textSecondary),
        ),
      ],
    );

    final monthButton = MonthFilterButton(
      month: _overviewMonth,
      onPressed: _pickOverviewMonth,
    );

    if (isDesktop || isTablet) {
      return Row(
        crossAxisAlignment: isDesktop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          monthButton,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 16), monthButton],
    );
  }

  Widget _overviewCards({
    required OverviewMonth data,
    required OverviewMonth? previous,
    required int columns,
  }) {
    final p = context.palette;
    final feeShare = data.revenue == 0
        ? 0.0
        : data.operationFee / data.revenue * 100;

    const gap = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        Widget card({
          required int index,
          required String label,
          required num value,
          required String Function(num value) format,
          required TrendDelta delta,
          required String supporting,
          required List<double> spark,
          required Color sparkColor,
          Widget? footer,
        }) {
          final highlighted = _overviewHighlightedCard == index;
          return OfSummaryCard(
            width: width,
            highlight: highlighted,
            onTap: () => setState(() => _overviewHighlightedCard = index),
            label: label,
            value: value,
            format: format,
            badgeText: delta.text,
            badgeUp: delta.up,
            badgeTone: delta.tone,
            supporting: supporting,
            footer:
                footer ??
                Align(
                  alignment: Alignment.centerRight,
                  child: OfSparkBars(
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.85)
                        : sparkColor,
                    values: spark,
                  ),
                ),
          );
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            card(
              index: 0,
              label: 'Revenue',
              value: data.revenue,
              format: _moneyCounter(data.revenue),
              delta: trendDelta(
                data.revenue,
                previous?.revenue,
                higherIsBetter: true,
              ),
              supporting: previous == null
                  ? 'No earlier month on record'
                  : 'vs. ${_money(previous.revenue)} last month',
              spark: _spark((m) => m.revenue),
              sparkColor: AppColors.green,
            ),
            card(
              index: 1,
              label: 'Cost of goods',
              value: data.cogs,
              format: _moneyCounter(data.cogs),
              delta: trendDelta(
                data.cogs,
                previous?.cogs,
                higherIsBetter: false,
              ),
              supporting: data.revenue == 0
                  ? 'No sales this month'
                  : '${(data.cogs / data.revenue * 100).toStringAsFixed(1)}% of revenue',
              spark: _spark((m) => m.cogs),
              sparkColor: AppColors.red,
            ),
            card(
              index: 2,
              label: 'Gross profit',
              value: data.grossProfit,
              format: _moneyCounter(data.grossProfit),
              delta: trendDelta(
                data.grossProfit,
                previous?.grossProfit,
                higherIsBetter: true,
              ),
              supporting: 'Revenue minus cost of goods',
              spark: _spark((m) => m.grossProfit),
              sparkColor: p.primary,
            ),
            card(
              index: 3,
              label: 'Gross margin',
              value: data.marginPct,
              format: (v) => '${v.toStringAsFixed(1)}%',
              delta: trendDelta(
                data.marginPct,
                previous?.marginPct,
                higherIsBetter: true,
              ),
              supporting: 'Share of revenue kept as profit',
              spark: _spark((m) => m.marginPct),
              sparkColor: AppColors.teal,
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (data.marginPct / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: _overviewHighlightedCard == 3
                      ? Colors.white.withValues(alpha: 0.28)
                      : p.chipBg,
                  color: _overviewHighlightedCard == 3
                      ? Colors.white
                      : p.primary,
                ),
              ),
            ),
            card(
              index: 4,
              label: 'Units sold',
              value: data.unitsSold,
              format: (v) => ofCount(v),
              delta: trendDelta(
                data.unitsSold,
                previous?.unitsSold,
                higherIsBetter: true,
              ),
              supporting: '${data.avgUnits.toStringAsFixed(1)} per transaction',
              spark: _spark((m) => m.unitsSold.toDouble()),
              sparkColor: AppColors.blue,
            ),
            card(
              index: 5,
              label: 'Transactions',
              value: data.transactions,
              format: (v) => ofCount(v),
              delta: trendDelta(
                data.transactions,
                previous?.transactions,
                higherIsBetter: true,
              ),
              supporting: 'Paid and completed sales',
              spark: _spark((m) => m.transactions.toDouble()),
              sparkColor: AppColors.blueBright,
            ),
            card(
              index: 6,
              label: 'Average order value',
              value: data.aov,
              format: _moneyCounter(data.aov),
              delta: trendDelta(data.aov, previous?.aov, higherIsBetter: true),
              supporting: 'Revenue per transaction',
              spark: _spark((m) => m.aov),
              sparkColor: AppColors.teal,
            ),
            card(
              index: 7,
              label: 'Avg units / transaction',
              value: data.avgUnits,
              format: (v) => v.toStringAsFixed(2),
              delta: trendDelta(
                data.avgUnits,
                previous?.avgUnits,
                higherIsBetter: true,
              ),
              supporting: 'Basket size per sale',
              spark: _spark((m) => m.avgUnits),
              sparkColor: p.accentText,
            ),
            card(
              index: 8,
              label: 'Operation fee',
              value: data.operationFee,
              format: _moneyCounter(data.operationFee),
              delta: trendDelta(
                data.operationFee,
                previous?.operationFee,
                higherIsBetter: false,
              ),
              supporting: '${feeShare.toStringAsFixed(1)}% of revenue',
              spark: _spark((m) => m.operationFee),
              sparkColor: AppColors.orange,
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (feeShare / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: _overviewHighlightedCard == 8
                      ? Colors.white.withValues(alpha: 0.28)
                      : p.chipBg,
                  color: _overviewHighlightedCard == 8
                      ? Colors.white
                      : AppColors.orange,
                ),
              ),
            ),
            card(
              index: 9,
              label: 'Net profit',
              value: data.netProfit,
              format: _moneyCounter(data.netProfit),
              delta: trendDelta(
                data.netProfit,
                previous?.netProfit,
                higherIsBetter: true,
              ),
              supporting: 'After cost of goods and fees',
              spark: _spark((m) => m.netProfit),
              sparkColor: p.accentText,
            ),
          ],
        );
      },
    );
  }

  Widget _profitTrendCard(OverviewMonth data) {
    final p = context.palette;
    final series = _profitSeries();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ofCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Profit trend',
            style: ofText(
              size: 16,
              weight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gross vs net profit · all time',
            style: ofText(size: 11.5, color: p.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _legendDot(p, p.primary, 'Gross profit'),
              _legendDot(p, AppColors.green, 'Net profit'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: ProfitTrendChart(
              months: series,
              highlightIndex: series.indexWhere(
                (m) =>
                    m.month.year == data.month.year &&
                    m.month.month == data.month.month,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(AppPalette p, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: ofText(size: 11, color: p.textSecondary)),
      ],
    );
  }

  Widget _emptyOverview(AppPalette p) {
    final name =
        '${overviewMonthAbbr[_overviewMonth.month - 1]} ${_overviewMonth.year}';
    return AppEmptyState(
      title: 'No sales recorded in $name',
      subtitle: 'Try a different month or check your filters.',
      icon: Icons.receipt_long_outlined,
    );
  }

  /// Sparkline values for the six months ending at the selected month.
  List<double> _spark(double Function(OverviewMonth) pick) {
    final series = _overviewSeries();
    final index = series.indexWhere(
      (m) =>
          m.month.year == _overviewMonth.year &&
          m.month.month == _overviewMonth.month,
    );
    if (index < 0) return List<double>.filled(7, 0.12);
    final start = math.max(0, index - 6);
    final window = series.sublist(start, index + 1);
    final max = window.fold<double>(0, (m, x) => math.max(m, pick(x)));
    if (max <= 0) return List<double>.filled(window.length, 0.12);
    return [
      for (final m in window) (pick(m) / max).clamp(0.08, 1.0).toDouble(),
    ];
  }

  /// The selected year with real revenue, COGS, units, transactions and the
  /// operation fee computed from the shop's rules.
  ///
  /// Before the API responds there is no series at all — the cards show a
  /// skeleton and the chart draws nothing, rather than a designed year of
  /// numbers the shop never made.
  List<OverviewMonth> _overviewSeries() {
    if (_vm.months.isEmpty) return const [];

    return _vm.yearMonths(_overviewMonth.year).map((m) {
      final month = m.month.month;
      return OverviewMonth(
        month: m.month,
        revenue: m.inflow,
        cogsValue: _vm.cogsFor(month).toDouble(),
        operationFee: m.operationFee,
        unitsSold: _vm.unitsFor(month),
        transactions: _vm.txnsFor(month),
      );
    }).toList();
  }

  /// Months that actually sold something, oldest first. Empty months are
  /// dropped so the profit trend starts at the first real month instead of
  /// drawing a flat line across months with no profit.
  List<OverviewMonth> _profitSeries() {
    if (_vm.months.isEmpty) return const [];
    return _overviewSeries()
        .where((m) => m.revenue > 0 && m.transactions > 0)
        .toList();
  }

  String _money(num value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return 'MMK ${(value / 1000000).toStringAsFixed(1)}M';
    }
    return ofMoney(value, digits: 0);
  }

  /// The counting formatter for a card whose final figure is [target].
  ///
  /// It picks the notation from the destination, not the in-flight value, so a
  /// count from zero to eight million reads `MMK 0.0M … MMK 8.0M` instead of
  /// switching from `MMK 999,999` to `MMK 1.0M` halfway up.
  String Function(num) _moneyCounter(num target) {
    if (target.abs() >= 1000000) {
      return (v) => 'MMK ${(v / 1000000).toStringAsFixed(1)}M';
    }
    return (v) => ofMoney(v, digits: 0);
  }

  Future<void> _pickOverviewMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _overviewMonth,
      firstDate: _firstMonth,
      lastDate: _lastMonth,
      helpText: 'Select a month',
    );
    if (picked != null && mounted) {
      final newMonth = DateTime(picked.year, picked.month);
      setState(() => _overviewMonth = newMonth);
      if (newMonth.year != _vm.selectedYear) {
        _vm.load(year: newMonth.year);
      }
    }
  }
}

/// Placeholder for the Overview cards while the first response is in flight.
///
/// The grid has ten cards; the skeleton draws ten so the layout does not jump
/// when the real figures land.
class _OverviewSkeleton extends StatelessWidget {
  final int columns;
  const _OverviewSkeleton({required this.columns});

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 10; i++)
              SizedBox(
                width: width,
                child: const SkeletonCard(
                  radius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 96, height: 12, radius: 4),
                      SizedBox(height: 12),
                      SkeletonBox(width: 140, height: 26, radius: 6),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 11, radius: 4),
                      SizedBox(height: 24),
                      SkeletonBox(width: 72, height: 18, radius: 4),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

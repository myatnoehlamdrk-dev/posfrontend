import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/money_flow/cash_flow_trend_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/money_flow/money_flow_data.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/sale_analysis/presentation/viewmodels/finance_view_model.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/operation_fee_style.dart';
import 'package:posfrontend/features/sale_analysis/presentation/operation_fee/widgets/summary_card.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/month_filter_button.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_delta.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Money Flow dashboard for the Finance section.
///
/// One month at a time (chosen from a calendar), four figures — inflow,
/// purchases outflow, the operation-fee cost from the shop's rules, and net
/// cash flow after both — plus the monthly trend for the selected year.
class MoneyFlowAnalysisScreen extends StatefulWidget {
  final bool embedded;

  /// Changes whenever the parent knows fee rules may have changed; the screen
  /// then refetches its monthly figures.
  final int refreshToken;

  const MoneyFlowAnalysisScreen({
    super.key,
    this.embedded = false,
    this.refreshToken = 0,
  });

  @override
  State<MoneyFlowAnalysisScreen> createState() =>
      _MoneyFlowAnalysisScreenState();
}

class _MoneyFlowAnalysisScreenState extends State<MoneyFlowAnalysisScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final FinanceViewModel _vm;

  /// The month on screen. Opens on the current month rather than a date that
  /// was frozen into the source when the screen was written.
  DateTime _month = _nowMonth();

  static DateTime _nowMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// The card carrying the theme highlight. Tapping another card moves it.
  /// Starts on Net cash flow, the headline figure.
  int _highlightedCard = 3;

  /// Year shown in the cash-flow trend chart (independent of the month filter).
  int _chartYear = DateTime.now().year;

  /// Earliest month the picker can reach: January of the first year the
  /// account has data for, falling back to the selected year while the
  /// finance data is still loading.
  DateTime get _firstMonth {
    var year = _month.year;
    for (final y in _vm.years) {
      if (y < year) year = y;
    }
    return DateTime(year, 1);
  }

  /// Latest month the picker can reach: there is no data for future months.
  DateTime get _lastMonth => _nowMonth();

  @override
  void initState() {
    super.initState();
    _vm = FinanceViewModel(repository: DashboardRepositoryImpl());
    _vm.load(year: _month.year);
  }

  @override
  void didUpdateWidget(covariant MoneyFlowAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _vm.load(year: _month.year);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final content = _buildContent(context);
        if (widget.embedded) return content;

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
                  title: 'Money Flow Analysis',
                  showMenuButton: !isWide,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.palette;
    // Real figures only: the month exists on screen if the API returned it.
    final month = _vm.monthFor(_month);
    final previous = _vm.previousMonthOf(_month);
    // Trend chart uses real data only (no demo fallback).
    final chartMonths = _vm.yearMonths(_chartYear);
    final selectedIndex = _month.month - 1;

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
              ? 4
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
                    _heading(isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 20),
                    if (month == null)
                      _vm.isLoading
                          ? _MoneyFlowSkeleton(columns: columns)
                          : _emptyMonth(p)
                    else ...[
                      _cards(
                        month: month,
                        previous: previous,
                        yearMonths: chartMonths,
                        selectedIndex: selectedIndex,
                        columns: columns,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All amounts in MMK.',
                        style: ofText(size: 11, color: p.textMuted),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Cash flow trend',
                            style: ofText(
                              size: 16,
                              weight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _chartYear,
                            items: _vm.years.isNotEmpty
                                ? _vm.years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y'),
                                        ),
                                      )
                                      .toList()
                                : [
                                    DropdownMenuItem(
                                      value: _chartYear,
                                      child: Text('$_chartYear'),
                                    ),
                                  ],
                            onChanged: (y) {
                              if (y != null && y != _chartYear) {
                                setState(() => _chartYear = y);
                                _vm.load(year: y);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _trend(
                        p: p,
                        yearMonths: chartMonths,
                        selectedIndex: selectedIndex,
                      ),
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

  Widget _heading({required bool isDesktop, required bool isTablet}) {
    final p = context.palette;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Money flow',
          style: ofText(
            size: 27,
            weight: FontWeight.w700,
            color: p.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'See what came in, what went out, and what was left.',
          style: ofText(size: 13, color: p.textSecondary),
        ),
      ],
    );

    final monthButton = MonthFilterButton(month: _month, onPressed: _pickMonth);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          monthButton,
        ],
      );
    }

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _cards({
    required MoneyFlowMonth month,
    required MoneyFlowMonth? previous,
    required List<MoneyFlowMonth> yearMonths,
    required int selectedIndex,
    required int columns,
  }) {
    final p = context.palette;
    final inflowDelta = trendDelta(
      month.inflow,
      previous?.inflow,
      higherIsBetter: true,
    );
    final outflowDelta = trendDelta(
      month.outflow,
      previous?.outflow,
      higherIsBetter: false,
    );
    final feeDelta = trendDelta(
      month.operationFee,
      previous?.operationFee,
      higherIsBetter: false,
    );
    final netDelta = trendDelta(month.net, previous?.net, higherIsBetter: true);
    final feeShare = month.inflow == 0
        ? 0.0
        : month.operationFee / month.inflow * 100;

    const gap = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            OfSummaryCard(
              width: width,
              highlight: _highlightedCard == 0,
              onTap: () => setState(() => _highlightedCard = 0),
              label: 'Total inflow',
              value: month.inflow,
              format: (v) => ofMoney(v, digits: 0),
              badgeText: inflowDelta.text,
              badgeUp: inflowDelta.up,
              badgeTone: inflowDelta.tone,
              supporting: previous == null
                  ? 'No earlier month on record'
                  : 'vs. ${ofMoney(previous.inflow, digits: 0)} last month',
              footer: Align(
                alignment: Alignment.centerRight,
                child: OfSparkBars(
                  color: _highlightedCard == 0
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.green,
                  values: _sparkValues(
                    yearMonths,
                    selectedIndex,
                    (m) => m.inflow,
                  ),
                ),
              ),
            ),
            OfSummaryCard(
              width: width,
              highlight: _highlightedCard == 1,
              onTap: () => setState(() => _highlightedCard = 1),
              label: 'Total outflow',
              value: month.outflow,
              format: (v) => ofMoney(v, digits: 0),
              badgeText: outflowDelta.text,
              badgeUp: outflowDelta.up,
              badgeTone: outflowDelta.tone,
              supporting: previous == null
                  ? 'No earlier month on record'
                  : 'vs. ${ofMoney(previous.outflow, digits: 0)} last month',
              footer: Align(
                alignment: Alignment.centerRight,
                child: OfSparkBars(
                  color: _highlightedCard == 1
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.red,
                  values: _sparkValues(
                    yearMonths,
                    selectedIndex,
                    (m) => m.outflow,
                  ),
                ),
              ),
            ),
            OfSummaryCard(
              width: width,
              highlight: _highlightedCard == 2,
              onTap: () => setState(() => _highlightedCard = 2),
              label: 'Operation fee',
              value: month.operationFee,
              format: (v) => ofMoney(v, digits: 0),
              badgeText: feeDelta.text,
              badgeUp: feeDelta.up,
              badgeTone: feeDelta.tone,
              supporting: '${feeShare.toStringAsFixed(1)}% of inflow',
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (feeShare / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: _highlightedCard == 2
                      ? Colors.white.withValues(alpha: 0.28)
                      : p.chipBg,
                  color: _highlightedCard == 2 ? Colors.white : p.primary,
                ),
              ),
            ),
            OfSummaryCard(
              width: width,
              highlight: _highlightedCard == 3,
              onTap: () => setState(() => _highlightedCard = 3),
              label: 'Net cash flow',
              value: month.net,
              format: (v) => ofMoney(v, digits: 0),
              badgeText: netDelta.text,
              badgeUp: netDelta.up,
              badgeTone: netDelta.tone,
              supporting: 'Inflow minus outflow and fees',
              footer: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _MiniStat(
                    label: 'Inflow',
                    value: moneyFlowCompact(month.inflow),
                    onHighlight: _highlightedCard == 3,
                  ),
                  _MiniStat(
                    label: 'Outflow',
                    value: moneyFlowCompact(month.outflow),
                    onHighlight: _highlightedCard == 3,
                  ),
                  _MiniStat(
                    label: 'Fees',
                    value: moneyFlowCompact(month.operationFee),
                    onHighlight: _highlightedCard == 3,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trend({
    required AppPalette p,
    required List<MoneyFlowMonth> yearMonths,
    required int selectedIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inflow vs outflow by month · $_chartYear',
          style: ofText(size: 11.5, color: p.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(p, AppColors.green, 'Inflow'),
            const SizedBox(width: 16),
            _legendDot(p, AppColors.red, 'Outflow'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: CashFlowTrendChart(
            months: yearMonths,
            highlightIndex: selectedIndex,
          ),
        ),
      ],
    );
  }

  Widget _emptyMonth(AppPalette p) {
    return AppEmptyState(
      title: 'No money flow data for ${moneyFlowMonthLabel(_month)}',
      subtitle: 'Try a different month.',
      icon: Icons.account_balance_wallet_outlined,
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

  List<double> _sparkValues(
    List<MoneyFlowMonth> yearMonths,
    int selectedIndex,
    double Function(MoneyFlowMonth) pick,
  ) {
    final start = math.max(0, selectedIndex - 6);
    final window = yearMonths.sublist(start, selectedIndex + 1);
    final max = window.fold<double>(0, (m, x) => math.max(m, pick(x)));
    if (max <= 0) return List<double>.filled(window.length, 0.12);
    return [
      for (final m in window) (pick(m) / max).clamp(0.08, 1.0).toDouble(),
    ];
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: _firstMonth,
      lastDate: _lastMonth,
      helpText: 'Select a month',
    );
    if (picked != null && mounted) {
      final newMonth = DateTime(picked.year, picked.month);
      setState(() => _month = newMonth);
      if (newMonth.year != _vm.selectedYear) {
        _vm.load(year: newMonth.year);
      }
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool onHighlight;

  const _MiniStat({
    required this.label,
    required this.value,
    this.onHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ofText(
            size: 10.5,
            color: onHighlight
                ? Colors.white.withValues(alpha: 0.7)
                : p.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: ofText(
            size: 11,
            weight: FontWeight.w600,
            color: onHighlight ? Colors.white : p.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Placeholder for the Money Flow cards while the first response is in flight.
///
/// Four cards, the same four the real grid draws, so the layout does not jump
/// when the figures land.
class _MoneyFlowSkeleton extends StatelessWidget {
  final int columns;
  const _MoneyFlowSkeleton({required this.columns});

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
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: width,
                child: const SkeletonCard(
                  radius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 84, height: 12, radius: 4),
                      SizedBox(height: 12),
                      SkeletonBox(width: 150, height: 26, radius: 6),
                      SizedBox(height: 10),
                      SkeletonBox(width: 130, height: 11, radius: 4),
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

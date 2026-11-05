import 'package:flutter/material.dart';
import 'package:posfrontend/features/money_flow/presentation/data/money_flow_demo_data.dart';
import 'package:posfrontend/features/money_flow/presentation/screens/money_flow_transactions_screen.dart';
import 'package:posfrontend/features/money_flow/presentation/widgets/charts/cash_flow_trend_chart.dart';
import 'package:posfrontend/features/money_flow/presentation/widgets/money_flow_widgets.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';

/// Money Flow Analysis — the Phase 1 financial dashboard.
///
/// One screen answering the five questions a shop owner actually asks: how much
/// came in, how much went out, what is left, where it came from, and where it
/// went. Payment methods, receivables/payables and the forecast are Phase 2/3
/// and are deliberately not here yet.
class MoneyFlowAnalysisScreen extends StatefulWidget {
  const MoneyFlowAnalysisScreen({super.key});

  @override
  State<MoneyFlowAnalysisScreen> createState() =>
      _MoneyFlowAnalysisScreenState();
}

class _MoneyFlowAnalysisScreenState extends State<MoneyFlowAnalysisScreen> {
  static const MoneyFlowDemoData _data = MoneyFlowDemoData();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _preset = 'This Month';
  DateTimeRange _range = MoneyFlowDemoData.rangeForPreset('This Month');
  String _granularity = 'Weekly';

  /// How many movements the dashboard previews; `View All` opens the rest.
  static const int _previewCount = 5;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final totals = _data.totalsFor(_range);
    final previous = _data.totalsFor(_data.previousPeriod(_range));
    final buckets = _data.trendBuckets(_range, _granularity);
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MoneyFlowSectionTitle('Financial Overview'),
                    MoneyFlowPeriodFilter(
                      presets: MoneyFlowDemoData.periodPresets,
                      selected: _preset,
                      onSelect: _selectPreset,
                      rangeLabel: _data.rangeLabelFor(_range),
                      onPickRange: _pickRange,
                    ),
                    const SizedBox(height: 16),
                    const MoneyFlowSectionTitle('Financial Summary'),
                    _summaryGrid(totals, previous),
                    const SizedBox(height: 8),
                    const MoneyFlowNote(
                      'Illustrative figures only. All amounts in MMK.',
                    ),
                    const SizedBox(height: 16),
                    const MoneyFlowSectionTitle('Cash Flow Trend'),
                    CashFlowTrendPanel(
                      granularity: _granularity,
                      granularities: MoneyFlowDemoData.granularities,
                      onGranularityChanged: (g) =>
                          setState(() => _granularity = g),
                      labels: buckets.labels,
                      inflow: buckets.inflow,
                      outflow: buckets.outflow,
                      rangeLabel: _data.rangeLabelFor(_range),
                      axisLabel: _data.money,
                    ),
                    const SizedBox(height: 16),
                    const MoneyFlowSectionTitle('Financial Breakdown'),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          _breakdowns(constraints.maxWidth, totals),
                    ),
                    const SizedBox(height: 16),
                    const MoneyFlowSectionTitle(
                      'Recent Financial Transactions',
                    ),
                    MoneyFlowTransactionList(
                      transactions: _visibleLedger.take(_previewCount).toList(),
                      onViewAll: _openLedger,
                    ),
                    const SizedBox(height: 8),
                    MoneyFlowNote(
                      'Showing ${_visibleLedger.take(_previewCount).length} '
                      'of ${_visibleLedger.length} movements for '
                      '${_data.rangeLabelFor(_range)}.',
                      italic: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Financial Summary
  // -------------------------------------------------------------------

  Widget _summaryGrid(MoneyFlowTotals totals, MoneyFlowTotals previous) {
    final net = totals.net;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        MoneyFlowSummaryCard(
          label: 'Total Inflow',
          value: _data.money(totals.inflow),
          sub: _data.change(totals.inflow, previous.inflow),
          icon: Icons.arrow_downward,
          tone: MoneyFlowTone.inflow,
        ),
        MoneyFlowSummaryCard(
          label: 'Total Outflow',
          value: _data.money(totals.outflow),
          sub: _data.change(totals.outflow, previous.outflow),
          icon: Icons.arrow_upward,
          tone: MoneyFlowTone.outflow,
        ),
        MoneyFlowSummaryCard(
          label: 'Net Cash Flow',
          value: '${net >= 0 ? '+' : '-'}${_data.money(net.abs())}',
          sub: _data.change(totals.net, previous.net),
          icon: Icons.swap_horiz,
          tone: MoneyFlowTone.net,
          positive: net >= 0,
        ),
        MoneyFlowSummaryCard(
          label: 'Closing Balance',
          value: _data.money(totals.closing),
          sub: 'Opening ${_data.money(MoneyFlowDemoData.openingBalance)}',
          icon: Icons.account_balance_wallet_outlined,
          tone: MoneyFlowTone.neutral,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Financial Breakdown
  // -------------------------------------------------------------------

  Widget _breakdowns(double width, MoneyFlowTotals totals) {
    final inflow = MoneyFlowBreakdown(
      title: 'Money Inflow',
      totalLabel: _data.money(totals.inflow),
      items: _breakdownItems(MoneyFlowDemoData.inflowSources, totals.inflow),
      color: AppColors.green,
    );
    final outflow = MoneyFlowBreakdown(
      title: 'Money Outflow',
      totalLabel: _data.money(totals.outflow),
      items: _breakdownItems(MoneyFlowDemoData.outflowSources, totals.outflow),
      color: AppColors.red,
    );
    if (width >= 720) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: inflow),
          const SizedBox(width: 16),
          Expanded(child: outflow),
        ],
      );
    }
    return Column(children: [inflow, const SizedBox(height: 16), outflow]);
  }

  /// Whole MMK per source, so the rows add up to the total exactly rather than
  /// to a column of rounded millions.
  List<(String, String, double)> _breakdownItems(
    List<(String, double)> sources,
    double total,
  ) => [
    for (final source in sources)
      (source.$1, formatMmk(total * source.$2 * 1000000), source.$2),
  ];

  // -------------------------------------------------------------------
  // Ledger
  // -------------------------------------------------------------------

  /// Movements inside the active range, newest first.
  List<MoneyFlowTransaction> get _visibleLedger {
    final start = DateUtils.dateOnly(_range.start);
    final end = DateUtils.dateOnly(_range.end);
    return MoneyFlowDemoData.ledger.where((tx) {
      final day = DateUtils.dateOnly(tx.when);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  void _openLedger() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MoneyFlowTransactionsScreen(range: _range),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Period controls
  // -------------------------------------------------------------------

  Future<void> _selectPreset(String preset) async {
    if (preset != 'Custom') {
      setState(() {
        _preset = preset;
        _range = MoneyFlowDemoData.rangeForPreset(preset);
      });
      return;
    }
    // Choosing "Custom" is asking for the calendar: switch the chip only once
    // a range actually comes back, so an abandoned picker leaves the old view.
    final picked = await _pickRange();
    if (picked != null) setState(() => _preset = 'Custom');
  }

  Future<DateTimeRange?> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _preset = 'Custom';
      });
    }
    return picked;
  }
}

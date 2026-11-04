import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Net profit drill-down: trend, revenue-to-profit walk and category profit.
class NetProfitPage extends StatefulWidget {
  const NetProfitPage({super.key});

  @override
  State<NetProfitPage> createState() => _NetProfitPageState();
}

class _NetProfitPageState extends State<NetProfitPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _trendGranularity = 'Daily';
  String _chartType = 'Line';

  /// The two independent ranges behind the Period Comparison table, matching
  /// the other detail pages.
  DateTimeRange _compareRangeA = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  DateTimeRange _compareRangeB = DateTimeRange(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 31),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AnalysisKpiCard(
                label: 'Total Net Profit',
                value: '7.7M',
                sub: 'Revenue − COGS − Expenses',
              ),
              AnalysisKpiCard(
                label: 'Net Profit Margin',
                value: '27%',
                sub: 'Net Profit ÷ Revenue × 100',
              ),
              AnalysisKpiCard(
                label: 'Total Revenue',
                value: '28.5M',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Total Expenses',
                value: '20.8M',
                sub: 'COGS + Operating Expenses',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote(
            'Illustrative values in MMK. Estimated Net Profit — tax, interest '
            'and other non-operating items are not deducted.',
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Net Profit Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.netProfitTrendBuckets(_dateRange, _trendGranularity),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.netProfitDailyValue,
            ),
            lineColor: AppColors.green,
            axisLabel: _millions,
            money: _millions,
            metricLabel: 'net profit',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Revenue to Net Profit Breakdown'),
          const AnalysisTable(
            headers: ['Item', 'Amount'],
            rows: [
              ['Revenue', '28.5M'],
              ['COGS', '18.8M'],
              ['Gross Profit', '9.7M'],
              ['Operating Expenses', '2M'],
              ['Net Profit', '7.7M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Net Profit by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [3.2, 1.8, 1.3, 1.4]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Net Profit', 'Margin'],
            rows: [
              ['Electronics', '3.2M', '24%'],
              ['Accessories', '1.8M', '22%'],
              ['Computer', '1.3M', '29%'],
              ['Others', '1.4M', '61%'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Period Comparison'),
          _periodComparison(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _periodComparison() {
    final a = _data.netProfitStatsFor(_compareRangeA);
    final b = _data.netProfitStatsFor(_compareRangeB);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnalysisRangePickerButton(
                label: 'Range A',
                value: _data.rangeLabelFor(_compareRangeA),
                onPressed: () => _pickComparisonRange(isRangeA: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Swap ranges',
              onPressed: _swapComparisonRanges,
            ),
            Expanded(
              child: AnalysisRangePickerButton(
                label: 'Range B',
                value: _data.rangeLabelFor(_compareRangeB),
                onPressed: () => _pickComparisonRange(isRangeA: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnalysisTable(
          headers: [
            'Metric',
            _data.rangeLabelFor(_compareRangeA),
            _data.rangeLabelFor(_compareRangeB),
            'Change',
          ],
          minTableWidth: 640,
          rows: [
            [
              'Net Profit',
              _data.money(a.netProfit),
              _data.money(b.netProfit),
              _data.change(a.netProfit, b.netProfit),
            ],
            [
              'Net Profit Margin',
              '${a.netMargin.asPercent(1)}%',
              '${b.netMargin.asPercent(1)}%',
              _data.change(a.netMargin, b.netMargin),
            ],
            [
              'Revenue',
              _data.money(a.revenue),
              _data.money(b.revenue),
              _data.change(a.revenue, b.revenue),
            ],
            [
              'COGS',
              _data.money(a.cogs),
              _data.money(b.cogs),
              _data.change(a.cogs, b.cogs),
            ],
            [
              'Operating Expenses',
              _data.money(a.operatingExpenses),
              _data.money(b.operatingExpenses),
              _data.change(a.operatingExpenses, b.operatingExpenses),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const AnalysisNote(
          'Pick any two ranges with the calendar buttons. Change compares '
          'Range A with Range B.',
        ),
      ],
    );
  }

  Future<void> _pickComparisonRange({required bool isRangeA}) async {
    final initial = isRangeA ? _compareRangeA : _compareRangeB;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isRangeA) {
        _compareRangeA = picked;
      } else {
        _compareRangeB = picked;
      }
    });
  }

  void _swapComparisonRanges() {
    setState(() {
      final previousA = _compareRangeA;
      _compareRangeA = _compareRangeB;
      _compareRangeB = previousA;
    });
  }

  void _setRange(DateTimeRange range) {
    final available = _data.granularitiesFor(range);
    setState(() {
      _dateRange = range;
      if (!available.contains(_trendGranularity)) {
        _trendGranularity = available.last;
      }
    });
  }
}

String _millions(double v) => '${v.toStringAsFixed(1)}M';

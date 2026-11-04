import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Gross profit drill-down: profit trend, category breakdown and product
/// profitability.
class GrossProfitPage extends StatefulWidget {
  const GrossProfitPage({super.key});

  @override
  State<GrossProfitPage> createState() => _GrossProfitPageState();
}

class _GrossProfitPageState extends State<GrossProfitPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _trendGranularity = 'Daily';
  String _chartType = 'Line';

  /// The two independent ranges behind the Period Comparison table. They are
  /// deliberately separate from the trend range so any period can be compared
  /// with any other, not just this month and last month.
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
                label: 'Total Gross Profit',
                value: '9.7M',
                sub: '↑ 8.5% vs prev',
              ),
              AnalysisKpiCard(
                label: 'Gross Profit Margin',
                value: '34%',
                sub: 'Gross Profit / Revenue',
              ),
              AnalysisKpiCard(
                label: 'Total Revenue',
                value: '28.5M',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Total COGS',
                value: '18.8M',
                sub: 'Cost of products sold',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Gross Profit Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.grossProfitTrendBuckets(
              _dateRange,
              _trendGranularity,
            ),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.grossProfitDailyValue,
            ),
            // Profit stays green: the filters and candle view match Revenue
            // and COGS, while the series and caption remain gross profit.
            lineColor: AppColors.green,
            axisLabel: (v) => _data.money(v),
            money: (v) => _data.money(v),
            metricLabel: 'gross profit',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Gross Profit by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [4.2, 2.8, 1.8, 0.9]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Revenue', 'COGS', 'Gross Profit'],
            rows: [
              ['Electronics', '13.5M', '9.3M', '4.2M'],
              ['Accessories', '8.2M', '5.4M', '2.8M'],
              ['Computer', '4.5M', '2.7M', '1.8M'],
              ['Others', '2.3M', '1.4M', '0.9M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Product Profitability'),
          const AnalysisTable(
            headers: ['Product', 'Revenue', 'COGS', 'Gross Profit', 'Margin'],
            rows: [
              ['Headphones', '500,000', '300,000', '200,000', '40%'],
              ['Keyboard', '350,000', '200,000', '150,000', '42.9%'],
              ['Mouse', '200,000', '150,000', '50,000', '25%'],
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
    final a = _data.grossProfitStatsFor(_compareRangeA);
    final b = _data.grossProfitStatsFor(_compareRangeB);
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
          // Four columns, two of them date spans: let phones scroll the table
          // sideways instead of squeezing the figures into unreadable cells.
          minTableWidth: 560,
          rows: [
            [
              'Gross Profit',
              _data.money(a.grossProfit),
              _data.money(b.grossProfit),
              _data.change(a.grossProfit, b.grossProfit),
            ],
            [
              'Gross Profit Margin',
              '${a.margin.asPercent(1)}%',
              '${b.margin.asPercent(1)}%',
              _data.change(a.margin, b.margin),
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
          ],
        ),
        const SizedBox(height: 8),
        const AnalysisNote(
          'Pick any two ranges with the calendar buttons. Change compares '
          'Range A with Range B; amounts are in MMK.',
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
      // The selected granularity can disappear when the range shrinks; fall
      // back to the coarsest one the new range still supports.
      if (!available.contains(_trendGranularity)) {
        _trendGranularity = available.last;
      }
    });
  }
}

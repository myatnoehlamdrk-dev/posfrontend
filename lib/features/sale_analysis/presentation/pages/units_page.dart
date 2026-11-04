import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Units sold drill-down: trend, category units and product performance.
class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _trendGranularity = 'Daily';
  String _chartType = 'Line';

  /// The two independent ranges behind the Period Comparison table, matching
  /// the COGS, Gross Profit and Margin comparisons.
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
                label: 'Total Units Sold',
                value: '1,250',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Avg Units per Sale',
                value: '7',
                sub: 'Units ÷ transactions',
              ),
              AnalysisKpiCard(
                label: 'Best-Selling Product',
                value: 'Headphones',
                sub: '300 units',
              ),
              AnalysisKpiCard(
                label: 'Best-Selling Category',
                value: 'Electronics',
                sub: '520 units',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Units Sold Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.unitsTrendBuckets(_dateRange, _trendGranularity),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.unitsDailyValue,
            ),
            lineColor: AppColors.brandPurple,
            axisLabel: _wholeNumber,
            money: _wholeNumber,
            // Units are counts, so the candle scale must not read like money.
            candleAxisLabel: _wholeNumber,
            metricLabel: 'units sold',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Units Sold by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [520, 300, 240, 190]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Units Sold', 'Revenue'],
            rows: [
              ['Electronics', '520', '13.5M'],
              ['Accessories', '300', '8.2M'],
              ['Computer', '240', '4.5M'],
              ['Others', '190', '2.3M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Product Sales Performance'),
          const AnalysisTable(
            headers: ['Product', 'Units Sold', 'Revenue', '% of Total Units'],
            rows: [
              ['Product A', '250', '2,500,000', '50%'],
              ['Product B', '150', '1,500,000', '30%'],
              ['Product C', '100', '1,000,000', '20%'],
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
    final a = _data.unitsStatsFor(_compareRangeA);
    final b = _data.unitsStatsFor(_compareRangeB);
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
              'Total units sold',
              a.unitsSold.withCommas(),
              b.unitsSold.withCommas(),
              _data.change(a.unitsSold.toDouble(), b.unitsSold.toDouble()),
            ],
            [
              'Best-selling product',
              a.bestSellingProduct,
              b.bestSellingProduct,
              '—',
            ],
            [
              'Best-selling category',
              a.bestSellingCategory,
              b.bestSellingCategory,
              '—',
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
      // The selected granularity can disappear when the range shrinks; fall
      // back to the coarsest one the new range still supports.
      if (!available.contains(_trendGranularity)) {
        _trendGranularity = available.last;
      }
    });
  }
}

String _wholeNumber(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

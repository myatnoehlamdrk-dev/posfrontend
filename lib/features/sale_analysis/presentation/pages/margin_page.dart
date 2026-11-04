import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Margin drill-down: trend, category margins and product margin analysis.
class MarginPage extends StatefulWidget {
  const MarginPage({super.key});

  @override
  State<MarginPage> createState() => _MarginPageState();
}

class _MarginPageState extends State<MarginPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _trendGranularity = 'Daily';

  /// The two independent ranges behind the Margin Comparison table, matching
  /// the COGS and Gross Profit comparisons.
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
                label: 'Avg Profit Margin',
                value: '34%',
                sub: 'Overall gross margin',
              ),
              AnalysisKpiCard(
                label: 'Highest Margin',
                value: 'Keyboard',
                sub: '42.9%',
              ),
              AnalysisKpiCard(
                label: 'Lowest Margin',
                value: 'Mouse',
                sub: '25%',
              ),
              AnalysisKpiCard(
                label: 'Total Gross Profit',
                value: '9.7M',
                sub: 'Before operating expenses',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Margin Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: 'Line',
            // Margin is a percentage, so there is no meaningful candle view.
            chartTypes: const ['Line'],
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.marginTrendBuckets(_dateRange, _trendGranularity),
            lineColor: AppColors.orange,
            axisLabel: _percent,
            money: _data.money,
            metricLabel: 'margin',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Margin by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [31, 34, 40, 39]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Revenue', 'COGS', 'Gross Profit', 'Margin'],
            rows: [
              ['Electronics', '13.5M', '9.3M', '4.2M', '31%'],
              ['Accessories', '8.2M', '5.4M', '2.8M', '34%'],
              ['Computer', '4.5M', '2.7M', '1.8M', '40%'],
              ['Others', '2.3M', '1.4M', '0.9M', '39%'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Product Margin Analysis'),
          const AnalysisTable(
            headers: [
              'Product',
              'Selling Price',
              'Unit Cost',
              'Gross Profit',
              'Margin',
            ],
            rows: [
              ['Product A', '10,000', '6,000', '4,000', '40%'],
              ['Product B', '15,000', '9,000', '6,000', '40%'],
              ['Product C', '8,000', '6,000', '2,000', '25%'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Margin Comparison'),
          _periodComparison(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _periodComparison() {
    final a = _data.marginStatsFor(_compareRangeA);
    final b = _data.marginStatsFor(_compareRangeB);
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
              'Avg Profit Margin',
              '${a.overall.asPercent(1)}%',
              '${b.overall.asPercent(1)}%',
              _marginChange(a.overall, b.overall),
            ],
            [
              'Electronics Margin',
              '${a.electronics.asPercent(1)}%',
              '${b.electronics.asPercent(1)}%',
              _marginChange(a.electronics, b.electronics),
            ],
            [
              'Accessories Margin',
              '${a.accessories.asPercent(1)}%',
              '${b.accessories.asPercent(1)}%',
              _marginChange(a.accessories, b.accessories),
            ],
            [
              'Computer Margin',
              '${a.computer.asPercent(1)}%',
              '${b.computer.asPercent(1)}%',
              _marginChange(a.computer, b.computer),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const AnalysisNote(
          'Pick any two ranges with the calendar buttons. Change compares '
          'Range A with Range B in percentage points.',
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

  /// Margin is already a percentage, so its change is a difference in
  /// percentage points rather than a relative percentage.
  String _marginChange(double a, double b) {
    final delta = a - b;
    if (delta.abs() < 0.05) return '—';
    return '${delta > 0 ? '↑' : '↓'} ${delta.abs().asPercent(1)}%';
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

String _percent(double v) => '${v.toInt()}%';

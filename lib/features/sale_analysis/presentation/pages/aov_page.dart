import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Average order value drill-down: trend, category AOV and value distribution.
class AovPage extends StatefulWidget {
  const AovPage({super.key});

  @override
  State<AovPage> createState() => _AovPageState();
}

class _AovPageState extends State<AovPage> {
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
                label: 'Average Order Value',
                value: '83.3K',
                sub: 'Revenue ÷ transactions',
              ),
              AnalysisKpiCard(
                label: 'Highest Order Value',
                value: 'INV-045',
                sub: '250,000',
              ),
              AnalysisKpiCard(
                label: 'Lowest Order Value',
                value: 'INV-012',
                sub: '12,000',
              ),
              AnalysisKpiCard(
                label: 'Total Revenue',
                value: '15M',
                sub: 'Completed sales',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('AOV Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.aovTrendBuckets(_dateRange, _trendGranularity),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.aovDailyValue,
            ),
            lineColor: AppColors.teal,
            axisLabel: _thousands,
            money: _thousands,
            candleAxisLabel: _thousands,
            metricLabel: 'AOV',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('AOV by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [120, 95, 80, 60]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Avg Order Value'],
            rows: [
              ['Electronics', '120,000'],
              ['Accessories', '95,000'],
              ['Computer', '80,000'],
              ['Others', '60,000'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Transaction Value Distribution'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [35, 50, 25, 10]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Transaction Range', 'Number of Transactions'],
            rows: [
              ['Under 20,000', '35'],
              ['20,000–50,000', '50'],
              ['50,001–100,000', '25'],
              ['Above 100,000', '10'],
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
    final a = _data.aovStatsFor(_compareRangeA);
    final b = _data.aovStatsFor(_compareRangeB);
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
          minTableWidth: 560,
          rows: [
            [
              'Average Order Value',
              '${a.aov.toStringAsFixed(1)}K',
              '${b.aov.toStringAsFixed(1)}K',
              _data.change(a.aov, b.aov),
            ],
            [
              'Total revenue',
              _data.money(a.revenue),
              _data.money(b.revenue),
              _data.change(a.revenue, b.revenue),
            ],
            [
              'Transaction count',
              a.transactions.withCommas(),
              b.transactions.withCommas(),
              _data.change(
                a.transactions.toDouble(),
                b.transactions.toDouble(),
              ),
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

String _thousands(double v) => '${v.toInt()}K';

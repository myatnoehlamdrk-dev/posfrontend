import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Average units per transaction drill-down.
class AvgUnitsPage extends StatefulWidget {
  const AvgUnitsPage({super.key});

  @override
  State<AvgUnitsPage> createState() => _AvgUnitsPageState();
}

class _AvgUnitsPageState extends State<AvgUnitsPage> {
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
                label: 'Avg Units per Transaction',
                value: '2.5',
                sub: 'Units ÷ transactions',
              ),
              AnalysisKpiCard(
                label: 'Total Units Sold',
                value: '450',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Total Transactions',
                value: '180',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Highest Units per Txn',
                value: '8 units',
                sub: 'Single transaction',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Avg Units per Transaction Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.avgUnitsTrendBuckets(_dateRange, _trendGranularity),
            lineColor: AppColors.orange,
            axisLabel: _oneDecimal,
            money: _oneDecimal,
            candleAxisLabel: _oneDecimal,
            metricLabel: 'avg units per txn',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Avg Units by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [3, 2.2, 1.8, 1.5]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Avg Units per Txn'],
            rows: [
              ['Electronics', '3.0'],
              ['Accessories', '2.2'],
              ['Computer', '1.8'],
              ['Others', '1.5'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Transaction Quantity Distribution'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [40, 55, 25, 10]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Units per Transaction', 'Transactions'],
            rows: [
              ['1 unit', '40'],
              ['2–3 units', '55'],
              ['4–5 units', '25'],
              ['More than 5 units', '10'],
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
    final a = _data.avgUnitsStatsFor(_compareRangeA);
    final b = _data.avgUnitsStatsFor(_compareRangeB);
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
              'Avg units per txn',
              a.avgUnits.toStringAsFixed(1),
              b.avgUnits.toStringAsFixed(1),
              _data.change(a.avgUnits, b.avgUnits),
            ],
            [
              'Total units sold',
              a.totalUnits.withCommas(),
              b.totalUnits.withCommas(),
              _data.change(a.totalUnits.toDouble(), b.totalUnits.toDouble()),
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

String _oneDecimal(double v) => v.toStringAsFixed(1);

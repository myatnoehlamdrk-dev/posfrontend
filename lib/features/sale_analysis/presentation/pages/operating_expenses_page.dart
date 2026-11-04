import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Operating expenses drill-down: trend, category mix and expense history.
class OperatingExpensesPage extends StatefulWidget {
  const OperatingExpensesPage({super.key});

  @override
  State<OperatingExpensesPage> createState() => _OperatingExpensesPageState();
}

class _OperatingExpensesPageState extends State<OperatingExpensesPage> {
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
                label: 'Total Operating Expenses',
                value: '2M',
                sub: 'Selected period',
              ),
              AnalysisKpiCard(
                label: 'Expense Ratio',
                value: '13.3%',
                sub: 'Expenses ÷ Revenue × 100',
              ),
              AnalysisKpiCard(
                label: 'Avg Daily Expense',
                value: '66.7K',
                sub: 'Expenses ÷ days',
              ),
              AnalysisKpiCard(
                label: 'Highest Expense Category',
                value: 'Rent',
                sub: '300,000',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Expense Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.operatingExpensesTrendBuckets(
              _dateRange,
              _trendGranularity,
            ),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.operatingExpensesDailyValue,
            ),
            lineColor: AppColors.red,
            axisLabel: _millions,
            money: _millions,
            metricLabel: 'expenses',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Expense by Category'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(
              values: [300, 150, 80, 60, 40, 30, 20, 120],
            ),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Category', 'Amount'],
            rows: [
              ['Rent', '300,000'],
              ['Staff salaries', '150,000'],
              ['Electricity and water', '80,000'],
              ['Internet and phone', '60,000'],
              ['Transportation', '40,000'],
              ['Maintenance', '30,000'],
              ['Marketing', '20,000'],
              ['Other expenses', '120,000'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Expense History'),
          AnalysisFilterRow(
            label: 'Category',
            options: const [
              'All',
              'Rent',
              'Salaries',
              'Utilities',
              'Internet',
              'Transport',
              'Maintenance',
              'Marketing',
              'Other',
            ],
            selected: 'All',
            onSelect: (_) {},
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Date', 'Description', 'Category', 'Amount'],
            rows: [
              ['Nov 01', 'Shop rent', 'Rent', '300,000'],
              ['Nov 03', 'Electricity bill', 'Utilities', '50,000'],
              ['Nov 05', 'Internet bill', 'Internet', '30,000'],
            ],
            minTableWidth: 720,
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
    final a = _data.operatingExpensesStatsFor(_compareRangeA);
    final b = _data.operatingExpensesStatsFor(_compareRangeB);
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
              'Total Operating Expenses',
              _data.money(a.totalExpenses),
              _data.money(b.totalExpenses),
              _data.change(a.totalExpenses, b.totalExpenses),
            ],
            [
              'Expense Ratio',
              '${a.expenseRatio.asPercent(1)}%',
              '${b.expenseRatio.asPercent(1)}%',
              _data.change(a.expenseRatio, b.expenseRatio),
            ],
            [
              'Avg Daily Expense',
              _data.money(a.avgDailyExpense),
              _data.money(b.avgDailyExpense),
              _data.change(a.avgDailyExpense, b.avgDailyExpense),
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

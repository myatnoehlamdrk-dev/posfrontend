import 'package:flutter/material.dart';
import 'package:posfrontend/core/extensions/number_extensions.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

/// Transactions drill-down: volume trend, payment mix and transaction history.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
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
                label: 'Total Transactions',
                value: '180',
                sub: 'Completed sales',
              ),
              AnalysisKpiCard(
                label: 'Avg Transaction Value',
                value: '83.3K',
                sub: 'Revenue ÷ transactions',
              ),
              AnalysisKpiCard(
                label: 'Highest Transaction',
                value: 'INV-045',
                sub: '250,000',
              ),
              AnalysisKpiCard(
                label: 'Pending Payments',
                value: '12',
                sub: 'Unpaid balances',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote('Illustrative values in MMK.'),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Transaction Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.transactionsTrendBuckets(
              _dateRange,
              _trendGranularity,
            ),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.transactionsDailyValue,
            ),
            lineColor: AppColors.blue,
            axisLabel: _wholeNumber,
            money: _wholeNumber,
            // Transaction counts are not money, so the candle scale must not
            // read like it.
            candleAxisLabel: _wholeNumber,
            metricLabel: 'transactions',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('By Payment Method'),
          const SizedBox(
            height: 200,
            child: AnalysisBarChart(values: [78, 56, 34, 12]),
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: ['Payment Method', 'Transactions', 'Collected'],
            rows: [
              ['Cash', '78', '11.7M'],
              ['Bank transfer', '56', '8.4M'],
              ['Mobile payment', '34', '5.1M'],
              ['Credit', '12', '1.8M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('By Payment Status'),
          const AnalysisTable(
            headers: ['Status', 'Transactions', 'Amount'],
            rows: [
              ['Paid', '160', '24M'],
              ['Partial', '8', '1.2M'],
              ['Unpaid', '12', '1.8M'],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Transaction History'),
          AnalysisFilterRow(
            label: 'Payment',
            options: const ['All', 'Cash', 'Bank', 'Mobile', 'Credit'],
            selected: 'All',
            onSelect: (_) {},
          ),
          const SizedBox(height: 4),
          AnalysisFilterRow(
            label: 'Status',
            options: const ['All', 'Paid', 'Partial', 'Unpaid'],
            selected: 'All',
            onSelect: (_) {},
          ),
          const SizedBox(height: 8),
          const AnalysisTable(
            headers: [
              'Voucher No.',
              'Date',
              'Customer',
              'Payment Method',
              'Total Amount',
              'Status',
            ],
            rows: [
              ['INV-001', 'Nov 01', 'Customer A', 'Cash', '50,000', 'Paid'],
              ['INV-002', 'Nov 01', 'Customer B', 'KPay', '80,000', 'Paid'],
              ['INV-003', 'Nov 02', 'Customer C', 'Cash', '35,000', 'Partial'],
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
    final a = _data.transactionsStatsFor(_compareRangeA);
    final b = _data.transactionsStatsFor(_compareRangeB);
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
              'Transaction count',
              a.transactions.withCommas(),
              b.transactions.withCommas(),
              _data.change(
                a.transactions.toDouble(),
                b.transactions.toDouble(),
              ),
            ],
            [
              'Avg transaction value',
              _data.money(a.avgTransactionValue),
              _data.money(b.avgTransactionValue),
              _data.change(a.avgTransactionValue, b.avgTransactionValue),
            ],
            [
              'Pending payments',
              a.pendingPayments.withCommas(),
              b.pendingPayments.withCommas(),
              _data.change(
                a.pendingPayments.toDouble(),
                b.pendingPayments.toDouble(),
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

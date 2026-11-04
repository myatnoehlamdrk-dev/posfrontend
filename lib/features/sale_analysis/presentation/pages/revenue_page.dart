import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/data/sale_analysis_demo_data.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_bar_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/trend_chart_panel.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Revenue drill-down: KPI cards, trend chart, breakdowns, comparison and the
/// filterable transaction table.
class RevenueAnalysisPage extends StatefulWidget {
  const RevenueAnalysisPage({super.key});

  @override
  State<RevenueAnalysisPage> createState() => _RevenueAnalysisPageState();
}

class _RevenueAnalysisPageState extends State<RevenueAnalysisPage> {
  static const SaleAnalysisDemoData _data = SaleAnalysisDemoData();

  /// Demo "current month". Picking a range replaces it, and the granularity
  /// chips below are derived from whatever range is active.
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );

  /// Daily, plus Weekly/Monthly only when the range actually contains a whole
  /// week or whole month. A "Weekly" view over four days is not a week.
  String _trendGranularity = 'Daily';

  /// Line is the default; candles add an OHLC view of the same buckets.
  String _chartType = 'Line';

  /// Baseline for the comparison table. The user can compare against the
  /// preceding period, the same dates last year, or any range they pick.
  String _compareMode = 'Previous period';
  DateTimeRange? _customCompareRange;

  /// Transaction rows are filtered by an explicit range, not preset buckets.
  DateTimeRange _transactionRange = DateTimeRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 30),
  );
  String _payFilter = 'All';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = _data.statsFor(_dateRange);
    final prev = _data.statsFor(_data.previousPeriod(_dateRange));
    final vsPrev = _data.change(now.revenue, prev.revenue);
    final compare = _comparisonRange;
    final compareStats = _data.statsFor(compare);
    final vsCompare = _data.change(now.revenue, compareStats.revenue);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AnalysisKpiCard(
                label: 'Total Revenue',
                value: _data.money(now.revenue),
                sub: vsPrev == '—' ? '—' : '$vsPrev vs prev',
              ),
              AnalysisKpiCard(
                label: 'Gross Profit',
                value: _data.money(now.grossProfit),
                sub: _data.change(now.grossProfit, prev.grossProfit),
              ),
              AnalysisKpiCard(
                label: 'Transactions',
                value: '${now.transactions}',
                sub: _data.change(
                  now.transactions.toDouble(),
                  prev.transactions.toDouble(),
                ),
              ),
              AnalysisKpiCard(
                label: 'Avg Order Value',
                value: _data.money(now.aov / 1000000),
                sub: _data.change(now.aov, prev.aov),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote(
            'Illustrative figures only. Revenue and profit in MMK.',
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Revenue Trend'),
          TrendChartPanel(
            dateRange: _dateRange,
            granularity: _trendGranularity,
            chartType: _chartType,
            granularities: _data.granularitiesFor(_dateRange),
            buckets: _data.trendBuckets(_dateRange, _trendGranularity),
            candleOhlc: _data.candleBuckets(
              _dateRange,
              _trendGranularity,
              _data.dailyValue,
            ),
            lineColor: AppColors.brandPurple,
            axisLabel: (v) => _data.money(v),
            money: (v) => _data.money(v),
            metricLabel: 'revenue',
            rangeLabel: _data.rangeLabelFor(_dateRange),
            onRangePicked: _setRange,
            onGranularityChanged: (g) => setState(() => _trendGranularity = g),
            onChartTypeChanged: (t) => setState(() => _chartType = t),
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Revenue by Category'),
          Text(
            'Total: ${_data.money(now.revenue)} MMK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: AnalysisBarChart(
              values: [
                for (final share in SaleAnalysisDemoData.categoryShares)
                  now.revenue * share,
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnalysisTable(
            headers: const ['Category', 'Revenue'],
            rows: [
              for (
                var i = 0;
                i < SaleAnalysisDemoData.categoryNames.length;
                i++
              )
                [
                  SaleAnalysisDemoData.categoryNames[i],
                  _data.money(
                    now.revenue * SaleAnalysisDemoData.categoryShares[i],
                  ),
                ],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Top Selling Products'),
          AnalysisTable(
            headers: const ['Product', 'Qty', 'Revenue'],
            rows: [
              for (final product in SaleAnalysisDemoData.topProducts)
                [
                  product.$1,
                  '${(now.revenue * product.$2 / (now.aov / 1000000)).round()}',
                  _data.money(now.revenue * product.$2),
                ],
            ],
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Revenue by Payment Method'),
          AnalysisTable(
            headers: const ['Method', 'Collected'],
            rows: [
              for (var i = 0; i < SaleAnalysisDemoData.paymentNames.length; i++)
                [
                  SaleAnalysisDemoData.paymentNames[i],
                  _data.money(
                    now.revenue * SaleAnalysisDemoData.paymentShares[i],
                  ),
                ],
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote(
            'Payment-method breakdown shows collected payments separately from '
            'sales revenue, especially for credit sales.',
            italic: true,
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Revenue Comparison'),
          Wrap(
            spacing: 6,
            children: [
              for (final mode in const [
                'Previous period',
                'Same period last year',
                'Custom range',
              ])
                ChoiceChip(
                  label: Text(mode, style: const TextStyle(fontSize: 11)),
                  selected: _compareMode == mode,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _selectCompareMode(mode),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_data.rangeLabelFor(_dateRange)} vs '
                  '${_data.rangeLabelFor(compare)}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range, size: 20),
                tooltip: 'Pick comparison range',
                onPressed: _pickComparisonRange,
              ),
            ],
          ),
          AnalysisTable(
            headers: const ['Period', 'Revenue', 'Change'],
            rows: [
              [
                _data.rangeLabelFor(_dateRange),
                _data.money(now.revenue),
                vsCompare,
              ],
              [
                _data.rangeLabelFor(compare),
                _data.money(compareStats.revenue),
                '—',
              ],
            ],
          ),
          const SizedBox(height: 8),
          const AnalysisNote(
            'Change compares total revenue for the selected range with the '
            'chosen comparison range. Pick any two ranges — month against '
            'month, year against year — with the chips or the date button.',
          ),
          const SizedBox(height: 16),
          const AnalysisSectionTitle('Transaction Details'),
          _transactionDateRow(),
          const SizedBox(height: 4),
          AnalysisFilterRow(
            label: 'Payment',
            options: const ['All', 'Cash', 'Bank', 'Mobile', 'Credit'],
            selected: _payFilter,
            onSelect: (v) => setState(() => _payFilter = v),
          ),
          const SizedBox(height: 4),
          AnalysisFilterRow(
            label: 'Status',
            options: const ['All', 'Completed', 'Pending'],
            selected: _statusFilter,
            onSelect: (v) => setState(() => _statusFilter = v),
          ),
          const SizedBox(height: 8),
          _transactionTable(),
          const SizedBox(height: 8),
          const AnalysisNote(
            'Search voucher · Pick date range · Filter payment/status · '
            'Open voucher · Paginate/export',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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

  /// The range currently being compared against the selected one.
  DateTimeRange get _comparisonRange {
    if (_compareMode == 'Custom range' && _customCompareRange != null) {
      return _customCompareRange!;
    }
    if (_compareMode == 'Same period last year') {
      return _data.sameRangeLastYear(_dateRange);
    }
    return _data.previousPeriod(_dateRange);
  }

  Future<void> _selectCompareMode(String mode) async {
    if (mode != 'Custom range') {
      setState(() => _compareMode = mode);
      return;
    }
    await _pickComparisonRange();
  }

  Future<void> _pickComparisonRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: _comparisonRange,
    );
    if (picked == null) return;
    setState(() {
      _compareMode = 'Custom range';
      _customCompareRange = picked;
    });
  }

  /// The chips above the table only set filter state; this is where that state
  /// is read. A chip that changes nothing on screen reads as a broken control.
  List<List<String>> get _visibleTransactions =>
      SaleAnalysisDemoData.transactions.where((row) {
        final date = _data.parseIso(row[1]);
        final start = DateUtils.dateOnly(_transactionRange.start);
        final end = DateUtils.dateOnly(_transactionRange.end);
        final dateOk = !date.isBefore(start) && !date.isAfter(end);
        if (!dateOk) return false;
        if (_payFilter != 'All' && row[3] != _payFilter) return false;
        if (_statusFilter != 'All' && row[4] != _statusFilter) return false;
        return true;
      }).toList();

  /// The table's date filter is a real range picker, not preset buckets.
  Widget _transactionDateRow() {
    final p = context.palette;
    return Row(
      children: [
        Text('Date: ', style: TextStyle(fontSize: 12, color: p.textSecondary)),
        OutlinedButton.icon(
          onPressed: _pickTransactionRange,
          icon: const Icon(Icons.date_range, size: 14),
          label: Text(
            _data.rangeLabelFor(_transactionRange),
            style: const TextStyle(fontSize: 11),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _pickTransactionRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _transactionRange,
      helpText: 'Filter transactions',
    );
    if (picked != null) setState(() => _transactionRange = picked);
  }

  Widget _transactionTable() {
    final visible = _visibleTransactions;
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No transactions match these filters.',
          style: TextStyle(fontSize: 12, color: context.palette.textMuted),
        ),
      );
    }
    return AnalysisTable(
      headers: const [
        'Voucher',
        'Date',
        'Customer',
        'Payment',
        'Status',
        'Amount',
      ],
      rows: [
        for (final row in visible)
          [row[0], _data.shortDate(row[1]), row[2], row[3], row[4], row[5]],
      ],
      // Six columns in 360px squeezes each cell to ~50px, so every value
      // wraps to two lines. Let this one scroll sideways instead.
      minTableWidth: 560,
    );
  }
}

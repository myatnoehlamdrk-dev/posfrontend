import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';

class SaleAnalysisDetailScreen extends StatefulWidget {
  final String metric;
  const SaleAnalysisDetailScreen({super.key, required this.metric});

  @override
  State<SaleAnalysisDetailScreen> createState() =>
      _SaleAnalysisDetailScreenState();
}

class _SaleAnalysisDetailScreenState extends State<SaleAnalysisDetailScreen> {
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

  /// Candle under the pointer, so the OHLC legend can read like a terminal.
  int? _hoveredCandle;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Demo mix of the total. Shares, not absolute amounts, so the breakdowns
  /// always add up to whatever the selected range totals.
  static const List<String> _categoryNames = [
    'Electronics',
    'Accessories',
    'Computer',
    'Others',
  ];
  static const List<double> _categoryShares = [0.4467, 0.2667, 0.18, 0.1066];

  static const List<String> _paymentNames = [
    'Cash',
    'Bank transfer',
    'Mobile payment',
    'Credit',
  ];
  static const List<double> _paymentShares = [0.4467, 0.2667, 0.18, 0.1066];

  /// Product and its share of total revenue.
  static const List<(String, double)> _topProducts = [
    ('Headphones', 0.26),
    ('Keyboard', 0.1733),
    ('Mouse', 0.1333),
  ];

  String get _title {
    switch (widget.metric) {
      case 'revenue':
        return 'Revenue Analysis';
      case 'cogs':
        return 'COGS Detail';
      case 'grossProfit':
        return 'Gross Profit Detail';
      case 'margin':
        return 'Margin Detail';
      case 'units':
        return 'Units Sold Detail';
      case 'transactions':
        return 'Transactions Detail';
      case 'aov':
        return 'Average Order Value Detail';
      case 'netProfit':
        return 'Net Profit Detail';
      default:
        return 'Detail';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppShell(
      active: DrawerDestination.saleAnalysis,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      // Back, not menu: this screen is a drill-down from Sale Analysis, and
      // every other pushed detail screen in the app does the same. On a narrow
      // window it used to show the hamburger and no back button, so the only
      // way back to the overview was the drawer or the system back gesture.
      body: (context, _) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: _title,
              showBackButton: true,
              showMenuButton: false,
            ),
            Expanded(
              child:
                  widget.metric == 'revenue'
                      ? _revenuePage()
                      : widget.metric == 'cogs'
                          ? _cogsPage()
                          : widget.metric == 'grossProfit'
                              ? _grossProfitPage()
                              : widget.metric == 'margin'
                                  ? _marginPage()
                              : widget.metric == 'units'
                                  ? _unitsPage()
                              : widget.metric == 'transactions'
                                  ? _transactionsPage()
                              : widget.metric == 'aov'
                                  ? _aovPage()
                              : widget.metric == 'avgUnits'
                                  ? _avgUnitsPage()
                              : widget.metric == 'netProfit'
                                  ? _operatingExpensesPage()
                              : widget.metric == 'netProfit'
                                  ? _netProfitPage()
                              : _genericPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revenuePage() {
    final p = context.palette;
    // Every figure on this page comes from the same demo daily series, so the
    // KPIs, breakdowns and comparisons all move together with the picked range.
    // Comparing a range against itself is how you get a page that says 15M at
    // the top and 13.3M in the table below.
    final now = _statsFor(_dateRange);
    final prev = _statsFor(_previousPeriod(_dateRange));
    final vsPrev = _change(now.revenue, prev.revenue);
    final compare = _comparisonRange;
    final compareStats = _statsFor(compare);
    final vsCompare = _change(now.revenue, compareStats.revenue);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Revenue', _money(now.revenue),
                  vsPrev == '—' ? '—' : '$vsPrev vs prev'),
              _kpiCard('Gross Profit', _money(now.grossProfit),
                  _change(now.grossProfit, prev.grossProfit)),
              _kpiCard('Transactions', '${now.transactions}',
                  _change(now.transactions.toDouble(), prev.transactions.toDouble())),
              _kpiCard('Avg Order Value', _money(now.aov / 1000000),
                  _change(now.aov, prev.aov)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Illustrative figures only. Revenue and profit in MMK.',
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Revenue Trend'),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final g in _granularities)
                      ChoiceChip(
                        label: Text(g, style: const TextStyle(fontSize: 11)),
                        selected: _trendGranularity == g,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) =>
                            setState(() => _trendGranularity = g),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.date_range, size: 20),
                tooltip: 'Pick date range',
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) _setRange(picked);
                },
              ),
            ],
          ),
          Text(
            '$_trendGranularity revenue · ${_rangeLabel()}',
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Chart: ',
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
              for (final type in const ['Line', 'Candles'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 11)),
                    selected: _chartType == type,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() {
                      _chartType = type;
                      _hoveredCandle = null;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            // Candles carry a legend, a volume pane and a time axis, so they
            // need noticeably more room than the line view.
            height: _chartType == 'Candles' ? 420 : 260,
            child: _chartType == 'Candles' ? _candleChart() : _trendChart(),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Revenue by Category'),
          Text(
            'Total: ${_money(now.revenue)} MMK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _categoryBarChart([
              for (final share in _categoryShares) now.revenue * share,
            ]),
          ),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Revenue'],
            rows: [
              for (var i = 0; i < _categoryNames.length; i++)
                [_categoryNames[i], _money(now.revenue * _categoryShares[i])],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Top Selling Products'),
          _simpleTable(
            headers: const ['Product', 'Qty', 'Revenue'],
            rows: [
              for (final product in _topProducts)
                [
                  product.$1,
                  '${(now.revenue * product.$2 / (now.aov / 1000000)).round()}',
                  _money(now.revenue * product.$2),
                ],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Revenue by Payment Method'),
          _simpleTable(
            headers: const ['Method', 'Collected'],
            rows: [
              for (var i = 0; i < _paymentNames.length; i++)
                [_paymentNames[i], _money(now.revenue * _paymentShares[i])],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment-method breakdown shows collected payments separately from sales revenue, especially for credit sales.',
            style: TextStyle(
              fontSize: 11,
              color: p.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Revenue Comparison'),
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
                  '${_rangeLabelFor(_dateRange)} vs ${_rangeLabelFor(compare)}',
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
          _simpleTable(
            headers: const ['Period', 'Revenue', 'Change'],
            rows: [
              [_rangeLabelFor(_dateRange), _money(now.revenue), vsCompare],
              [_rangeLabelFor(compare), _money(compareStats.revenue), '—'],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Change compares total revenue for the selected range with the '
            'chosen comparison range. Pick any two ranges — month against '
            'month, year against year — with the chips or the date button.',
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Transaction Details'),
          _transactionDateRow(),
          const SizedBox(height: 4),
          _filterRow('Payment', const ['All', 'Cash', 'Bank', 'Mobile', 'Credit'], _payFilter,
              (v) => setState(() => _payFilter = v)),
          const SizedBox(height: 4),
          _filterRow('Status', const ['All', 'Completed', 'Pending'], _statusFilter,
              (v) => setState(() => _statusFilter = v)),
          const SizedBox(height: 8),
          _transactionTable(),
          const SizedBox(height: 8),
          Text(
            'Search voucher · Pick date range · Filter payment/status · Open voucher · Paginate/export',
            style: TextStyle(fontSize: 11, color: p.textMuted),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _cogsPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total COGS', '28.5M', '↑ 8.5% vs prev'),
              _kpiCard('COGS Ratio', '62.2%', 'COGS / Revenue'),
              _kpiCard('Units Sold', '1,250', 'Total quantities'),
              _kpiCard('Avg Cost / Unit', '22.8K', 'COGS / units sold'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('COGS Trend'),
          SizedBox(height: 260, child: _cogsTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('COGS by Category'),
          SizedBox(height: 200, child: _cogsPieChart()),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'COGS'],
            rows: const [
              ['Electronics', '13.5M'],
              ['Accessories', '8.2M'],
              ['Computer', '4.5M'],
              ['Others', '2.3M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('COGS by Product'),
          _simpleTable(
            headers: const ['Product', 'Units sold', 'COGS'],
            rows: const [
              ['Headphones', '300', '9M'],
              ['Keyboard', '200', '6M'],
              ['Mouse', '250', '3M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Product Cost Analysis'),
          _simpleTable(
            headers: const ['Product', 'Unit cost', 'Selling price'],
            rows: const [
              ['Headphones', '20,000', '30,000'],
              ['Keyboard', '25,000', '35,000'],
              ['Mouse', '10,000', '15,000'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month'],
            rows: const [
              ['Total COGS', '28.5M', '26M'],
              ['Units sold', '1,250', '1,100'],
              ['Avg cost/unit', '22.8K', '23.6K'],
              ['COGS ratio', '62.2%', '64%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _cogsTrendChart() {
    final p = context.palette;
    const vals = [0.7, 1.05, 0.9, 1.4, 1.75, 1.2, 2.1, 1.6];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: AppColors.red, barWidth: 3, belowBarData: BarAreaData(show: true, color: AppColors.red.withValues(alpha: 0.15))),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _cogsPieChart() {
    final sections = [
      PieChartSectionData(value: 13.5, color: AppColors.brandPurple, title: 'Electronics'),
      PieChartSectionData(value: 8.2, color: AppColors.teal, title: 'Accessories'),
      PieChartSectionData(value: 4.5, color: AppColors.orange, title: 'Computer'),
      PieChartSectionData(value: 2.3, color: AppColors.blue, title: 'Others'),
    ];
    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 30));
  }

  Widget _grossProfitPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Gross Profit', '9.7M', '↑ 8.5% vs prev'),
              _kpiCard('Gross Profit Margin', '34%', 'Gross Profit / Revenue'),
              _kpiCard('Total Revenue', '28.5M', 'Completed sales'),
              _kpiCard('Total COGS', '18.8M', 'Cost of products sold'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Gross Profit Trend'),
          SizedBox(height: 260, child: _grossProfitTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Gross Profit by Category'),
          SizedBox(height: 200, child: _categoryBarChart([4.2, 2.8, 1.8, 0.9])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Revenue', 'COGS', 'Gross Profit'],
            rows: const [
              ['Electronics', '13.5M', '9.3M', '4.2M'],
              ['Accessories', '8.2M', '5.4M', '2.8M'],
              ['Computer', '4.5M', '2.7M', '1.8M'],
              ['Others', '2.3M', '1.4M', '0.9M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Product Profitability'),
          _simpleTable(
            headers: const ['Product', 'Revenue', 'COGS', 'Gross Profit', 'Margin'],
            rows: const [
              ['Headphones', '500,000', '300,000', '200,000', '40%'],
              ['Keyboard', '350,000', '200,000', '150,000', '42.9%'],
              ['Mouse', '200,000', '150,000', '50,000', '25%'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Gross Profit', '9.7M', '8.9M', '↑ 9%'],
              ['Gross Profit Margin', '34%', '32%', '↑ 2%'],
              ['Revenue', '28.5M', '26M', '↑ 9.6%'],
              ['COGS', '18.8M', '17.1M', '↑ 9.9%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _grossProfitTrendChart() {
    final p = context.palette;
    const vals = [0.6, 0.9, 0.7, 1.1, 1.3, 0.8, 1.2, 1.5];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.green.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _marginPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Avg Profit Margin', '34%', 'Overall gross margin'),
              _kpiCard('Highest Margin', 'Keyboard', '42.9%'),
              _kpiCard('Lowest Margin', 'Mouse', '25%'),
              _kpiCard('Total Gross Profit', '9.7M', 'Before operating expenses'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Margin Trend'),
          SizedBox(height: 260, child: _marginTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Margin by Category'),
          SizedBox(height: 200, child: _categoryBarChart([31, 34, 40, 39])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Revenue', 'COGS', 'Gross Profit', 'Margin'],
            rows: const [
              ['Electronics', '13.5M', '9.3M', '4.2M', '31%'],
              ['Accessories', '8.2M', '5.4M', '2.8M', '34%'],
              ['Computer', '4.5M', '2.7M', '1.8M', '40%'],
              ['Others', '2.3M', '1.4M', '0.9M', '39%'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Product Margin Analysis'),
          _simpleTable(
            headers: const ['Product', 'Selling Price', 'Unit Cost', 'Gross Profit', 'Margin'],
            rows: const [
              ['Product A', '10,000', '6,000', '4,000', '40%'],
              ['Product B', '15,000', '9,000', '6,000', '40%'],
              ['Product C', '8,000', '6,000', '2,000', '25%'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Margin Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Avg Profit Margin', '34%', '32%', '↑ 2%'],
              ['Electronics Margin', '31%', '29%', '↑ 2%'],
              ['Accessories Margin', '34%', '33%', '↑ 1%'],
              ['Computer Margin', '40%', '38%', '↑ 2%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _marginTrendChart() {
    final p = context.palette;
    const vals = [30, 32, 34, 33, 35, 34, 33, 36];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.orange,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.orange.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _unitsPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Units Sold', '1,250', 'Completed sales'),
              _kpiCard('Avg Units per Sale', '7', 'Units ÷ transactions'),
              _kpiCard('Best-Selling Product', 'Headphones', '300 units'),
              _kpiCard('Best-Selling Category', 'Electronics', '520 units'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Units Sold Trend'),
          SizedBox(height: 260, child: _unitsTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Units Sold by Category'),
          SizedBox(height: 200, child: _categoryBarChart([520, 300, 240, 190])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Units Sold', 'Revenue'],
            rows: const [
              ['Electronics', '520', '13.5M'],
              ['Accessories', '300', '8.2M'],
              ['Computer', '240', '4.5M'],
              ['Others', '190', '2.3M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Product Sales Performance'),
          _simpleTable(
            headers: const ['Product', 'Units Sold', 'Revenue', '% of Total Units'],
            rows: const [
              ['Product A', '250', '2,500,000', '50%'],
              ['Product B', '150', '1,500,000', '30%'],
              ['Product C', '100', '1,000,000', '20%'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Total units sold', '1,250', '1,100', '↑ 13.6%'],
              ['Best-selling product', 'Headphones', 'Keyboard', '—'],
              ['Best-selling category', 'Electronics', 'Electronics', '—'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _unitsTrendChart() {
    final p = context.palette;
    const vals = [120, 160, 140, 180, 200, 150, 170, 190];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.brandPurple,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.brandPurple.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _transactionsPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Transactions', '180', 'Completed sales'),
              _kpiCard('Avg Transaction Value', '83.3K', 'Revenue ÷ transactions'),
              _kpiCard('Highest Transaction', 'INV-045', '250,000'),
              _kpiCard('Pending Payments', '12', 'Unpaid balances'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Transaction Trend'),
          SizedBox(height: 260, child: _transactionsTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('By Payment Method'),
          SizedBox(height: 200, child: _categoryBarChart([78, 56, 34, 12])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Payment Method', 'Transactions', 'Collected'],
            rows: const [
              ['Cash', '78', '11.7M'],
              ['Bank transfer', '56', '8.4M'],
              ['Mobile payment', '34', '5.1M'],
              ['Credit', '12', '1.8M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('By Payment Status'),
          _simpleTable(
            headers: const ['Status', 'Transactions', 'Amount'],
            rows: const [
              ['Paid', '160', '24M'],
              ['Partial', '8', '1.2M'],
              ['Unpaid', '12', '1.8M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Transaction History'),
          _filterRow('Payment', const ['All', 'Cash', 'Bank', 'Mobile', 'Credit'], 'All', (_) {}),
          const SizedBox(height: 4),
          _filterRow('Status', const ['All', 'Paid', 'Partial', 'Unpaid'], 'All', (_) {}),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Voucher No.', 'Date', 'Customer', 'Payment Method', 'Total Amount', 'Status'],
            rows: const [
              ['INV-001', 'Nov 01', 'Customer A', 'Cash', '50,000', 'Paid'],
              ['INV-002', 'Nov 01', 'Customer B', 'KPay', '80,000', 'Paid'],
              ['INV-003', 'Nov 02', 'Customer C', 'Cash', '35,000', 'Partial'],
            ],
            minTableWidth: 720,
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Transaction count', '180', '160', '↑ 12.5%'],
              ['Avg transaction value', '83.3K', '78.1K', '↑ 6.7%'],
              ['Pending payments', '12', '15', '↓ 20%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _transactionsTrendChart() {
    final p = context.palette;
    const vals = [6, 9, 7, 11, 13, 8, 10, 12];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.blue,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.blue.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _aovPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Average Order Value', '83.3K', 'Revenue ÷ transactions'),
              _kpiCard('Highest Order Value', 'INV-045', '250,000'),
              _kpiCard('Lowest Order Value', 'INV-012', '12,000'),
              _kpiCard('Total Revenue', '15M', 'Completed sales'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('AOV Trend'),
          SizedBox(height: 260, child: _aovTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('AOV by Category'),
          SizedBox(height: 200, child: _categoryBarChart([120, 95, 80, 60])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Avg Order Value'],
            rows: const [
              ['Electronics', '120,000'],
              ['Accessories', '95,000'],
              ['Computer', '80,000'],
              ['Others', '60,000'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Transaction Value Distribution'),
          SizedBox(height: 200, child: _categoryBarChart([35, 50, 25, 10])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Transaction Range', 'Number of Transactions'],
            rows: const [
              ['Under 20,000', '35'],
              ['20,000–50,000', '50'],
              ['50,001–100,000', '25'],
              ['Above 100,000', '10'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Average Order Value', '83.3K', '78.1K', '↑ 6.7%'],
              ['Total revenue', '15M', '14M', '↑ 7.1%'],
              ['Transaction count', '180', '179', '↑ 0.6%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _aovTrendChart() {
    final p = context.palette;
    const vals = [80, 85, 82, 88, 90, 84, 86, 89];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.teal,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.teal.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _avgUnitsPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Avg Units per Transaction', '2.5', 'Units ÷ transactions'),
              _kpiCard('Total Units Sold', '450', 'Completed sales'),
              _kpiCard('Total Transactions', '180', 'Completed sales'),
              _kpiCard('Highest Units per Txn', '8 units', 'Single transaction'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Avg Units per Transaction Trend'),
          SizedBox(height: 260, child: _avgUnitsTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Avg Units by Category'),
          SizedBox(height: 200, child: _categoryBarChart([3, 2.2, 1.8, 1.5])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Avg Units per Txn'],
            rows: const [
              ['Electronics', '3.0'],
              ['Accessories', '2.2'],
              ['Computer', '1.8'],
              ['Others', '1.5'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Transaction Quantity Distribution'),
          SizedBox(height: 200, child: _categoryBarChart([40, 55, 25, 10])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Units per Transaction', 'Transactions'],
            rows: const [
              ['1 unit', '40'],
              ['2–3 units', '55'],
              ['4–5 units', '25'],
              ['More than 5 units', '10'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Avg units per txn', '2.5', '2.3', '↑ 8.7%'],
              ['Total units sold', '450', '420', '↑ 7.1%'],
              ['Transaction count', '180', '182', '↓ 1.1%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _avgUnitsTrendChart() {
    final p = context.palette;
    const vals = [2.2, 2.5, 2.4, 2.7, 2.9, 2.5, 2.6, 2.8];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.orange,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.orange.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _operatingExpensesPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Operating Expenses', '2M', 'Selected period'),
              _kpiCard('Expense Ratio', '13.3%', 'Expenses ÷ Revenue × 100'),
              _kpiCard('Avg Daily Expense', '66.7K', 'Expenses ÷ days'),
              _kpiCard('Highest Expense Category', 'Rent', '300,000'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Expense Trend'),
          SizedBox(height: 260, child: _expensesTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Expense by Category'),
          SizedBox(height: 200, child: _categoryBarChart([300, 150, 80, 60, 40, 30, 20, 120])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Amount'],
            rows: const [
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
          _sectionTitle('Expense History'),
          _filterRow('Category', const ['All', 'Rent', 'Salaries', 'Utilities', 'Internet', 'Transport', 'Maintenance', 'Marketing', 'Other'], 'All', (_) {}),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Date', 'Description', 'Category', 'Amount'],
            rows: const [
              ['Nov 01', 'Shop rent', 'Rent', '300,000'],
              ['Nov 03', 'Electricity bill', 'Utilities', '50,000'],
              ['Nov 05', 'Internet bill', 'Internet', '30,000'],
            ],
            minTableWidth: 720,
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Total Operating Expenses', '2M', '1.8M', '↑ 11.1%'],
              ['Expense Ratio', '13.3%', '13.8%', '↓ 0.5%'],
              ['Avg Daily Expense', '66.7K', '60K', '↑ 11.1%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _expensesTrendChart() {
    final p = context.palette;
    const vals = [0.3, 0.5, 0.4, 0.6, 0.5, 0.4, 0.6, 0.7];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.red,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.red.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _netProfitPage() {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard('Total Net Profit', '7.7M', 'Revenue − COGS − Expenses'),
              _kpiCard('Net Profit Margin', '27%', 'Net Profit ÷ Revenue × 100'),
              _kpiCard('Total Revenue', '28.5M', 'Completed sales'),
              _kpiCard('Total Expenses', '20.8M', 'COGS + Operating Expenses'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Illustrative values in MMK. Estimated Net Profit — tax, interest and other non-operating items are not deducted.', style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 16),
          _sectionTitle('Net Profit Trend'),
          SizedBox(height: 260, child: _netProfitTrendChart()),
          const SizedBox(height: 16),
          _sectionTitle('Revenue to Net Profit Breakdown'),
          _simpleTable(
            headers: const ['Item', 'Amount'],
            rows: const [
              ['Revenue', '28.5M'],
              ['COGS', '18.8M'],
              ['Gross Profit', '9.7M'],
              ['Operating Expenses', '2M'],
              ['Net Profit', '7.7M'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Net Profit by Category'),
          SizedBox(height: 200, child: _categoryBarChart([3.2, 1.8, 1.3, 1.4])),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Net Profit', 'Margin'],
            rows: const [
              ['Electronics', '3.2M', '24%'],
              ['Accessories', '1.8M', '22%'],
              ['Computer', '1.3M', '29%'],
              ['Others', '1.4M', '61%'],
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Period Comparison'),
          _simpleTable(
            headers: const ['Metric', 'This month', 'Last month', 'Change'],
            rows: const [
              ['Net Profit', '7.7M', '6.8M', '↑ 13.2%'],
              ['Net Profit Margin', '27%', '26%', '↑ 1%'],
              ['Revenue', '28.5M', '26M', '↑ 9.6%'],
              ['COGS', '18.8M', '17.1M', '↑ 9.9%'],
              ['Operating Expenses', '2M', '1.8M', '↑ 11.1%'],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _netProfitTrendChart() {
    final p = context.palette;
    const vals = [0.9, 1.2, 1.0, 1.3, 1.5, 1.1, 1.4, 1.3];
    final spots = vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppColors.green.withValues(alpha: 0.15)),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}M', style: TextStyle(fontSize: 9, color: p.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const labels = ['Nov 1', 'Nov 2', 'Nov 3', 'Nov 4', 'Nov 5', 'Nov 6', 'Nov 7', 'Nov 8'];
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: TextStyle(fontSize: 9, color: p.textMuted));
          })),
        ),
      ),
    );
  }

  Widget _genericPage() {
    final rows = _demoRows(widget.metric);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = rows[i];
        return ListTile(title: Text(r.$1), trailing: Text(r.$2));
      },
    );
  }

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Voucher, ISO date, customer, payment, status, amount.
  /// Amounts average ~84K, the AOV the KPI cards quote.
  static const List<List<String>> _transactions = [
    ['SAL-001', '2026-11-03', 'Customer A', 'Cash', 'Completed', '75,000'],
    ['SAL-002', '2026-11-03', 'Customer B', 'Bank', 'Completed', '62,000'],
    ['SAL-003', '2026-11-03', 'Customer C', 'Credit', 'Pending', '145,000'],
    ['SAL-004', '2026-11-01', 'Customer D', 'Cash', 'Completed', '90,000'],
    ['SAL-005', '2026-10-29', 'Customer E', 'Bank', 'Completed', '48,000'],
  ];

  /// The chips above the table only set filter state; this is where that state
  /// is read. A chip that changes nothing on screen reads as a broken control.
  List<List<String>> get _visibleTransactions => _transactions.where((row) {
        final date = _parseIso(row[1]);
        final start = DateUtils.dateOnly(_transactionRange.start);
        final end = DateUtils.dateOnly(_transactionRange.end);
        final dateOk = !date.isBefore(start) && !date.isAfter(end);
        if (!dateOk) return false;
        if (_payFilter != 'All' && row[3] != _payFilter) return false;
        if (_statusFilter != 'All' && row[4] != _statusFilter) return false;
        return true;
      }).toList();

  DateTime _parseIso(String iso) {
    final parts = iso.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _shortDate(String iso) {
    final d = _parseIso(iso);
    return '${_monthAbbr[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
  }

  /// The table's date filter is a real range picker, not preset buckets.
  Widget _transactionDateRow() {
    final p = context.palette;
    return Row(
      children: [
        Text(
          'Date: ',
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        OutlinedButton.icon(
          onPressed: _pickTransactionRange,
          icon: const Icon(Icons.date_range, size: 14),
          label: Text(
            _rangeLabelFor(_transactionRange),
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
    return _simpleTable(
      headers: const [
        'Voucher', 'Date', 'Customer', 'Payment', 'Status', 'Amount',
      ],
      rows: [
        for (final row in visible)
          [row[0], _shortDate(row[1]), row[2], row[3], row[4], row[5]],
      ],
      // Six columns in 360px squeezes each cell to ~50px, so every value
      // wraps to two lines. Let this one scroll sideways instead.
      minTableWidth: 560,
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.palette.textPrimary,
          ),
        ),
      );

  Widget _kpiCard(String label, String value, String sub) {
    final p = context.palette;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Direction decides the hue, not the copy: a green "↑" on a
              // falling figure is the mistake this avoids.
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: sub.startsWith('↑')
                      ? p.successFg
                      : sub.startsWith('↓')
                          ? p.dangerFg
                          : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendChart() {
    final p = context.palette;
    final buckets = _trendBuckets();
    final labels = buckets.labels;
    final spots = buckets.values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    // At most ~6 labels: a 60-day daily range would otherwise stack 60 dates.
    final step = (labels.length / 6).ceil().clamp(1, labels.length).toInt();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.brandPurple,
            barWidth: 3,
            // One bucket (a single week or month) has no line to draw, so show
            // the point instead of an empty chart.
            dotData: FlDotData(show: spots.length == 1),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandPurple.withValues(alpha: 0.15),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          // fl_chart shows all four sides by default, which put the same
          // numbers on the top and right edges as well as the left.
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => _moneyAxis(v),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                if (i % step != 0) return const SizedBox();
                return Text(
                  labels[i],
                  style: TextStyle(fontSize: 9, color: p.textMuted),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Candlestick view of the same buckets, styled like a trading chart: price
  /// scale on the right, a volume pane under the candles, and a dashed
  /// crosshair on touch. Revenue is not a traded price, so each candle is the
  /// bucket's total (close) with the previous bucket as its open; the wicks are
  /// a small deterministic spread that keeps the chart lively without
  /// inventing a second dataset.
  Widget _candleChart() {
    final p = context.palette;
    final buckets = _trendBuckets();
    final labels = buckets.labels;
    final values = buckets.values;
    final spots = _candles(values);
    final n = spots.length;
    final colors = [
      for (final s in spots)
        s.close >= s.open ? AppColors.green : AppColors.red,
    ];
    // The legend follows the hovered candle, falling back to the latest one.
    final active = _hoveredCandle != null &&
            _hoveredCandle! >= 0 &&
            _hoveredCandle! < n
        ? _hoveredCandle!
        : n - 1;
    final candle = spots[active];
    final candleColor = colors[active];
    final changePct =
        candle.open == 0 ? 0.0 : (candle.close - candle.open) / candle.open * 100;
    var minLow = spots.first.low;
    var maxHigh = spots.first.high;
    for (final s in spots) {
      if (s.low < minLow) minLow = s.low;
      if (s.high > maxHigh) maxHigh = s.high;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // The volume pane reclaims the same plot width as the candle chart, so
        // each bar sits under its candle the way a trading terminal does.
        const axisWidth = 52.0;
        final slot = (constraints.maxWidth - axisWidth) / n;
        final bodyWidth = (slot * 0.62).clamp(2.0, 26.0);
        final step = (n / 6).ceil().clamp(1, n).toInt();
        return Column(
          children: [
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 9.5, color: p.textMuted),
                          children: [
                            TextSpan(text: labels[active]),
                            TextSpan(text: '   O '),
                            TextSpan(
                              text: _money(candle.open),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   H '),
                            TextSpan(
                              text: _money(candle.high),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   L '),
                            TextSpan(
                              text: _money(candle.low),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   C '),
                            TextSpan(
                              text: _money(candle.close),
                              style: TextStyle(
                                color: candleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: candleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CandlestickChart(
                      CandlestickChartData(
                        // Half a slot of padding, so the first and last candles
                        // are not clipped against the edges.
                        minX: -0.5,
                        maxX: n - 0.5,
                        candlestickSpots: spots,
                        candlestickPainter: DefaultCandlestickPainter(
                          candlestickStyleProvider: (spot, index) {
                            final color = colors[index];
                            return CandlestickStyle(
                              lineColor: color,
                              lineWidth: 1,
                              bodyStrokeColor: color,
                              bodyStrokeWidth: 1,
                              bodyFillColor: color,
                              bodyWidth: bodyWidth,
                              bodyRadius: 1,
                            );
                          },
                        ),
                        touchedPointIndicator: AxisSpotIndicator(
                          painter: AxisLinesIndicatorPainter(
                            verticalLineProvider: (x) => VerticalLine(
                              x: x,
                              color: p.textMuted.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                            horizontalLineProvider: (y) => HorizontalLine(
                              y: y,
                              color: p.textMuted.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                          ),
                        ),
                        candlestickTouchData: CandlestickTouchData(
                          touchCallback: (event, response) {
                            final index = event.isInterestedForInteractions
                                ? response?.touchedSpot?.spotIndex
                                : null;
                            if (index != _hoveredCandle) {
                              setState(() => _hoveredCandle = index);
                            }
                          },
                          touchTooltipData: CandlestickTouchTooltipData(
                            getTooltipColor: (_) => p.surfaceAlt,
                            tooltipBorder: BorderSide(color: p.border),
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            getTooltipItems: (painter, spot, index) {
                              final color = painter.getMainColor(
                                spot: spot,
                                spotIndex: index,
                              );
                              final style =
                                  TextStyle(color: color, fontSize: 11);
                              final value =
                                  style.copyWith(fontWeight: FontWeight.bold);
                              return CandlestickTooltipItem(
                                labels[index],
                                textStyle: style,
                                children: [
                                  TextSpan(text: '\nO ', style: style),
                                  TextSpan(
                                      text: _money(spot.open), style: value),
                                  TextSpan(text: '  H ', style: style),
                                  TextSpan(
                                      text: _money(spot.high), style: value),
                                  TextSpan(text: '\nL ', style: style),
                                  TextSpan(
                                      text: _money(spot.low), style: value),
                                  TextSpan(text: '  C ', style: style),
                                  TextSpan(
                                      text: _money(spot.close), style: value),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Trading charts put the price scale on the right; it
                          // also leaves the left edge free for the candles.
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: axisWidth,
                              getTitlesWidget: (v, _) =>
                                  _moneyAxis(v, alignRight: true),
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Time labels live under the volume pane instead.
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: p.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  // Last close as a dashed line, with a price tag over the
                  // right scale, the way a trading chart marks the live price.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LastPricePainter(
                          price: values.last,
                          min: minLow,
                          max: maxHigh,
                          color: colors.last,
                          axisWidth: axisWidth,
                          label: _money(values.last),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VolumePainter(
                        values: values,
                        colors: colors,
                        rightPadding: axisWidth,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      'Vol',
                      style: TextStyle(fontSize: 8, color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              child: Stack(
                children: [
                  for (var i = 0; i < n; i += step)
                    Positioned(
                      left: i * slot,
                      width: slot,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: p.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// OHLC per bucket. Open is the previous bucket's close (the first candle
  /// opens slightly below its close), so candles chain like a price chart.
  List<CandlestickSpot> _candles(List<double> values) {
    const wick = [0.4, 0.7, 0.25, 0.9, 0.5, 0.35];
    return [
      for (var i = 0; i < values.length; i++)
        () {
          final close = values[i];
          final open = i == 0 ? close * 0.96 : values[i - 1];
          final spread = wick[i % wick.length];
          final top = open > close ? open : close;
          final bottom = open < close ? open : close;
          return CandlestickSpot(
            x: i.toDouble(),
            open: open,
            high: top * (1.01 + spread * 0.04),
            low: bottom * (1 - 0.01 - spread * 0.04),
            close: close,
          );
        }(),
    ];
  }

  /// Only the granularities the active range can support.
  List<String> get _granularities => _granularitiesFor(_dateRange);

  List<String> _granularitiesFor(DateTimeRange r) => [
        'Daily',
        if (_coversFullWeek(r)) 'Weekly',
        if (_coversFullMonth(r)) 'Monthly',
      ];

  void _setRange(DateTimeRange range) {
    final available = _granularitiesFor(range);
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
      return _sameRangeLastYear(_dateRange);
    }
    return _previousPeriod(_dateRange);
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

  /// True when the range contains at least one complete Monday–Sunday week.
  bool _coversFullWeek(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var monday = DateTime(
      start.year,
      start.month,
      start.day + (DateTime.monday - start.weekday) % 7,
    );
    while (!monday.isAfter(end)) {
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      if (!sunday.isAfter(end)) return true;
      monday = DateTime(monday.year, monday.month, monday.day + 7);
    }
    return false;
  }

  /// True when the range contains at least one complete calendar month.
  bool _coversFullMonth(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var month = DateTime(start.year, start.month, 1);
    while (!month.isAfter(end)) {
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      if (!month.isBefore(start) && !monthEnd.isAfter(end)) return true;
      month = DateTime(month.year, month.month + 1, 1);
    }
    return false;
  }

  /// Chart points for the active granularity. Every bucket is the sum of the
  /// same demo daily series, so a week adds up to its seven days and a month
  /// to the 15M the KPI cards quote.
  ({List<String> labels, List<double> values}) _trendBuckets() {
    final start = DateUtils.dateOnly(_dateRange.start);
    final end = DateUtils.dateOnly(_dateRange.end);
    final labels = <String>[];
    final values = <double>[];

    if (_trendGranularity == 'Weekly') {
      var monday = DateTime(
        start.year,
        start.month,
        start.day + (DateTime.monday - start.weekday) % 7,
      );
      while (true) {
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        if (sunday.isAfter(end)) break;
        var sum = 0.0;
        for (var i = 0; i < 7; i++) {
          sum +=
              _dailyValue(DateTime(monday.year, monday.month, monday.day + i));
        }
        labels.add('${monday.month}/${monday.day}');
        values.add(sum);
        monday = DateTime(monday.year, monday.month, monday.day + 7);
      }
      return (labels: labels, values: values);
    }

    if (_trendGranularity == 'Monthly') {
      var month = DateTime(start.year, start.month, 1);
      while (true) {
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        if (monthEnd.isAfter(end)) break;
        var sum = 0.0;
        for (var day = 1; day <= monthEnd.day; day++) {
          sum += _dailyValue(DateTime(month.year, month.month, day));
        }
        labels.add(_monthAbbr[month.month - 1]);
        values.add(sum);
        month = DateTime(month.year, month.month + 1, 1);
      }
      return (labels: labels, values: values);
    }

    var day = start;
    while (!day.isAfter(end)) {
      labels.add('${day.month}/${day.day}');
      values.add(_dailyValue(day));
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return (labels: labels, values: values);
  }

  /// Demo daily revenue in millions: ~0.5M a day, so thirty of them land on
  /// the 15M the KPI cards quote and each week totals 3.5M. Later years grow,
  /// so the year-on-year row is a real comparison rather than a flat copy.
  double _dailyValue(DateTime d) {
    const pattern = [0.35, 0.55, 0.45, 0.65, 0.5, 0.4, 0.6];
    final base = pattern[(d.day + d.month) % pattern.length];
    return base * (1 + 0.12 * (d.year - 2026));
  }

  /// Totals for a range, all derived from the same demo daily series.
  _Stats _statsFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    var revenue = 0.0;
    var day = start;
    while (!day.isAfter(end)) {
      revenue += _dailyValue(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
    final days = end.difference(start).inDays + 1;
    // Six vouchers a day is the demo cadence behind the overview's 180 for
    // November, so transactions and AOV move with the range too.
    final transactions = days * 6;
    return _Stats(
      revenue: revenue,
      grossProfit: revenue * 0.4,
      transactions: transactions,
      aov: revenue * 1000000 / transactions,
    );
  }

  /// The same length immediately before the range. Whole calendar months line
  /// up with whole calendar months (November is compared with October), which
  /// is what finance teams expect; anything else uses the preceding N days.
  DateTimeRange _previousPeriod(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    if (start.day == 1 && _isMonthEnd(end)) {
      final months =
          (end.year - start.year) * 12 + (end.month - start.month) + 1;
      return DateTimeRange(
        start: DateTime(start.year, start.month - months, 1),
        end: DateTime(start.year, start.month, 0),
      );
    }
    final days = end.difference(start).inDays + 1;
    return DateTimeRange(
      start: DateUtils.dateOnly(start.subtract(Duration(days: days))),
      end: DateUtils.dateOnly(start.subtract(const Duration(days: 1))),
    );
  }

  /// The same dates one year earlier, clamping 29 Feb to 28 Feb.
  DateTimeRange _sameRangeLastYear(DateTimeRange r) => DateTimeRange(
        start: _shiftYear(r.start, -1),
        end: _shiftYear(r.end, -1),
      );

  DateTime _shiftYear(DateTime d, int years) {
    final year = d.year + years;
    final lastDay = DateTime(year, d.month + 1, 0).day;
    return DateTime(year, d.month, d.day > lastDay ? lastDay : d.day);
  }

  bool _isMonthEnd(DateTime d) =>
      DateTime(d.year, d.month + 1, 0).day == d.day;

  /// Millions, with thousands for small figures: 15.0M, 83.3K.
  String _money(double millions) {
    if (millions.abs() >= 0.1) return '${millions.toStringAsFixed(1)}M';
    return '${(millions * 1000).toStringAsFixed(1)}K';
  }

  /// Percentage change with direction. A move smaller than a rounding step is
  /// shown as a dash instead of a misleading "↑ 0.0%".
  String _change(double current, double previous) {
    if (previous == 0) return '—';
    final pct = (current - previous) / previous * 100;
    if (pct.abs() < 0.05) return '—';
    return '${pct > 0 ? '↑' : '↓'} ${pct.abs().toStringAsFixed(1)}%';
  }

  String _rangeLabel() => _rangeLabelFor(_dateRange);

  /// "Nov 2026" for a whole month, otherwise the explicit date span.
  String _rangeLabelFor(DateTimeRange r) {
    final start = DateUtils.dateOnly(r.start);
    final end = DateUtils.dateOnly(r.end);
    if (start.day == 1 && _isMonthEnd(end)) {
      if (start.year == end.year && start.month == end.month) {
        return '${_monthAbbr[start.month - 1]} ${start.year}';
      }
      if (start.year == end.year) {
        return '${_monthAbbr[start.month - 1]}–'
            '${_monthAbbr[end.month - 1]} ${end.year}';
      }
      return '${_monthAbbr[start.month - 1]} ${start.year} – '
          '${_monthAbbr[end.month - 1]} ${end.year}';
    }
    final from = '${_monthAbbr[start.month - 1]} ${start.day}';
    if (start.year == end.year && start.month == end.month) {
      return '$from–${end.day}, ${end.year}';
    }
    if (start.year == end.year) {
      return '$from – ${_monthAbbr[end.month - 1]} ${end.day}, ${end.year}';
    }
    return '$from, ${start.year} – '
        '${_monthAbbr[end.month - 1]} ${end.day}, ${end.year}';
  }

  Widget _categoryBarChart(List<double> vals) {
    // Same brand accents the rest of the app uses; the last bar is "Others",
    // which earns a neutral rather than a fifth hue.
    final colors = [
      AppColors.brandPurple,
      AppColors.teal,
      AppColors.orange,
      AppColors.blue,
    ];
    final p = context.palette;
    return BarChart(
      BarChartData(
        barGroups: vals
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(toY: e.value, color: colors[e.key % colors.length]),
                  ],
                ))
            .toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => _moneyAxis(v),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const labels = ['Electronics', 'Accessories', 'Computer', 'Others'];
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(
                  labels[i],
                  style: TextStyle(fontSize: 9, color: p.textMuted),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Axis label for the money charts. The demo series are in millions, and a
  /// bare "1.5" next to a page quoting 15M gives the reader no unit at all.
  Widget _moneyAxis(double v, {bool alignRight = false}) => Text(
        v == v.roundToDouble()
            ? '${v.toInt()}M'
            : '${v.toStringAsFixed(1)}M',
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(fontSize: 9, color: context.palette.textMuted),
      );

  Widget _filterRow(String label, List<String> options, String selected,
      ValueChanged<String> onSelect) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options
                  .map((o) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text(o, style: const TextStyle(fontSize: 11)),
                          selected: selected == o,
                          onSelected: (_) => onSelect(o),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _simpleTable({
    required List<String> headers,
    required List<List<String>> rows,
    double minTableWidth = 0,
  }) {
    final p = context.palette;
    final table = Table(
      // Palette tokens, not `Colors.grey.shade*`: the old header was a fixed
      // light grey while the text came from the theme, so in dark mode white
      // sat on near-white. It was also the only table in lib/ built this way.
      border: TableBorder.all(color: p.border),
      children: [
        TableRow(
          decoration: BoxDecoration(color: p.surfaceAlt),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      h,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: p.textSecondary,
                      ),
                    ),
                  ))
              .toList(),
        ),
        ...rows.map((r) => TableRow(
              children: r
                  .map((c) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          c,
                          style: TextStyle(fontSize: 12, color: p.textPrimary),
                        ),
                      ))
                  .toList(),
            )),
      ],
    );
    if (minTableWidth <= 0) return table;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: table),
        );
      },
    );
  }

  List<(String, String)> _demoRows(String m) {
    switch (m) {
      case 'cogs':
        return const [
          ('2026-10-01', '720,000'),
          ('2026-10-02', '810,000'),
          ('2026-10-03', '660,000'),
          ('2026-10-04', '870,000'),
          ('2026-10-05', '960,000'),
        ];
      case 'grossProfit':
        return const [
          ('2026-10-01', '480,000'),
          ('2026-10-02', '540,000'),
          ('2026-10-03', '440,000'),
          ('2026-10-04', '580,000'),
          ('2026-10-05', '640,000'),
        ];
      case 'units':
        return const [
          ('Product A', '120'),
          ('Product B', '95'),
          ('Product C', '80'),
          ('Product D', '75'),
          ('Product E', '80'),
        ];
      case 'transactions':
        return const [
          ('2026-10-01', '32'),
          ('2026-10-02', '36'),
          ('2026-10-03', '30'),
          ('2026-10-04', '40'),
          ('2026-10-05', '42'),
        ];
      default:
        return const [
          ('Detail', 'Demo value'),
        ];
    }
  }
}

/// Totals for one date range. Revenue and gross profit are in millions; AOV
/// is in MMK, because order values are quoted in thousands.
class _Stats {
  const _Stats({
    required this.revenue,
    required this.grossProfit,
    required this.transactions,
    required this.aov,
  });

  final double revenue;
  final double grossProfit;
  final int transactions;
  final double aov;
}

/// Volume bars for the candlestick chart. It paints in the same width and with
/// the same right gutter as the candle chart above it, so the bars line up
/// under their candles.
class _VolumePainter extends CustomPainter {
  _VolumePainter({
    required this.values,
    required this.colors,
    required this.rightPadding,
  });

  final List<double> values;
  final List<Color> colors;
  final double rightPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    var maxValue = 0.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }
    if (maxValue <= 0) return;

    final slot = (size.width - rightPadding) / values.length;
    final barWidth = (slot * 0.62).clamp(2.0, 26.0);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final height = values[i] / maxValue * (size.height - 2);
      paint.color = colors[i].withValues(alpha: 0.55);
      canvas.drawRect(
        Rect.fromLTWH(
          i * slot + (slot - barWidth) / 2,
          size.height - height,
          barWidth,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.rightPadding != rightPadding;
}

/// Draws the latest close as a dashed line across the plot with a filled price
/// tag in the right gutter — the "last price" marker every trading chart has.
/// The line's y is mapped exactly like fl_chart maps a value, so it meets the
/// last candle's close.
class _LastPricePainter extends CustomPainter {
  _LastPricePainter({
    required this.price,
    required this.min,
    required this.max,
    required this.color,
    required this.axisWidth,
    required this.label,
  });

  final double price;
  final double min;
  final double max;
  final Color color;
  final double axisWidth;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - axisWidth;
    if (plotWidth <= 0 || max <= min) return;

    final ratio = ((max - price) / (max - min)).clamp(0.0, 1.0);
    final lineY = ratio * size.height;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < plotWidth; x += dash + gap) {
      final end = (x + dash).clamp(0.0, plotWidth);
      canvas.drawLine(Offset(x, lineY), Offset(end, lineY), linePaint);
    }

    // Keep the tag on-screen when the last candle sits on an edge.
    final tagCenter = lineY.clamp(8.0, size.height - 8.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(plotWidth, tagCenter - 8, axisWidth, 16),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: axisWidth - 4);
    textPainter.paint(
      canvas,
      Offset(
        plotWidth + (axisWidth - textPainter.width) / 2,
        tagCenter - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LastPricePainter old) =>
      old.price != price ||
      old.min != min ||
      old.max != max ||
      old.color != color ||
      old.axisWidth != axisWidth ||
      old.label != label;
}

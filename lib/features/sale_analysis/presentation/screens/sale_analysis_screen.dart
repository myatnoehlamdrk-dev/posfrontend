import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/features/sale_analysis/presentation/screens/money_flow_analysis_screen.dart';
import 'package:posfrontend/features/sale_analysis/presentation/screens/sale_analysis_detail_screen.dart';

class SaleAnalysisScreen extends StatefulWidget {
  const SaleAnalysisScreen({super.key});

  @override
  State<SaleAnalysisScreen> createState() => _SaleAnalysisScreenState();
}

class _SaleAnalysisScreenState extends State<SaleAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;
  String _forecastPeriod = 'Next 30 Days';

  // Demo data
  static const double revenue = 15000000;
  static const double cogs = 9000000;
  static const double grossProfit = revenue - cogs;
  static const double marginPct = grossProfit / revenue * 100;
  static const int unitsSold = 450;
  static const int transactionCount = 180;
  static const double aov = revenue / transactionCount;
  static const double avgUnits = unitsSold / transactionCount;
  static const double operatingExpenses = 2000000;
  static const double netProfit = grossProfit - operatingExpenses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppShell(
      active: DrawerDestination.saleAnalysis,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: 'Sale Analysis (Demo)',
              showMenuButton: !isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Money Flow'),
                Tab(text: 'Profit'),
                Tab(text: 'Forecast'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverview(p),
                  const MoneyFlowAnalysisScreen(embedded: true),
                  _buildProfit(p),
                  _buildForecast(p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(dynamic _) {
    final p = context.palette;
    final cards = <_Kpi>[
      _Kpi('Revenue', _fmt(revenue), Icons.trending_up, 'revenue'),
      _Kpi('COGS', _fmt(cogs), Icons.shopping_cart, 'cogs'),
      _Kpi(
        'Gross Profit',
        _fmt(grossProfit),
        Icons.attach_money,
        'grossProfit',
      ),
      _Kpi(
        'Margin %',
        '${marginPct.toStringAsFixed(1)}%',
        Icons.percent,
        'margin',
      ),
      _Kpi('Units Sold', '$unitsSold', Icons.inventory_2, 'units'),
      _Kpi(
        'Transactions',
        '$transactionCount',
        Icons.receipt_long,
        'transactions',
      ),
      _Kpi('AOV', _fmt(aov), Icons.payments, 'aov'),
      _Kpi(
        'Avg Units/Txn',
        avgUnits.toStringAsFixed(2),
        Icons.shopping_bag,
        'avgUnits',
      ),
      _Kpi(
        'Operating Exp.',
        _fmt(operatingExpenses),
        Icons.money_off,
        'operatingExpenses',
      ),
      _Kpi('Net Profit', _fmt(netProfit), Icons.account_balance, 'netProfit'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (c) => GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SaleAnalysisDetailScreen(metric: c.metric),
                      ),
                    ),
                    child: _kpiCard(c, p),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _fiveNumberSection(),
          const SizedBox(height: 16),
          _binningSection(),
        ],
      ),
    );
  }

  Widget _kpiCard(_Kpi k, dynamic p) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(k.icon, size: 20),
              const SizedBox(height: 8),
              Text(k.label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                k.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _profitPeriod = 'Next 30 Days';

  Widget _buildProfit(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Forecast Period:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _profitPeriod,
                items: const [
                  DropdownMenuItem(value: 'Next 7 Days', child: Text('Next 7 Days')),
                  DropdownMenuItem(value: 'Next 30 Days', child: Text('Next 30 Days')),
                  DropdownMenuItem(value: 'Next 90 Days', child: Text('Next 90 Days')),
                  DropdownMenuItem(value: 'Next 6 Months', child: Text('Next 6 Months')),
                ],
                onChanged: (v) => setState(() => _profitPeriod = v ?? _profitPeriod),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard2('Expected Revenue', '15.0M', 'MMK', Colors.blue),
              _kpiCard2('Expected COGS', '9.0M', 'MMK', Colors.red),
              _kpiCard2('Expected Gross Profit', '6.0M', 'MMK', Colors.green),
              _kpiCard2('Expected Net Profit*', '4.0M', 'MMK', Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          const Text('*Illustrative figures. Net profit assumes all relevant expenses included.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Text('Profit Projection',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(Colors.blue, 'Gross Profit'),
              const SizedBox(width: 12),
              _legendDot(Colors.green, 'Net Profit'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _profitProjectionChart()),
          const SizedBox(height: 16),
          Text('Profit Breakdown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Item', 'Amount'],
            rows: const [
              ['Revenue', '15,000,000'],
              ['Cost of Goods Sold', '-9,000,000'],
              ['Gross Profit', '6,000,000'],
              ['Operating Expenses', '-2,000,000'],
              ['Expected Net Profit*', '4,000,000'],
            ],
          ),
          const SizedBox(height: 16),
          Text('Expected Profit by Category',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: _categoryProfitChart()),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Category', 'Share'],
            rows: const [
              ['Electronics', '45%'],
              ['Accessories', '30%'],
              ['Beauty', '25%'],
            ],
          ),
          const SizedBox(height: 16),
          Text('Top Expected Profit Products',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Product', 'Forecast Profit'],
            rows: const [
              ['Product A', '1,200,000'],
              ['Product B', '850,000'],
              ['Product C', '600,000'],
            ],
          ),
          const SizedBox(height: 8),
          const Text('Sample data for UI design.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _profitProjectionChart() {
    final gross = const [0.5, 0.75, 1.0, 1.25, 1.5];
    final net = const [0.3, 0.5, 0.7, 0.9, 1.1];
    final labels = const ['W1', 'W2', 'W3', 'W4', 'W5'];
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: gross.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
          ),
          LineChartBarData(
            spots: net.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i], style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(2)}M',
                  style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryProfitChart() {
    final vals = const [45.0, 30.0, 25.0];
    final colors = [Colors.blue, Colors.green, Colors.orange];
    final labels = const ['Electronics', 'Accessories', 'Beauty'];
    return BarChart(
      BarChartData(
        barGroups: vals.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(toY: e.value, color: colors[e.key])],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i], style: const TextStyle(fontSize: 9));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForecast(dynamic p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Forecast period:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _forecastPeriod,
                items: const [
                  DropdownMenuItem(value: 'Next 7 Days', child: Text('Next 7 Days')),
                  DropdownMenuItem(value: 'Next 30 Days', child: Text('Next 30 Days')),
                  DropdownMenuItem(value: 'Next 90 Days', child: Text('Next 90 Days')),
                  DropdownMenuItem(value: 'Next 6 Months', child: Text('Next 6 Months')),
                ],
                onChanged: (v) => setState(() => _forecastPeriod = v ?? _forecastPeriod),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiCard2('Expected Inflow', '12.5M', 'MMK', Colors.green),
              _kpiCard2('Expected Outflow', '9.2M', 'MMK', Colors.red),
              _kpiCard2('Expected Net Flow', '+3.3M', 'MMK', Colors.green),
              _kpiCard2('Forecast Balance', '8.3M', 'MMK', Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Illustrative values. Historical and forecast periods visually distinguished.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Text('Cash Flow Projection',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Historical + Forecast', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(Colors.blue, 'Actual Balance'),
              const SizedBox(width: 12),
              _legendDot(Colors.orange, 'Forecast Balance'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _projectionChart()),
          const SizedBox(height: 16),
          Text('Forecast Breakdown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Source', 'Amount'],
            rows: const [
              ['Sales Collections', '+10.0M'],
              ['Customer Debt Collection', '+2.5M'],
              ['Inventory Purchases', '-5.0M'],
              ['Operating Expenses', '-2.2M'],
              ['Other Payments', '-2.0M'],
            ],
          ),
          const SizedBox(height: 16),
          Text('Financial Alerts',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Healthy cash position',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('No predicted shortage in this example.',
                  style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Sample dashboard concept, not live financial predictions.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _projectionChart() {
    final actual = const [4.0, 5.0, 6.0, 5.5, 6.5, 7.0, 7.5, 8.0];
    final forecast = const [8.0, 8.2, 8.1, 8.3, 8.4, 8.3, 8.5, 8.6];
    final labels = const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: actual.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
          ),
          LineChartBarData(
            spots: forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dashArray: [5, 5],
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i], style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text('${v.toInt()}M',
                  style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _kpiCard2(String label, String value, String sub, Color color) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpleTable({required List<String> headers, required List<List<String>> rows}) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ))
              .toList(),
        ),
        ...rows.map((r) => TableRow(
              children: r
                  .map((c) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(c, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  Widget _fiveNumberSection() {
    final data = const [0.7, 1.0, 0.9, 1.4, 1.2, 1.6, 1.3, 1.8, 1.5, 2.1];
    final sorted = [...data]..sort();
    final n = sorted.length;
    double q(double p) {
      final pos = (n - 1) * p;
      final lo = pos.floor();
      final hi = pos.ceil();
      if (lo == hi) return sorted[lo];
      return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
    }
    final min = sorted.first;
    final q1 = q(0.25);
    final med = q(0.5);
    final q3 = q(0.75);
    final max = sorted.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Five-Number Summary (Daily Revenue, M)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _fiveRow('Minimum', min),
            _fiveRow('Q1 (25th %)', q1),
            _fiveRow('Median', med),
            _fiveRow('Q3 (75th %)', q3),
            _fiveRow('Maximum', max),
          ],
        ),
      ),
    );
  }

  Widget _fiveRow(String label, double v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(v.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _binningSection() {
    final data = const [0.7, 1.0, 0.9, 1.4, 1.2, 1.6, 1.3, 1.8, 1.5, 2.1];
    final sorted = [...data]..sort();
    final k = 4; // number of equal-frequency bins
    final n = sorted.length;
    final binSize = n ~/ k;
    final bins = <_Bin>[];
    int idx = 0;
    for (int b = 0; b < k; b++) {
      final start = idx;
      final end = (b == k - 1) ? n : idx + binSize;
      final slice = sorted.sublist(start, end);
      final mean = slice.reduce((a, c) => a + c) / slice.length;
      bins.add(_Bin(
        lo: slice.first,
        hi: slice.last,
        mean: mean,
        count: slice.length,
      ));
      idx = end;
    }
    final maxCount = bins.map((b) => b.count).reduce((a, c) => a > c ? a : c);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Amount Distribution (Equal-Frequency Bins)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount + 1).toDouble(),
                  barGroups: bins.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(toY: e.value.count.toDouble(), color: Colors.blue),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= bins.length) return const SizedBox();
                          return Text('${bins[i].lo.toStringAsFixed(1)}-${bins[i].hi.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 8));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _simpleTable(
              headers: const ['Bin', 'Boundary', 'Mean', 'Count'],
              rows: bins
                  .asMap()
                  .entries
                  .map((e) => [
                        '${e.key + 1}',
                        '${e.value.lo.toStringAsFixed(2)} – ${e.value.hi.toStringAsFixed(2)}',
                        e.value.mean.toStringAsFixed(2),
                        '${e.value.count}',
                      ])
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : v.toStringAsFixed(0);
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final String metric;
  const _Kpi(this.label, this.value, this.icon, this.metric);
}

class _Bin {
  final double lo;
  final double hi;
  final double mean;
  final int count;
  const _Bin({required this.lo, required this.hi, required this.mean, required this.count});
}

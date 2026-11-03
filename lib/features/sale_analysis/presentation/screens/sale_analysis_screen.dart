import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
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

  /// Last six months, ending on the month the KPI cards quote: the series
  /// below close at 15 revenue / 9 cost, which is exactly the Revenue and
  /// COGS on this screen, and the same 15M the revenue detail page opens on.
  final List<String> _months = const [
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov',
  ];

  /// The forecast looks forward, so it gets its own labels — reusing [_months]
  /// would have drawn Dec–May on an axis that already claimed to be Jun–Nov.
  final List<String> _forecastMonths = const [
    'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
  ];
  final List<double> _revSeries = const [10, 12, 11, 14, 13, 15];
  final List<double> _costSeries = const [6, 7, 6.5, 8, 7.5, 9];
  final List<String> _products = const [
    'Product A', 'Product B', 'Product C', 'Product D', 'Product E',
  ];
  final List<double> _profitByProduct = const [2.5, 2.0, 1.5, 1.2, 0.8];
  final List<double> _forecastRev = const [15, 16, 15.5, 17, 16.5, 18];
  final List<double> _forecastLower = const [13, 14, 13.5, 15, 14.5, 16];
  final List<double> _forecastUpper = const [17, 18, 17.5, 19, 18.5, 20];

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
                  _buildMoneyFlow(p),
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
      _Kpi('Gross Profit', _fmt(grossProfit), Icons.attach_money, 'grossProfit'),
      _Kpi('Margin %', '${marginPct.toStringAsFixed(1)}%', Icons.percent, 'margin'),
      _Kpi('Units Sold', '$unitsSold', Icons.inventory_2, 'units'),
      _Kpi('Transactions', '$transactionCount', Icons.receipt_long, 'transactions'),
      _Kpi('AOV', _fmt(aov), Icons.payments, 'aov'),
      _Kpi('Avg Units/Txn', avgUnits.toStringAsFixed(2), Icons.shopping_bag, 'units'),
      _Kpi('Operating Exp.', _fmt(operatingExpenses), Icons.money_off, 'netProfit'),
      _Kpi('Net Profit', _fmt(netProfit), Icons.account_balance, 'netProfit'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((c) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SaleAnalysisDetailScreen(metric: c.metric),
                    ),
                  ),
                  child: _kpiCard(c, p),
                ))
            .toList(),
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
              Text(k.value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyFlow(dynamic p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: _revSeries
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.brandPurple,
              barWidth: 3,
            ),
            LineChartBarData(
              spots: _costSeries
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.red,
              barWidth: 3,
            ),
          ],
          titlesData: FlTitlesData(
            // fl_chart draws titles on all four sides by default, which put
            // the same numbers along the top and right edges as the left.
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _months.length) return const SizedBox();
                  return Text(
                    _months[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: context.palette.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfit(dynamic p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: _profitByProduct
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: e.value, color: AppColors.green),
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
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _products.length) return const SizedBox();
                  return Text(
                    _products[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: context.palette.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForecast(dynamic p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: _forecastRev
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.brandPurple,
              barWidth: 3,
            ),
            LineChartBarData(
              spots: _forecastLower
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.brandPurple.withValues(alpha: 0.3),
              barWidth: 1,
            ),
            LineChartBarData(
              spots: _forecastUpper
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: AppColors.brandPurple.withValues(alpha: 0.3),
              barWidth: 1,
            ),
          ],
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _forecastMonths.length) {
                    return const SizedBox();
                  }
                  return Text(
                    _forecastMonths[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: context.palette.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
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

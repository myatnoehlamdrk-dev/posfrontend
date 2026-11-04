import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';

class MoneyFlowAnalysisScreen extends StatefulWidget {
  final bool embedded;
  const MoneyFlowAnalysisScreen({super.key, this.embedded = false});

  @override
  State<MoneyFlowAnalysisScreen> createState() => _MoneyFlowAnalysisScreenState();
}

class _MoneyFlowAnalysisScreenState extends State<MoneyFlowAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tab;

  String _period = 'Weekly';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = Column(
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Payments'),
                Tab(text: 'Receivables'),
                Tab(text: 'Payables'),
                Tab(text: 'Profit vs Cash'),
              ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _overview(),
              _payments(),
              _receivables(),
              _payables(),
              _profitVsCash(),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) {
      return body;
    }
    return AppShell(
      active: DrawerDestination.saleAnalysis,
      scaffoldKey: _scaffoldKey,
      backgroundColor: p.scaffoldBg,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: 'Money Flow Analysis',
              showMenuButton: !isWide,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // ---------- Overview (Phase 1) ----------
  Widget _overview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card('Total Inflow', '8.0M', 'Money received', Colors.green),
              _card('Total Outflow', '5.5M', 'Money spent', Colors.red),
              _card('Net Cash Flow', '+2.5M', 'Inflow − Outflow', Colors.green),
              _card('Closing Balance', '7.5M', 'Opening + Net', Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Illustrative figures only. Amounts in MMK.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Text('Cash Flow Trend',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Compare money received and spent over time.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final v in ['Daily', 'Weekly', 'Monthly', 'Yearly'])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    label: Text(v, style: const TextStyle(fontSize: 11)),
                    selected: _period == v,
                    onSelected: (_) => setState(() => _period = v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _trendChart()),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _breakdown('Money Inflow', '8.0M', [
                  ('Sales payments', 0.55),
                  ('Customer debt collection', 0.25),
                  ('Other income', 0.20),
                ], Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _breakdown('Money Outflow', '5.5M', [
                  ('Inventory payments', 0.50),
                  ('Operating expenses', 0.25),
                  ('Salary payments', 0.15),
                  ('Customer refunds', 0.10),
                ], Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Recent Financial Transactions',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _txn('Customer Payment', 'Sales · Cash', '+250,000', Colors.green),
          _txn('Inventory Purchase', 'Purchase · Bank', '-500,000', Colors.red),
          _txn('Electricity Bill', 'Expense · Cash', '-80,000', Colors.red),
        ],
      ),
    );
  }

  // ---------- Payments (Phase 2) ----------
  Widget _payments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method Distribution',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _donutChart()),
          const SizedBox(height: 12),
          _simpleTable(
            headers: const ['Method', 'Amount', 'Share'],
            rows: const [
              ['Cash', '3.6M', '45%'],
              ['Bank', '2.4M', '30%'],
              ['Wallet', '2.0M', '25%'],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Receivables (Phase 2) ----------
  Widget _receivables() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card('Outstanding', '1.2M', 'Pending collection', Colors.orange),
              _card('Collected', '6.8M', 'Received', Colors.green),
              _card('Overdue', '0.3M', 'Past due', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Text('Receivable Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Customer', 'Amount', 'Due Date', 'Status'],
            rows: const [
              ['Customer A', '250,000', 'Nov 10', 'Pending'],
              ['Customer B', '180,000', 'Nov 05', 'Overdue'],
              ['Customer C', '350,000', 'Nov 15', 'Pending'],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Payables (Phase 2) ----------
  Widget _payables() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card('Outstanding', '0.9M', 'To pay', Colors.orange),
              _card('Paid', '4.6M', 'Paid', Colors.green),
              _card('Overdue', '0.1M', 'Past due', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Text('Payable Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _simpleTable(
            headers: const ['Supplier', 'Amount', 'Due Date', 'Status'],
            rows: const [
              ['Supplier A', '500,000', 'Nov 12', 'Pending'],
              ['Supplier B', '300,000', 'Nov 08', 'Overdue'],
              ['Supplier C', '100,000', 'Nov 20', 'Pending'],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Profit vs Cash (Phase 2) ----------
  Widget _profitVsCash() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profit vs Cash Flow',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Explains why accounting profit and actual cash movement differ.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _profitCashChart()),
          const SizedBox(height: 12),
          _simpleTable(
            headers: const ['Metric', 'Amount'],
            rows: const [
              ['Gross Profit', '13.2M'],
              ['Net Cash Flow', '2.5M'],
              ['Difference', '10.7M'],
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Forecast (Phase 3) ----------
  // ---------- Charts ----------
  Widget _trendChart() {
    final inflow = const [0.7, 1.0, 0.9, 1.4];
    final outflow = const [0.5, 0.6, 0.55, 0.8];
    final labels = const ['W1', 'W2', 'W3', 'W4'];
    return BarChart(
      BarChartData(
        barGroups: inflow.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(toY: e.value, color: Colors.green, width: 8),
              BarChartRodData(toY: outflow[e.key], color: Colors.red, width: 8),
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
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i], style: const TextStyle(fontSize: 9));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _donutChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 45, color: Colors.blue, title: '45%'),
          PieChartSectionData(value: 30, color: Colors.green, title: '30%'),
          PieChartSectionData(value: 25, color: Colors.orange, title: '25%'),
        ],
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _profitCashChart() {
    final profit = const [1.0, 1.2, 1.1, 1.3];
    final cash = const [0.7, 0.9, 0.8, 1.0];
    final labels = const ['W1', 'W2', 'W3', 'W4'];
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: profit.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
          ),
          LineChartBarData(
            spots: cash.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
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
        ),
      ),
    );
  }

  // ---------- Helpers ----------
  Widget _card(String label, String value, String sub, Color color) {
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

  Widget _breakdown(String title, String total, List<(String, double)> items, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(total, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(it.$1, style: const TextStyle(fontSize: 11))),
                      Text('${(it.$2 * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _txn(String title, String sub, String amount, Color color) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: Text(amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
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
}

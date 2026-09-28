import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posfrontend/features/customer/domain/entities/customer.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class TrendsTab extends StatelessWidget {
  final CustomerAnalyticsEntity analytics;

  const TrendsTab({super.key, required this.analytics});

  static const Color purple = Color(0xFF6D28D9);
  static const Color teal = Color(0xFF4FD1D9);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analytics.monthlyTrends.isNotEmpty) ...[
            Text('Sales Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary)),
            const SizedBox(height: 12),
            _spendingChart(context),
            const SizedBox(height: 24),
          ],
          if (analytics.monthlyTrends.isNotEmpty) ...[
            Text('Orders & Customers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary)),
            const SizedBox(height: 12),
            _ordersCustomersChart(context),
            const SizedBox(height: 24),
          ],
          if (analytics.salesByLocation.isNotEmpty) ...[
            Text('Sales by Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary)),
            const SizedBox(height: 12),
            _locationChart(context),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _spendingChart(BuildContext context) {
    final p = context.palette;
    final trends = analytics.monthlyTrends;
    final maxY = trends.map((t) => t.totalSpending).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxY * 1.2).toDouble(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < trends.length) {
                    return Text(trends[idx].month, style: TextStyle(fontSize: 10, color: p.textSecondary));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) return Text('${(value / 1000000).toStringAsFixed(1)}M', style: TextStyle(fontSize: 10, color: p.textSecondary));
                  if (value >= 1000) return Text('${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 10, color: p.textSecondary));
                  return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: p.textSecondary));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: p.border, strokeWidth: 1),
          ),
          barGroups: List.generate(trends.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trends[i].totalSpending.toDouble(),
                  color: purple,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _ordersCustomersChart(BuildContext context) {
    final p = context.palette;
    final trends = analytics.monthlyTrends;
    final maxOrders = trends.map((t) => t.orderCount).fold<int>(0, (a, b) => a > b ? a : b);
    final maxCustomers = trends.map((t) => t.uniqueCustomers).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxOrders > maxCustomers ? maxOrders : maxCustomers;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY * 1.3).toDouble(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < trends.length) {
                    return Text(trends[idx].month, style: TextStyle(fontSize: 10, color: p.textSecondary));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: p.textSecondary)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: p.border, strokeWidth: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(trends.length, (i) => FlSpot(i.toDouble(), trends[i].orderCount.toDouble())),
              isCurved: true,
              color: teal,
              barWidth: 2,
              dotData: FlDotData(show: true, getDotPainter: (spot, a, b, c) => FlDotCirclePainter(radius: 3, color: teal)),
            ),
            LineChartBarData(
              spots: List.generate(trends.length, (i) => FlSpot(i.toDouble(), trends[i].uniqueCustomers.toDouble())),
              isCurved: true,
              color: purple,
              barWidth: 2,
              dotData: FlDotData(show: true, getDotPainter: (spot, a, b, c) => FlDotCirclePainter(radius: 3, color: purple)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationChart(BuildContext context) {
    final p = context.palette;
    final locations = analytics.salesByLocation;
    final maxSales = locations.map((l) => l.totalSales).fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: locations.take(8).map((loc) {
          final fraction = maxSales > 0 ? loc.totalSales / maxSales : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(loc.location, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.textPrimary)),
                    ),
                    Text('MMK ${loc.totalSales}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: purple)),
                    const SizedBox(width: 8),
                    Text('${loc.percentage}%', style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: purple.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(purple),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

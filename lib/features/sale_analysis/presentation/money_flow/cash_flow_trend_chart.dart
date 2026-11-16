import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee/operation_fee_style.dart';
import 'money_flow_data.dart';

/// Grouped monthly bars: money received against money paid out.
class CashFlowTrendChart extends StatelessWidget {
  final List<MoneyFlowMonth> months;

  /// Month that matches the active calendar filter. It stays fully saturated
  /// while the rest of the year sits back, so the filter is visible in the
  /// chart as well as in the cards.
  final int highlightIndex;

  const CashFlowTrendChart({
    super.key,
    required this.months,
    required this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = months.length;
    if (n == 0) {
      return Center(
        child: Text(
          'No cash flow data for this period.',
          style: ofText(size: 12, color: p.textMuted),
        ),
      );
    }

    double alphaFor(int index) => index == highlightIndex ? 1 : 0.45;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: months[i].inflow,
                  width: 9,
                  color: AppColors.green.withValues(alpha: alphaFor(i)),
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: months[i].outflow,
                  width: 9,
                  color: AppColors.red.withValues(alpha: alphaFor(i)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: p.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
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
              interval: 2000000,
              getTitlesWidget: (v, _) => Text(
                moneyFlowAxis(v),
                style: ofText(size: 9.5, color: p.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= n) return const SizedBox();
                final active = i == highlightIndex;
                return Text(
                  moneyFlowMonthAbbr[months[i].month.month - 1],
                  style: ofText(
                    size: 9.5,
                    weight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? p.textPrimary : p.textMuted,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

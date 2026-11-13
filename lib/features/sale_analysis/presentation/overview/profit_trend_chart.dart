import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee/operation_fee_style.dart';
import 'overview_data.dart';

/// Gross vs net profit across every month that recorded sales.
///
/// Only a few evenly spaced month labels are drawn (four when the series is
/// long enough) so the axis stays readable instead of repeating every month.
class ProfitTrendChart extends StatelessWidget {
  final List<OverviewMonth> months;

  /// Month matching the active calendar filter; marked with a vertical guide so
  /// the filtered cards and the all-time trend agree on one month.
  final int? highlightIndex;

  const ProfitTrendChart({
    super.key,
    required this.months,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = months.length;
    if (n == 0) {
      return Center(
        child: Text(
          'No profit data yet.',
          style: ofText(size: 12, color: p.textMuted),
        ),
      );
    }
    final labels = _labelIndices(n);

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), months[i].grossProfit),
            ],
            isCurved: true,
            curveSmoothness: 0.22,
            color: p.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), months[i].netProfit),
            ],
            isCurved: true,
            curveSmoothness: 0.22,
            color: AppColors.green,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: p.border, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (highlightIndex != null &&
                highlightIndex! >= 0 &&
                highlightIndex! < n)
              VerticalLine(
                x: highlightIndex!.toDouble(),
                color: p.primary.withValues(alpha: 0.45),
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
          ],
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
              interval: 1000000,
              getTitlesWidget: (v, _) => Text(
                _axis(v),
                style: ofText(size: 9.5, color: p.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= n || !labels.contains(i)) {
                  return const SizedBox();
                }
                final month = months[i].month;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${month.year}/${overviewMonthAbbr[month.month - 1]}',
                    style: ofText(size: 9.5, color: p.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// At most four labels, evenly spaced across the series, always including
  /// the first and last month. Small series show every point.
  Set<int> _labelIndices(int n) {
    if (n <= 4) return {for (var i = 0; i < n; i++) i};
    final last = n - 1;
    return {
      0,
      (last / 3).round(),
      (last * 2 / 3).round(),
      last,
    };
  }

  String _axis(double value) {
    if (value == 0) return '0';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
}

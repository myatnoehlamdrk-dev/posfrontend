import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Curved line/area chart shared by the detail pages.
class AnalysisLineChart extends StatelessWidget {
  const AnalysisLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.axisLabel,
    this.maxBottomLabels = 0,
    this.showDots = true,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  /// Formats the left-axis value, e.g. `1.5M`, `34%` or `120`.
  final String Function(double value) axisLabel;

  /// When greater than zero, thins the bottom labels so at most this many are
  /// drawn. A 60-day daily range would otherwise stack 60 dates.
  final int maxBottomLabels;

  /// Whether to draw a dot on each point. Charts with many buckets usually
  /// turn this off; a single bucket needs it on or there is no chart at all.
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final step = maxBottomLabels > 0 && labels.isNotEmpty
        ? (labels.length / maxBottomLabels)
              .ceil()
              .clamp(1, labels.length)
              .toInt()
        : 1;
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(show: showDots),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
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
              getTitlesWidget: (v, _) => Text(
                axisLabel(v),
                style: TextStyle(fontSize: 9, color: p.textMuted),
              ),
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
}

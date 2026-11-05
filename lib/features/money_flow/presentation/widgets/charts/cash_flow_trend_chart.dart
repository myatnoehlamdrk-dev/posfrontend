import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Grouped bar chart comparing money received against money paid out, one
/// group per period.
///
/// Green in, red out — the same direction the summary cards use, so a bar and
/// a card never disagree about which side a figure is on.
class CashFlowTrendChart extends StatelessWidget {
  const CashFlowTrendChart({
    super.key,
    required this.labels,
    required this.inflow,
    required this.outflow,
    required this.axisLabel,
    this.maxBottomLabels = 8,
  });

  final List<String> labels;
  final List<double> inflow;
  final List<double> outflow;

  /// Formats the left-hand amount scale, e.g. `2.0M`.
  final String Function(double value) axisLabel;

  /// Bottom labels are thinned to at most this many so a 60-day daily view
  /// does not stack sixty dates on top of each other.
  final int maxBottomLabels;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = labels.length;
    if (n == 0 || inflow.length != n || outflow.length != n) {
      return Center(
        child: Text(
          'No cash flow data for this period.',
          style: TextStyle(fontSize: 12, color: p.textMuted),
        ),
      );
    }
    final step = (n / maxBottomLabels).ceil().clamp(1, n);
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
                  toY: inflow[i],
                  width: 9,
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: outflow[i],
                  width: 9,
                  color: AppColors.red,
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
        // fl_chart titles all four sides by default, which repeated the same
        // numbers along the top and right edges.
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
              reservedSize: 46,
              getTitlesWidget: (v, _) => Text(
                axisLabel(v),
                style: TextStyle(fontSize: 9, color: p.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= n) return const SizedBox();
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

/// Granularity selector, caption, legend and [CashFlowTrendChart].
class CashFlowTrendPanel extends StatelessWidget {
  const CashFlowTrendPanel({
    super.key,
    required this.granularity,
    required this.granularities,
    required this.onGranularityChanged,
    required this.labels,
    required this.inflow,
    required this.outflow,
    required this.rangeLabel,
    required this.axisLabel,
  });

  final String granularity;
  final List<String> granularities;
  final ValueChanged<String> onGranularityChanged;

  final List<String> labels;
  final List<double> inflow;
  final List<double> outflow;

  final String rangeLabel;
  final String Function(double value) axisLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final g in granularities)
              ChoiceChip(
                label: Text(g, style: const TextStyle(fontSize: 11)),
                selected: granularity == g,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onGranularityChanged(g),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$granularity inflow vs outflow · $rangeLabel',
          style: TextStyle(fontSize: 11, color: p.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(context, AppColors.green, 'Inflow'),
            const SizedBox(width: 16),
            _legendDot(context, AppColors.red, 'Outflow'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: CashFlowTrendChart(
            labels: labels,
            inflow: inflow,
            outflow: outflow,
            axisLabel: axisLabel,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: p.textSecondary)),
      ],
    );
  }
}

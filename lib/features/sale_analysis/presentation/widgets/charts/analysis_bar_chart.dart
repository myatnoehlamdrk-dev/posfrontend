import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Category bar chart used by the breakdown sections.
class AnalysisBarChart extends StatelessWidget {
  const AnalysisBarChart({
    super.key,
    required this.values,
    this.labels = defaultLabels,
  });

  static const List<String> defaultLabels = [
    'Electronics',
    'Accessories',
    'Computer',
    'Others',
  ];

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    // Same brand accents the rest of the app uses; the last bar is "Others",
    // which earns a neutral rather than a fifth hue.
    const colors = [
      AppColors.brandPurple,
      AppColors.teal,
      AppColors.orange,
      AppColors.blue,
    ];
    final p = context.palette;
    return BarChart(
      BarChartData(
        barGroups: values
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: colors[e.key % colors.length],
                  ),
                ],
              ),
            )
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
              getTitlesWidget: (v, _) => Text(
                analysisMoneyAxisLabel(v),
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

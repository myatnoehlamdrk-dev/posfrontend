import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/analysis_line_chart.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/charts/trend_candle_chart.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Shared trend controls used by the Revenue, COGS, Gross Profit and Margin
/// pages: granularity chips, a date-range picker, an optional line/candles
/// switch, and the chart itself.
///
/// The parent owns the state so it can derive other figures (KPIs, tables)
/// from the same range.
class TrendChartPanel extends StatelessWidget {
  const TrendChartPanel({
    super.key,
    required this.dateRange,
    required this.granularity,
    required this.chartType,
    required this.granularities,
    required this.buckets,
    required this.lineColor,
    required this.axisLabel,
    required this.money,
    required this.metricLabel,
    required this.rangeLabel,
    required this.onRangePicked,
    required this.onGranularityChanged,
    this.onChartTypeChanged,
    this.chartTypes = const ['Line', 'Candles'],
    this.candleAxisLabel,
    this.candleOhlc,
  });

  final DateTimeRange dateRange;
  final String granularity;
  final String chartType;
  final List<String> granularities;

  /// Chart views offered to the reader. Percentages such as margin have no
  /// meaningful candle, so those pages pass `['Line']` and the switch is
  /// hidden entirely.
  final List<String> chartTypes;

  /// Labels and values for the active granularity.
  final ({List<String> labels, List<double> values}) buckets;

  final Color lineColor;

  /// Formats the line chart's left axis.
  final String Function(double value) axisLabel;

  /// Formats the candle chart's right-hand scale. Defaults to the money label,
  /// which is right for revenue, COGS and gross profit; unit counts pass their
  /// own whole-number formatter.
  final String Function(double value)? candleAxisLabel;

  /// OHLC per bucket for the candle view. When provided, candles use real
  /// open/high/low/close instead of a synthetic spread.
  final List<({double open, double high, double low, double close})>?
  candleOhlc;

  /// Formats amounts in millions for the candle legend and price tag.
  final String Function(double millions) money;

  /// Noun used in the caption, e.g. `revenue` or `COGS`.
  final String metricLabel;

  /// Formatted active range, e.g. `Nov 2026`.
  final String rangeLabel;

  final ValueChanged<DateTimeRange> onRangePicked;
  final ValueChanged<String> onGranularityChanged;
  final ValueChanged<String>? onChartTypeChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
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
            ),
            IconButton(
              icon: const Icon(Icons.date_range, size: 20),
              tooltip: 'Pick date range',
              onPressed: () => _pickDateRange(context),
            ),
          ],
        ),
        Text(
          '$granularity $metricLabel · $rangeLabel',
          style: TextStyle(fontSize: 11, color: p.textMuted),
        ),
        const SizedBox(height: 8),
        if (chartTypes.length > 1) ...[
          Row(
            children: [
              Text(
                'Chart: ',
                style: TextStyle(fontSize: 11, color: p.textSecondary),
              ),
              for (final type in chartTypes)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 11)),
                    selected: chartType == type,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => onChartTypeChanged?.call(type),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        SizedBox(
          // Candles carry a legend, a volume pane and a time axis, so they
          // need noticeably more room than the line view.
          height: chartType == 'Candles' ? 420 : 260,
          child: chartType == 'Candles'
              ? TrendCandleChart(
                  values: buckets.values,
                  ohlc:
                      candleOhlc ??
                      [
                        for (var i = 0; i < buckets.values.length; i++)
                          (
                            open: i == 0
                                ? buckets.values[i] * 0.96
                                : buckets.values[i - 1],
                            high: buckets.values[i] * 1.04,
                            low: buckets.values[i] * 0.96,
                            close: buckets.values[i],
                          ),
                      ],
                  labels: buckets.labels,
                  money: money,
                  axisLabel: candleAxisLabel,
                )
              : AnalysisLineChart(
                  values: buckets.values,
                  labels: buckets.labels,
                  color: lineColor,
                  axisLabel: axisLabel,
                  maxBottomLabels: 6,
                  // One bucket (a single week or month) has no line to draw,
                  // so show the point instead of an empty chart.
                  showDots: buckets.values.length == 1,
                ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: dateRange,
    );
    if (picked != null) onRangePicked(picked);
  }
}

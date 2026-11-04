import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/features/sale_analysis/presentation/widgets/analysis_widgets.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Candlestick view of the trend buckets, styled like a trading chart: price
/// scale on the right, a volume pane under the candles, and a dashed crosshair
/// on touch. A metric such as revenue or COGS is not a traded price, so each
/// candle is the bucket's total (close) with the previous bucket as its open;
/// the wicks are a small deterministic spread that keeps the chart lively
/// without inventing a second dataset.
class TrendCandleChart extends StatefulWidget {
  const TrendCandleChart({
    super.key,
    required this.values,
    required this.ohlc,
    required this.labels,
    required this.money,
    this.axisLabel,
  });

  final List<double> values;
  final List<({double open, double high, double low, double close})> ohlc;
  final List<String> labels;

  /// Formats an amount in millions for the OHLC legend and price tag.
  final String Function(double millions) money;

  /// Formats the right-hand value scale. Revenue and COGS keep the default
  /// money label; count metrics such as units pass a whole-number one.
  final String Function(double value)? axisLabel;

  @override
  State<TrendCandleChart> createState() => _TrendCandleChartState();
}

class _TrendCandleChartState extends State<TrendCandleChart> {
  /// Candle under the pointer, so the OHLC legend can read like a terminal.
  int? _hoveredCandle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = widget.values;
    final labels = widget.labels;
    final spots = _candles(widget.ohlc);
    final n = spots.length;
    final colors = [
      for (final s in spots)
        s.close >= s.open ? AppColors.green : AppColors.red,
    ];
    // The legend follows the hovered candle, falling back to the latest one.
    final active =
        _hoveredCandle != null && _hoveredCandle! >= 0 && _hoveredCandle! < n
        ? _hoveredCandle!
        : n - 1;
    final candle = spots[active];
    final candleColor = colors[active];
    final changePct = candle.open == 0
        ? 0.0
        : (candle.close - candle.open) / candle.open * 100;
    var minLow = spots.first.low;
    var maxHigh = spots.first.high;
    for (final s in spots) {
      if (s.low < minLow) minLow = s.low;
      if (s.high > maxHigh) maxHigh = s.high;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // The volume pane reclaims the same plot width as the candle chart, so
        // each bar sits under its candle the way a trading terminal does.
        const axisWidth = 52.0;
        final slot = (constraints.maxWidth - axisWidth) / n;
        final bodyWidth = (slot * 0.62).clamp(2.0, 26.0);
        final step = (n / 6).ceil().clamp(1, n).toInt();
        return Column(
          children: [
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 9.5, color: p.textMuted),
                          children: [
                            TextSpan(text: labels[active]),
                            TextSpan(text: '   O '),
                            TextSpan(
                              text: widget.money(candle.open),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   H '),
                            TextSpan(
                              text: widget.money(candle.high),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   L '),
                            TextSpan(
                              text: widget.money(candle.low),
                              style: TextStyle(color: candleColor),
                            ),
                            TextSpan(text: '   C '),
                            TextSpan(
                              text: widget.money(candle.close),
                              style: TextStyle(
                                color: candleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: candleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CandlestickChart(
                      CandlestickChartData(
                        // Half a slot of padding, so the first and last candles
                        // are not clipped against the edges.
                        minX: -0.5,
                        maxX: n - 0.5,
                        candlestickSpots: spots,
                        candlestickPainter: DefaultCandlestickPainter(
                          candlestickStyleProvider: (spot, index) {
                            final color = colors[index];
                            return CandlestickStyle(
                              lineColor: color,
                              lineWidth: 1,
                              bodyStrokeColor: color,
                              bodyStrokeWidth: 1,
                              bodyFillColor: color,
                              bodyWidth: bodyWidth,
                              bodyRadius: 1,
                            );
                          },
                        ),
                        touchedPointIndicator: AxisSpotIndicator(
                          painter: AxisLinesIndicatorPainter(
                            verticalLineProvider: (x) => VerticalLine(
                              x: x,
                              color: p.textMuted.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                            horizontalLineProvider: (y) => HorizontalLine(
                              y: y,
                              color: p.textMuted.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                          ),
                        ),
                        candlestickTouchData: CandlestickTouchData(
                          touchCallback: (event, response) {
                            final index = event.isInterestedForInteractions
                                ? response?.touchedSpot?.spotIndex
                                : null;
                            if (index != _hoveredCandle) {
                              setState(() => _hoveredCandle = index);
                            }
                          },
                          touchTooltipData: CandlestickTouchTooltipData(
                            getTooltipColor: (_) => p.surfaceAlt,
                            tooltipBorder: BorderSide(color: p.border),
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            getTooltipItems: (painter, spot, index) {
                              final color = painter.getMainColor(
                                spot: spot,
                                spotIndex: index,
                              );
                              final style = TextStyle(
                                color: color,
                                fontSize: 11,
                              );
                              final value = style.copyWith(
                                fontWeight: FontWeight.bold,
                              );
                              return CandlestickTooltipItem(
                                labels[index],
                                textStyle: style,
                                children: [
                                  TextSpan(text: '\nO ', style: style),
                                  TextSpan(
                                    text: widget.money(spot.open),
                                    style: value,
                                  ),
                                  TextSpan(text: '  H ', style: style),
                                  TextSpan(
                                    text: widget.money(spot.high),
                                    style: value,
                                  ),
                                  TextSpan(text: '\nL ', style: style),
                                  TextSpan(
                                    text: widget.money(spot.low),
                                    style: value,
                                  ),
                                  TextSpan(text: '  C ', style: style),
                                  TextSpan(
                                    text: widget.money(spot.close),
                                    style: value,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Trading charts put the price scale on the right; it
                          // also leaves the left edge free for the candles.
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: axisWidth,
                              getTitlesWidget: (v, _) => Text(
                                (widget.axisLabel ?? analysisMoneyAxisLabel)(v),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Time labels live under the volume pane instead.
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: p.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  // Last close as a dashed line, with a price tag over the
                  // right scale, the way a trading chart marks the live price.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LastPricePainter(
                          price: widget.ohlc.last.close,
                          min: minLow,
                          max: maxHigh,
                          color: colors.last,
                          axisWidth: axisWidth,
                          label: widget.money(widget.ohlc.last.close),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VolumePainter(
                        values: values,
                        colors: colors,
                        rightPadding: axisWidth,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      'Vol',
                      style: TextStyle(fontSize: 8, color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              child: Stack(
                children: [
                  for (var i = 0; i < n; i += step)
                    Positioned(
                      left: i * slot,
                      width: slot,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: p.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// OHLC per bucket. Each candle opens at the previous candle's close (the
  /// first opens at its own computed open), so candles chain like a price
  /// chart. The guessed high/low only ever widen to cover the body — they are
  /// never inflated, so a high that sits under the close stays there.
  List<CandlestickSpot> _candles(
    List<({double open, double high, double low, double close})> ohlc,
  ) {
    final spots = <CandlestickSpot>[];
    for (var i = 0; i < ohlc.length; i++) {
      final open = i == 0 ? ohlc[i].open : spots[i - 1].close;
      final close = ohlc[i].close;
      final bodyTop = open > close ? open : close;
      final bodyBottom = open < close ? open : close;
      final high = ohlc[i].high > bodyTop ? ohlc[i].high : bodyTop;
      final low = ohlc[i].low < bodyBottom ? ohlc[i].low : bodyBottom;
      spots.add(
        CandlestickSpot(
          x: i.toDouble(),
          open: open,
          high: high,
          low: low,
          close: close,
        ),
      );
    }
    return spots;
  }
}

/// Volume bars for the candlestick chart. It paints in the same width and with
/// the same right gutter as the candle chart above it, so the bars line up
/// under their candles.
class _VolumePainter extends CustomPainter {
  _VolumePainter({
    required this.values,
    required this.colors,
    required this.rightPadding,
  });

  final List<double> values;
  final List<Color> colors;
  final double rightPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    var maxValue = 0.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }
    if (maxValue <= 0) return;

    final slot = (size.width - rightPadding) / values.length;
    final barWidth = (slot * 0.62).clamp(2.0, 26.0);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final height = values[i] / maxValue * (size.height - 2);
      paint.color = colors[i].withValues(alpha: 0.55);
      canvas.drawRect(
        Rect.fromLTWH(
          i * slot + (slot - barWidth) / 2,
          size.height - height,
          barWidth,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VolumePainter old) =>
      old.values != values ||
      old.colors != colors ||
      old.rightPadding != rightPadding;
}

/// Draws the latest close as a dashed line across the plot with a filled price
/// tag in the right gutter — the "last price" marker every trading chart has.
/// The line's y is mapped exactly like fl_chart maps a value, so it meets the
/// last candle's close.
class _LastPricePainter extends CustomPainter {
  _LastPricePainter({
    required this.price,
    required this.min,
    required this.max,
    required this.color,
    required this.axisWidth,
    required this.label,
  });

  final double price;
  final double min;
  final double max;
  final Color color;
  final double axisWidth;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - axisWidth;
    if (plotWidth <= 0 || max <= min) return;

    final ratio = ((max - price) / (max - min)).clamp(0.0, 1.0);
    final lineY = ratio * size.height;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    for (var x = 0.0; x < plotWidth; x += dash + gap) {
      final end = (x + dash).clamp(0.0, plotWidth);
      canvas.drawLine(Offset(x, lineY), Offset(end, lineY), linePaint);
    }

    // Keep the tag on-screen when the last candle sits on an edge.
    final tagCenter = lineY.clamp(8.0, size.height - 8.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(plotWidth, tagCenter - 8, axisWidth, 16),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: axisWidth - 4);
    textPainter.paint(
      canvas,
      Offset(
        plotWidth + (axisWidth - textPainter.width) / 2,
        tagCenter - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LastPricePainter old) =>
      old.price != price ||
      old.min != min ||
      old.max != max ||
      old.color != color ||
      old.axisWidth != axisWidth ||
      old.label != label;
}

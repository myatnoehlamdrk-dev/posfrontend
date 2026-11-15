import '../operation_fee/widgets/summary_card.dart';

/// Month-over-month movement rendered as the pill on a summary card.
typedef TrendDelta = ({String text, bool up, OfBadgeTone tone});

/// Compares [current] against [previous] as a percentage change.
///
/// [higherIsBetter] decides the pill's colour, not its arrow: a 4% rise in
/// costs is still an arrow pointing up, it just turns red. Returns a neutral
/// dash when there is no earlier month to compare against.
TrendDelta trendDelta(
  num current,
  num? previous, {
  required bool higherIsBetter,
}) {
  if (previous == null || previous == 0) {
    return (text: '—', up: true, tone: OfBadgeTone.neutral);
  }
  final pct = (current - previous) / previous * 100;
  if (pct.abs() < 0.05) {
    return (text: '0.0%', up: true, tone: OfBadgeTone.neutral);
  }
  final up = pct >= 0;
  return (
    text: '${pct.abs().toStringAsFixed(1)}%',
    up: up,
    tone: up == higherIsBetter ? OfBadgeTone.success : OfBadgeTone.danger,
  );
}

/// Month-over-month movement of a figure that is *already* a percentage —
/// a margin or a ratio — expressed in percentage points.
///
/// A margin moving from 39.8% to 37.2% is "2.6 pts", not "6.5%": the ratio of
/// two ratios reads as a change in the wrong quantity.
TrendDelta trendDeltaPoints(num current, num? previous) {
  if (previous == null || previous == 0) {
    return (text: '—', up: true, tone: OfBadgeTone.neutral);
  }
  final points = current - previous;
  if (points.abs() < 0.05) {
    return (text: '0.0 pts', up: true, tone: OfBadgeTone.neutral);
  }
  final up = points >= 0;
  return (
    text: '${points.abs().toStringAsFixed(1)} pts',
    up: up,
    tone: up ? OfBadgeTone.success : OfBadgeTone.danger,
  );
}

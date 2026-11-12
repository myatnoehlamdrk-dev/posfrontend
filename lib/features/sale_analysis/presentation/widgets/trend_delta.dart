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

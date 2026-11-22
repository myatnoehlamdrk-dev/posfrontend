import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/count_up_text.dart';
import 'package:posfrontend/shared/widgets/hover_spotlight.dart';

import '../operation_fee_style.dart';

/// Tone of the small pill next to a summary value.
enum OfBadgeTone { success, danger, neutral }

/// The KPI card used by the Operation Fee Controller and the Money Flow
/// dashboard: label, figure, trend pill, supporting line and a footer slot
/// (sparkline, progress bar or a pair of mini figures).
class OfSummaryCard extends StatelessWidget {
  final double width;
  final String label;

  /// The number behind the card. Kept numeric rather than pre-formatted so the
  /// figure can count up to it instead of appearing fully formed.
  final num value;

  /// How to print [value] while it counts, e.g. `(v) => ofMoney(v, digits: 0)`.
  /// Defaults to `ofMoney`.
  final String Function(num value)? format;

  /// Pill text. Omit to hide the pill.
  final String? badgeText;

  /// Arrow direction; ignored for [OfBadgeTone.neutral].
  final bool badgeUp;
  final OfBadgeTone badgeTone;

  final String supporting;
  final Widget footer;

  /// Dark brand card used for the headline figure.
  final bool highlight;

  /// Makes the whole card tappable, used to move the theme highlight between
  /// the cards in a finance grid.
  final VoidCallback? onTap;

  final double height;

  const OfSummaryCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    this.format,
    this.badgeText,
    this.badgeUp = true,
    this.badgeTone = OfBadgeTone.success,
    required this.supporting,
    required this.footer,
    this.highlight = false,
    this.onTap,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelColor = highlight
        ? Colors.white.withValues(alpha: 0.8)
        : p.textSecondary;
    final valueColor = highlight ? Colors.white : p.textPrimary;
    final supportingColor = highlight
        ? Colors.white.withValues(alpha: 0.7)
        : p.textMuted;

    return HoverSpotlight(
      radius: BorderRadius.circular(12),
      onTap: onTap,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? p.primary : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: highlight ? p.primary : p.border),
            boxShadow: p.cardElevation,
          ),
          child: ConstrainedBox(
            // A fixed 150dp box overflows the moment the OS text scale passes
            // ~1.4x. Keep 150 as the floor so a row of cards still lines up,
            // but let accessibility text grow the card instead of clipping it.
            constraints: BoxConstraints(minHeight: height - 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ofText(size: 12, color: labelColor)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: CountUpText(
                        value: value,
                        format: format ?? (v) => ofMoney(v),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ofText(
                          size: 24,
                          weight: FontWeight.w700,
                          color: valueColor,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        text: badgeText!,
                        up: badgeUp,
                        tone: badgeTone,
                        onHighlight: highlight,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  supporting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ofText(size: 11.5, color: supportingColor),
                ),
                const SizedBox(height: 12),
                footer,
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool up;
  final OfBadgeTone tone;
  final bool onHighlight;

  const _Badge({
    required this.text,
    required this.up,
    required this.tone,
    this.onHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Color background;
    final Color foreground;
    if (onHighlight) {
      background = Colors.white.withValues(alpha: 0.18);
      foreground = Colors.white;
    } else if (tone == OfBadgeTone.neutral) {
      background = p.chipBg;
      foreground = p.textSecondary;
    } else if (tone == OfBadgeTone.danger) {
      background = p.dangerBg;
      foreground = p.dangerFg;
    } else {
      background = p.successBg;
      foreground = p.successFg;
    }

    final showArrow = tone != OfBadgeTone.neutral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showArrow) ...[
            Icon(
              up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: foreground,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: ofText(
              size: 10.5,
              weight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative mini bar series for a card footer.
class OfSparkBars extends StatelessWidget {
  final Color color;
  final List<double> values;

  const OfSparkBars({super.key, required this.color, required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Container(
              width: 5,
              height: 4 + v * 15,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.35 + v * 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

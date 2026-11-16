import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Tone of an [AppBadge].
enum AppBadgeTone { success, info, warning, danger, neutral, brand }

/// A small pill used for status, counts and trend deltas.
///
/// Unifies the many hand-rolled `Container(padding: …, decoration: BoxDecoration(
/// color: p.successBg, borderRadius: BorderRadius.circular(20)))` blocks so
/// badges share one radius, padding and typography.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
    this.onHighlight = false,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;
  final bool onHighlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = _colors(p, tone, onHighlight);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm, color: fg),
            const SizedBox(width: AppSpacing.s4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.labelSmallSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(AppPalette p, AppBadgeTone tone, bool onHighlight) {
    if (onHighlight) {
      return (Colors.white.withValues(alpha: 0.18), Colors.white);
    }
    switch (tone) {
      case AppBadgeTone.success:
        return (p.successBg, p.successFg);
      case AppBadgeTone.info:
        return (p.infoBg, p.infoFg);
      case AppBadgeTone.warning:
        return (p.warningBg, p.warningFg);
      case AppBadgeTone.danger:
        return (p.dangerBg, p.dangerFg);
      case AppBadgeTone.brand:
        return (p.selectionTint, p.accentText);
      case AppBadgeTone.neutral:
        return (p.chipBg, p.textSecondary);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Rendered after the label. For a trailing affordance, such as a forward
  /// arrow on the primary call to action.
  final Widget? trailing;

  /// Overrides the solid brand fill with a gradient. Rare, and increasingly so:
  /// the button used to default to [AppColors.brandRamp], which swept 63° of hue
  /// from violet to sky and gave white text only 2.77:1 at the sky end. The
  /// default is now a solid fill, which is both safer and consistent with the
  /// welcome screen's `Get started` button. A call site that still passes its own
  /// pair of colours has opted out of matching the rest of the app.
  final List<Color>? gradientColors;

  /// Lifts the button off the page. Off by default, so every existing call site
  /// keeps the flat resting shadow.
  final bool floating;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.trailing,
    this.gradientColors,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // A null [onPressed] and a null [onTap] are different states and were drawn
    // identically: the button looked live, took the tap, and did nothing. The
    // app has 40-odd call sites, so "did nothing" was the common case.
    final isEnabled = onPressed != null && !loading;

    // Disabled is a fill swap, not the enabled fill at reduced opacity. Fading
    // `#7952DB` to 38% and leaving white text on it measures 2.31:1 in light —
    // the label disappears rather than receding. A neutral fill with neutral text
    // reads as unavailable at a glance *and* stays legible.
    //
    // `surfaceAlt` rather than `chipBg`: in dark, `textSecondary` on `chipBg`
    // is only 4.37:1, just under the 4.5:1 a label needs. On `surfaceAlt` it
    // clears it. (Disabled controls are exempt from WCAG, but an unreadable
    // disabled state is indistinguishable from a rendering bug.)
    final fill = isEnabled ? p.primary : p.surfaceAlt;
    final labelColor = isEnabled ? Colors.white : p.textSecondary;

    // Scale the type rather than pinning 16px, and let the button grow to fit.
    // A fixed 52px height clipped the label once the OS text size went past
    // about 1.3x, which is a common accessibility setting on the tiller's phone.
    final fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(AppTypography.bodyLargeSize);
    final minHeight = floating ? 56.0 : 52.0;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: fontSize * 0.75,
      ),
      decoration: BoxDecoration(
        color: gradientColors == null ? fill : null,
        gradient: gradientColors == null
            ? null
            : LinearGradient(
                colors: gradientColors!,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isEnabled
            ? (floating ? _floatingShadow(p) : _restingShadow(p))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: isEnabled ? onPressed : null,
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: labelColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: labelColor, size: 20),
                        const SizedBox(width: AppSpacing.s8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.s8),
                        trailing!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _restingShadow(AppPalette p) => [
    BoxShadow(
      color: p.primary.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Three shadows rather than one bigger one, because they each do a different
  /// job. The tight dark one is the contact point that anchors the button to the
  /// surface; the wide soft one is the ambient light that reads as height; the
  /// outermost haze stops the shape looking pasted onto the page. A single wide
  /// blur looks like a smudge, and two still look flat on a short window.
  List<BoxShadow> _floatingShadow(AppPalette p) => [
    BoxShadow(
      color: p.primary.withValues(alpha: 0.45),
      blurRadius: 14,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: p.primary.withValues(alpha: 0.28),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
    BoxShadow(
      color: p.primary.withValues(alpha: 0.14),
      blurRadius: 64,
      offset: const Offset(0, 30),
    ),
  ];
}

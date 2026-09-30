import 'package:flutter/material.dart';
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

  /// Overrides the default brand ramp. Rare: the ramp is already shared with
  /// the onboarding hero, so a button that passes its own colours is a button
  /// that has opted out of matching the rest of the app.
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
    return Container(
      width: double.infinity,
      height: floating ? 56 : 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? AppColors.brandRamp,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: floating ? _floatingShadow(p) : _restingShadow(p),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onPressed,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
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

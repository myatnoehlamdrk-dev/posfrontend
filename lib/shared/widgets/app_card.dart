import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The standard card surface used across the app: palette surface fill, hairline
/// border, theme-aware shadow and a consistent radius.
///
/// Replaces the many hand-rolled `Container(decoration: BoxDecoration(color:
/// p.surface, borderRadius: BorderRadius.circular(12), border: …))` blocks so
/// cards look identical in light and dark mode.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.margin,
    this.width,
    this.height,
    this.radius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.elevation = false,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool elevation;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = SizedBox(
      width: width,
      height: height,
      child: Container(
        margin: margin,
        padding: padding,
        clipBehavior: clipBehavior,
        decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: elevation ? p.cardElevation : null,
      ),
      child: child,
    ),
  );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

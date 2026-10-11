import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';

/// The chevron outline, in the brand ramp.
///
/// These six values used to be a private blue-to-violet sweep
/// (`#2879F5 #668CF2 #C35BE8` and three lighter tints) — a second gradient ramp
/// in the codebase, disjoint from `brandRamp`, on the one control that sits in
/// the top-left of essentially every screen. The hamburger and the back arrow
/// were rendering a different gradient from every button beside them.
///
/// Both lists are now steps of the single brand hue. The outline runs light to
/// dark and the fill stays two steps lighter so the chevron still reads as an
/// outline with an inner solid rather than one flat mark.
const List<Color> _kOutlineColors = [
  AppColors.violet400,
  AppColors.brandPurple,
  AppColors.brandPurpleDarker,
];

const List<Color> _kFillColors = [
  AppColors.lavender,
  AppColors.violet300,
  AppColors.violet400,
];

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double iconSize;
  final double tapSize;
  final double? strokeWidth;
  final List<Color> outlineColors;
  final List<Color> fillColors;
  final String tooltip;

  const CustomBackButton({
    super.key,
    this.onTap,
    this.iconSize = AppIconSize.xl,
    this.tapSize = AppTapTarget.comfortable,
    this.strokeWidth,
    this.outlineColors = _kOutlineColors,
    this.fillColors = _kFillColors,
    this.tooltip = 'Back',
  });

  void _handleTap(BuildContext context) {
    final handler = onTap;
    if (handler != null) {
      handler();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleTap(context),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: tapSize, minHeight: tapSize),
      tooltip: tooltip,
      icon: CustomPaint(
        size: Size.square(iconSize),
        painter: CustomBackButtonPainter(
          outlineColors: outlineColors,
          fillColors: fillColors,
          strokeWidth: strokeWidth ?? iconSize * 0.13,
        ),
      ),
    );
  }
}

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = AppIconSize.lg,
    this.colors = _kOutlineColors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect),
      child: Icon(icon, size: size),
    );
  }
}

class CustomBackButtonPainter extends CustomPainter {
  final List<Color> outlineColors;
  final List<Color> fillColors;
  final double strokeWidth;

  const CustomBackButtonPainter({
    required this.outlineColors,
    required this.fillColors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final shaderRect = Offset.zero & size;

    final outlineShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: outlineColors,
    ).createShader(shaderRect);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = outlineShader;

    final outer = Path()
      ..moveTo(s * 0.86, s * 0.22)
      ..lineTo(s * 0.18, s * 0.50)
      ..lineTo(s * 0.86, s * 0.78);
    canvas.drawPath(outer, outlinePaint);

    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: fillColors,
    ).createShader(shaderRect);

    final fillPaint = Paint()..shader = fillShader;

    final inner = Path()
      ..moveTo(s * 0.72, s * 0.35)
      ..lineTo(s * 0.38, s * 0.50)
      ..lineTo(s * 0.72, s * 0.65)
      ..close();
    canvas.drawPath(inner, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomBackButtonPainter oldDelegate) {
    return oldDelegate.outlineColors != outlineColors ||
        oldDelegate.fillColors != fillColors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

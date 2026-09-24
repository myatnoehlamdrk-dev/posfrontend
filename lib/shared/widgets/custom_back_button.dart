import 'package:flutter/material.dart';

const List<Color> _kOutlineColors = [
  Color(0xFF2879F5),
  Color(0xFF668CF2),
  Color(0xFFC35BE8),
];

const List<Color> _kFillColors = [
  Color(0xFF649EF7),
  Color(0xFF91ACF5),
  Color(0xFFD489EE),
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
    this.iconSize = 32,
    this.tapSize = 48,
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
    this.size = 24,
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
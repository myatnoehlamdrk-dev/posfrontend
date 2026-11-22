import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The app-wide page backdrop: a faint grid with three ambient colour blooms.
///
/// This is the background introduced by the Add Product screen. It lives at the
/// root of the app so every route shares one fixed canvas instead of each
/// `Scaffold` painting its own flat fill. Screens opt in by leaving their
/// `Scaffold.backgroundColor` transparent; branded pages such as onboarding
/// and sign-in keep their opaque fills and simply cover it.
class AppPageBackdrop extends StatelessWidget {
  final Widget child;

  const AppPageBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = context.isDark;

    return ColoredBox(
      color: p.scaffoldBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: p.border.withValues(alpha: isDark ? 0.30 : 0.55),
              ),
            ),
          ),
          Positioned(
            top: -180,
            left: -60,
            child: _Glow(
              size: 460,
              color: AppColors.brandPurple.withValues(
                alpha: isDark ? 0.18 : 0.09,
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: -120,
            child: _Glow(
              size: 400,
              color: AppColors.violet400.withValues(
                alpha: isDark ? 0.14 : 0.07,
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: 80,
            child: _Glow(
              size: 380,
              color: AppColors.teal.withValues(alpha: isDark ? 0.10 : 0.05),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 44.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

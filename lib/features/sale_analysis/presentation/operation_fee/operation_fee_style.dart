import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_text.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Poppins is the app-wide font; the fee screens use it too so they sit inside
/// the rest of the product rather than looking like a separate dashboard.
///
/// Delegates to [appText] so the dashboard's cards and these cards share one
/// definition of the typeface.
TextStyle ofText({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF111827),
  double? height,
  double? letterSpacing,
}) {
  return appText(
    size: size,
    weight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// `MMK 1,234.56` with grouped thousands, matching the app-wide convention
/// (`MMK 1,250,000`). Whole amounts drop the decimals; fractional amounts keep
/// two so fee maths stays exact.
String ofMoney(num value, {int? digits}) {
  final places = digits ?? (value == value.roundToDouble() ? 0 : 2);
  final fixed = value.abs().toStringAsFixed(places);
  final parts = fixed.split('.');
  final whole = parts.first;
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  final decimals = places > 0 ? '.${parts[1]}' : '';
  final sign = value < 0 ? '-' : '';
  return 'MMK $sign$grouped$decimals';
}

/// `1,264` for counts.
String ofCount(num value) {
  final whole = value.round().abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '${value < 0 ? '-' : ''}$grouped';
}

/// Trims a rate to the shortest readable form: 2800, 2.4, 0.75.
String ofRate(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

BoxDecoration ofCardDecoration(BuildContext context) {
  final p = context.palette;
  return BoxDecoration(
    color: p.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: p.border),
    boxShadow: p.cardElevation,
  );
}

/// Small icon chip used by fee rows and section headers.
class OfIconChip extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  const OfIconChip({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

/// Tiny info glyph that trails section labels.
class OfInfoDot extends StatelessWidget {
  final double size;
  const OfInfoDot({super.key, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.info_outline,
      size: size,
      color: context.palette.textMuted,
    );
  }
}

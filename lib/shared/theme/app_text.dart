import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins, named at the call site instead of inherited.
///
/// The theme already sets Poppins globally, but a [TextStyle] built for a
/// [TextPainter] or a widget rendering outside the Material text theme does
/// not inherit it — those fell back to the platform face, which is why chart
/// labels and card labels could disagree about their typeface.
///
/// Colours are always passed by the caller: a text colour depends on
/// brightness and belongs in [AppPalette].
TextStyle appText({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF111827),
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

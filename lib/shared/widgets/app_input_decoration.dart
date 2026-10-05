import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

InputDecoration appInputDecoration(
  BuildContext context, {
  required IconData icon,
  required String hint,
  String? errorText,
  Widget? suffixIcon,
}) {
  final p = context.palette;
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    hintStyle: TextStyle(
      color: p.textMuted,
      fontSize: AppTypography.bodySmallSize,
    ),
    // `accentText`, not `primary`. The prefix icon sits on `surfaceAlt`, where
    // `primary` measures 2.25:1 in dark — under the 3:1 that SC 1.4.11 requires
    // of a non-text glyph. `accentText` clears it at 4.30:1.
    prefixIcon: Icon(icon, color: p.accentText, size: AppIconSize.md),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: p.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s16,
      vertical: AppSpacing.s16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    ),
    // Also `accentText`: the focus ring is a UI component boundary (3:1), and
    // `primary` reaches only 2.25:1 on `surfaceAlt` in dark. Widening it from
    // 1 to 1.5 makes the focus state legible without leaning on colour alone.
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.accentText, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.dangerFg, width: 1.5),
    ),
  );
}

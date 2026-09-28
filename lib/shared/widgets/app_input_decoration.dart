import 'package:flutter/material.dart';
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
    hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
    prefixIcon: Icon(icon, color: p.primary, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: p.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}

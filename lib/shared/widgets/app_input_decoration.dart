import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

InputDecoration appInputDecoration({
  required IconData icon,
  required String hint,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    hintStyle: const TextStyle(color: AppColors.hintColor, fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

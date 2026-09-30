import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

class SearchInputBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchInputBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: p.textMuted, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee/operation_fee_style.dart';

/// Outlined calendar button showing the active month (`November 2026`).
class MonthFilterButton extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPressed;

  const MonthFilterButton({
    super.key,
    required this.month,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        backgroundColor: p.surface,
        side: BorderSide(color: p.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ofText(
                size: 12.5,
                weight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down,
            size: 17,
            color: p.textSecondary,
          ),
        ],
      ),
    );
  }
}

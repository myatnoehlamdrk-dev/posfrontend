import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_style.dart';

/// Wide insight strip under the dashboard.
class FinancialInsightBanner extends StatelessWidget {
  final bool compact;
  const FinancialInsightBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.successBg.withValues(alpha: 0.55), p.surfaceAlt],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.successBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.show_chart,
              size: 20,
              color: p.successFg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Small change, meaningful impact',
                  style: ofText(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reducing payment processing by 0.4% could save '
                  'approximately MMK 193 per month.',
                  style: ofText(
                    size: 11.5,
                    color: p.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: p.successFg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View insights',
                    style: ofText(
                      size: 12,
                      weight: FontWeight.w600,
                      color: p.successFg,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

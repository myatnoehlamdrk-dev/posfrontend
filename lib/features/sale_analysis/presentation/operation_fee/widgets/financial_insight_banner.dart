import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_style.dart';

/// Wide insight strip under the dashboard.
///
/// Every figure in the sentence comes from the same month the cards above it
/// describe — it used to claim a fixed "MMK 193 per month" saving that no
/// calculation in the app ever produced.
class FinancialInsightBanner extends StatelessWidget {
  final bool compact;

  /// Real month figures behind the sentence.
  final double totalCosts;
  final double revenue;
  final double costPerOrder;
  final int orders;

  const FinancialInsightBanner({
    super.key,
    this.compact = false,
    required this.totalCosts,
    required this.revenue,
    required this.costPerOrder,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final share = revenue == 0 ? 0.0 : totalCosts / revenue * 100;
    final body = revenue == 0
        ? 'No sales recorded this month, so the operation fees below are '
              'the whole cost of running the shop right now.'
        : 'Operation fees total ${ofMoney(totalCosts)} this month — '
              '${share.toStringAsFixed(1)}% of revenue, or '
              '${ofMoney(costPerOrder)} per order across '
              '${ofCount(orders)} orders.';
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
                  'What this month costs',
                  style: ofText(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: ofText(
                    size: 11.5,
                    color: p.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../operation_fee_style.dart';
import 'summary_card.dart';

/// Four-up KPI strip at the top of the Operation Fee Controller.
class SummaryCardsGrid extends StatelessWidget {
  final int columns;
  final double revenue;
  final double operatingCosts;
  final double operatingRatio;
  final double costPerOrder;
  final int totalOrders;
  final double marginBeforeFees;
  final double trueMargin;

  const SummaryCardsGrid({
    super.key,
    required this.columns,
    required this.revenue,
    required this.operatingCosts,
    required this.operatingRatio,
    required this.costPerOrder,
    required this.totalOrders,
    required this.marginBeforeFees,
    required this.trueMargin,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const gap = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cards = <Widget>[
          OfSummaryCard(
            width: width,
            label: 'Monthly revenue',
            value: revenue,
            format: (v) => ofMoney(v, digits: 0),
            badgeText: '8.2%',
            badgeUp: true,
            supporting: 'vs. ${ofMoney(44580, digits: 0)} last month',
            footer: Align(
              alignment: Alignment.centerRight,
              child: OfSparkBars(
                color: AppColors.blue,
                values: const [0.25, 0.45, 0.3, 0.6, 0.4, 0.85, 0.55],
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            label: 'Operating costs',
            value: operatingCosts,
            format: (v) => ofMoney(v),
            badgeText: '2.1%',
            badgeUp: false,
            supporting:
                '${operatingRatio.toStringAsFixed(1)}% of total revenue',
            footer: Align(
              alignment: Alignment.centerRight,
              child: OfSparkBars(
                color: p.primary,
                values: const [0.8, 0.6, 0.7, 0.45, 0.55, 0.35, 0.4],
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            label: 'Cost per order',
            value: costPerOrder,
            format: (v) => ofMoney(v),
            badgeText: '${ofCount(totalOrders)} orders',
            badgeTone: OfBadgeTone.neutral,
            supporting: 'Across all active fees',
            footer: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (operatingRatio / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: p.chipBg,
                color: p.primary,
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            highlight: true,
            label: 'True profit margin',
            value: trueMargin,
            format: (v) => '${v.toStringAsFixed(1)}%',
            badgeText: '1.4%',
            badgeUp: true,
            supporting: 'After all operation fees',
            footer: Row(
              children: [
                Text(
                  'Before fees',
                  style: ofText(
                    size: 10.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${marginBeforeFees.toStringAsFixed(1)}%',
                  style: ofText(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'After',
                  style: ofText(
                    size: 10.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${trueMargin.toStringAsFixed(1)}%',
                  style: ofText(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ];

        return Wrap(spacing: gap, runSpacing: gap, children: cards);
      },
    );
  }
}

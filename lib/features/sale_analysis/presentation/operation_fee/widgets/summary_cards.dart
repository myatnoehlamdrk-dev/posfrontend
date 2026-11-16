import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

import '../../widgets/trend_delta.dart';
import '../operation_fee_style.dart';
import 'summary_card.dart';

/// Four-up KPI strip at the top of the Operation Fee Controller.
///
/// Every figure on these cards is computed from the shop's real month data.
/// The comparison pills come from the previous month; when the account has no
/// earlier month to compare against the pill is dropped rather than filled
/// with a plausible-looking number.
class SummaryCardsGrid extends StatefulWidget {
  final int columns;
  final double revenue;
  final double operatingCosts;
  final double operatingRatio;
  final double costPerOrder;
  final int totalOrders;
  final double marginBeforeFees;
  final double trueMargin;

  /// Previous month's figures, or null when there is no earlier month.
  final double? prevRevenue;
  final double? prevOperatingCosts;
  final double? prevTrueMargin;

  /// Recent months, oldest first, already normalised to 0..1 for the
  /// sparkbars. Revenue and operating costs trend separately.
  final List<double> revenueSpark;
  final List<double> costSpark;

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
    this.prevRevenue,
    this.prevOperatingCosts,
    this.prevTrueMargin,
    this.revenueSpark = const [],
    this.costSpark = const [],
  });

  @override
  State<SummaryCardsGrid> createState() => _SummaryCardsGridState();
}

class _SummaryCardsGridState extends State<SummaryCardsGrid> {
  /// The card carrying the theme highlight. It starts on the headline card
  /// (True profit margin) and moves to whichever card the user taps, so the
  /// emphasis is chosen rather than baked into one static card.
  int _highlighted = 3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const gap = 16.0;

    // Local copies so the null checks below promote to non-null.
    final prevRevenue = widget.prevRevenue;
    final prevCosts = widget.prevOperatingCosts;
    final prevMargin = widget.prevTrueMargin;
    final revenueDelta = prevRevenue == null
        ? null
        : trendDelta(widget.revenue, prevRevenue, higherIsBetter: true);
    final costsDelta = prevCosts == null
        ? null
        : trendDelta(
            widget.operatingCosts,
            prevCosts,
            higherIsBetter: false,
          );
    final marginDelta = prevMargin == null
        ? null
        : trendDeltaPoints(widget.trueMargin, prevMargin);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - gap * (widget.columns - 1)) /
            widget.columns;
        final cards = <Widget>[
          OfSummaryCard(
            width: width,
            highlight: _highlighted == 0,
            onTap: () => setState(() => _highlighted = 0),
            label: 'Monthly revenue',
            value: widget.revenue,
            format: (v) => ofMoney(v, digits: 0),
            badgeText: revenueDelta?.text,
            badgeUp: revenueDelta?.up ?? true,
            badgeTone: revenueDelta?.tone ?? OfBadgeTone.neutral,
            supporting: prevRevenue == null
                ? 'No earlier month on record'
                : 'vs. ${ofMoney(prevRevenue, digits: 0)} last month',
            footer: Align(
              alignment: Alignment.centerRight,
              child: OfSparkBars(
                color: _highlighted == 0
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.blue,
                values: widget.revenueSpark,
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            highlight: _highlighted == 1,
            onTap: () => setState(() => _highlighted = 1),
            label: 'Operating costs',
            value: widget.operatingCosts,
            format: (v) => ofMoney(v),
            badgeText: costsDelta?.text,
            badgeUp: costsDelta?.up ?? true,
            badgeTone: costsDelta?.tone ?? OfBadgeTone.neutral,
            supporting:
                '${widget.operatingRatio.toStringAsFixed(1)}% of total revenue',
            footer: Align(
              alignment: Alignment.centerRight,
              child: OfSparkBars(
                color: _highlighted == 1
                    ? Colors.white.withValues(alpha: 0.85)
                    : p.primary,
                values: widget.costSpark,
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            highlight: _highlighted == 2,
            onTap: () => setState(() => _highlighted = 2),
            label: 'Cost per order',
            value: widget.costPerOrder,
            format: (v) => ofMoney(v),
            badgeText: '${ofCount(widget.totalOrders)} orders',
            badgeTone: OfBadgeTone.neutral,
            supporting: 'Across all active fees',
            footer: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (widget.operatingRatio / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: _highlighted == 2
                    ? Colors.white.withValues(alpha: 0.28)
                    : p.chipBg,
                color: _highlighted == 2 ? Colors.white : p.primary,
              ),
            ),
          ),
          OfSummaryCard(
            width: width,
            highlight: _highlighted == 3,
            onTap: () => setState(() => _highlighted = 3),
            label: 'True profit margin',
            value: widget.trueMargin,
            format: (v) => '${v.toStringAsFixed(1)}%',
            badgeText: marginDelta?.text,
            badgeUp: marginDelta?.up ?? true,
            badgeTone: marginDelta?.tone ?? OfBadgeTone.neutral,
            supporting: 'After all operation fees',
            footer: Row(
              children: [
                Text(
                  'Before fees',
                  style: ofText(
                    size: 10.5,
                    color: _highlighted == 3
                        ? Colors.white.withValues(alpha: 0.7)
                        : p.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.marginBeforeFees.toStringAsFixed(1)}%',
                  style: ofText(
                    size: 11,
                    weight: FontWeight.w600,
                    color: _highlighted == 3 ? Colors.white : p.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'After',
                  style: ofText(
                    size: 10.5,
                    color: _highlighted == 3
                        ? Colors.white.withValues(alpha: 0.7)
                        : p.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.trueMargin.toStringAsFixed(1)}%',
                  style: ofText(
                    size: 11,
                    weight: FontWeight.w600,
                    color: _highlighted == 3 ? Colors.white : p.textPrimary,
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

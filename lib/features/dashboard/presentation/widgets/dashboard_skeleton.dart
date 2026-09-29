import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the dashboard, shaped like the dashboard.
///
/// The point is not the shimmer. It is that the height and the column
/// breakpoints match what actually arrives, so nothing below the fold shifts
/// when the data lands. That is why this mirrors the 360/560/880 switches in
/// `DashboardScreen` rather than guessing: a placeholder that is roughly the
/// right size is worse than none at all, because it promises a layout and then
/// breaks the promise.
///
/// Only used for a first load. Pull-to-refresh keeps the real content on screen
/// and lets the refresh indicator do the talking, since blanking a populated
/// dashboard to show a placeholder is a worse answer than showing stale numbers
/// that are about to be replaced.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(height: 16, width: 90, radius: 6),
          SizedBox(height: 12),
          _SummaryGrid(),
          SizedBox(height: 24),
          _Header(width: 240),
          SizedBox(height: 12),
          _DistributionSkeleton(),
          SizedBox(height: 24),
          _Header(width: 190),
          SizedBox(height: 12),
          _CategoryChartSkeleton(),
          SizedBox(height: 24),
          _MonthlyHeader(),
          SizedBox(height: 12),
          _MonthlyChartSkeleton(),
          SizedBox(height: 24),
          _Header(width: 120),
          SizedBox(height: 12),
          _TrendSkeleton(),
        ],
      ),
    );
  }
}

/// Stands in for a section title: 16px semibold text is a 16px bar.
class _Header extends StatelessWidget {
  final double width;

  const _Header({required this.width});

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(height: 16, width: width, radius: 6);
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card = const _SummaryCardSkeleton();
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              card,
              const SizedBox(height: 12),
              card,
              const SizedBox(height: 12),
              card,
              const SizedBox(height: 12),
              card,
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: card),
                const SizedBox(width: 12),
                Expanded(child: card),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: card),
                const SizedBox(width: 12),
                Expanded(child: card),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Matches `_summaryCard`: 44px icon chip, label, a tall value, and the
/// trailing "View all" affordance.
class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 44, height: 44, radius: 12),
          SizedBox(height: 12),
          SkeletonBox(height: 14, width: 72, radius: 6),
          SizedBox(height: 6),
          SkeletonBox(height: 30, width: 120, radius: 6),
          SizedBox(height: 8),
          SkeletonBox(height: 14, width: 52, radius: 6),
        ],
      ),
    );
  }
}

/// The pie and its legend. The real section is 220x220 with up to five legend
/// entries, so the circle is the same size and the legend gets five rows.
class _DistributionSkeleton extends StatelessWidget {
  const _DistributionSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonBox(width: 220, height: 220, radius: 110),
          const SizedBox(height: 20),
          ...List.generate(
            5,
            (i) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SkeletonBox(width: 10, height: 10, radius: 3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(
                      height: 12,
                      // Varying the bar length keeps it from reading as a table.
                      width: 90.0 + (i.isEven ? 40 : 0),
                      radius: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for `_HorizontalCategoryChart`, which is five label-and-bar rows.
class _CategoryChartSkeleton extends StatelessWidget {
  const _CategoryChartSkeleton();

  static const _barWidths = [0.75, 0.52, 0.9, 0.41, 0.63];

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final w in _barWidths)
              Row(
                children: [
                  const SkeletonBox(height: 12, width: 60, radius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: w,
                      child: const SkeletonBox(height: 18, radius: 6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The monthly card has its title and year picker sharing a row, so the
/// placeholder does too.
class _MonthlyHeader extends StatelessWidget {
  const _MonthlyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: SkeletonBox(height: 16, width: 110, radius: 6)),
        SizedBox(width: 12),
        SkeletonBox(width: 84, height: 32, radius: 10),
      ],
    );
  }
}

/// Stands in for the twelve-month bar chart, so twelve bars.
class _MonthlyChartSkeleton extends StatelessWidget {
  const _MonthlyChartSkeleton();

  static const _heights = [
    0.55,
    0.72,
    0.48,
    0.86,
    0.61,
    0.94,
    0.39,
    0.68,
    0.81,
    0.57,
    0.74,
    0.9,
  ];

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 260,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in _heights)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FractionallySizedBox(
                    heightFactor: h,
                    child: const SkeletonBox(radius: 4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The three product lists, reflowing on the same 560/880 switches as
/// `_buildProductTrendSection`.
class _TrendSkeleton extends StatelessWidget {
  const _TrendSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card = const _ListCardSkeleton();
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              card,
              const SizedBox(height: 12),
              card,
              const SizedBox(height: 12),
              card,
            ],
          );
        }
        if (constraints.maxWidth < 880) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: card),
                  const SizedBox(width: 12),
                  Expanded(child: card),
                ],
              ),
              const SizedBox(height: 12),
              card,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            const SizedBox(width: 12),
            Expanded(child: card),
            const SizedBox(width: 12),
            Expanded(child: card),
          ],
        );
      },
    );
  }
}

/// Matches `_ProductListCard`: title, then three rows of a 48px thumbnail and
/// two text lines.
class _ListCardSkeleton extends StatelessWidget {
  const _ListCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 16, width: 96, radius: 6),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                const SkeletonBox(width: 48, height: 48, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        height: 14,
                        width: i.isEven ? 120 : 90,
                        radius: 6,
                      ),
                      const SizedBox(height: 4),
                      const SkeletonBox(height: 12, width: 54, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Just the chart inside the monthly card, for when the rest of the dashboard
/// has loaded but the year-to-date figures are still in flight. Exporting the
/// inner shape keeps it from drifting away from the first-load placeholder
/// above.
class MonthlySalesChartSkeleton extends StatelessWidget {
  const MonthlySalesChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSweep(child: _MonthlyChartSkeleton());
  }
}

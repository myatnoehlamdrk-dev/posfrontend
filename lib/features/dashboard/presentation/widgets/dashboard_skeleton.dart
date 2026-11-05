import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the dashboard, shaped like the dashboard.
///
/// The point is not the shimmer. It is that the height and the breakpoints
/// match what actually arrives, so nothing below the fold shifts when the
/// data lands. That is why this mirrors the 900 (pair), 760 (header) and
/// 1080/620 (KPI grid) switches in `DashboardScreen` rather than guessing: a
/// placeholder that is roughly the right size is worse than none at all,
/// because it promises a layout and then breaks the promise.
///
/// Only used for a first load. Pull-to-refresh keeps the real content on
/// screen and lets the refresh indicator do the talking, since blanking a
/// populated dashboard to show a placeholder is a worse answer than showing
/// stale numbers that are about to be replaced.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PageHeaderSkeleton(),
          SizedBox(height: 24),
          _KpiGridSkeleton(),
          SizedBox(height: 24),
          _MonthlyRowSkeleton(),
          SizedBox(height: 24),
          _ChartsRowSkeleton(),
          SizedBox(height: 24),
          _TrendRowSkeleton(),
          SizedBox(height: 24),
          _TablesRowSkeleton(),
          SizedBox(height: 24),
          _TablesRowSkeleton(),
          SizedBox(height: 24),
          _FooterSkeleton(),
        ],
      ),
    );
  }
}

/// Two cards side by side on a wide window, stacked on a narrow one — the
/// same 900px switch and the same flex ratio `DashboardScreen._pair` uses.
Widget _pair(
  Widget left,
  Widget right, {
  int leftFlex = 1,
  int rightFlex = 1,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, const SizedBox(height: 24), right],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: 24),
          Expanded(flex: rightFlex, child: right),
        ],
      );
    },
  );
}

/// Title, subtitle, tab bar and period picker.
class _PageHeaderSkeleton extends StatelessWidget {
  const _PageHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    const title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(height: 26, width: 168, radius: 6),
        SizedBox(height: 8),
        SkeletonBox(height: 13, width: 288, radius: 6),
      ],
    );
    const controls = SkeletonBox(height: 36, width: 236, radius: 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              SizedBox(width: 24),
              controls,
            ],
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [title, SizedBox(height: 16), controls],
        );
      },
    );
  }
}

/// Four KPI cards reflowing on the same 1080/620 switches as the real grid.
class _KpiGridSkeleton extends StatelessWidget {
  const _KpiGridSkeleton();

  @override
  Widget build(BuildContext context) {
    const card = _KpiCardSkeleton();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1080 ? 4 : width >= 620 ? 2 : 1;

        final rows = <Widget>[];
        for (var i = 0; i < 4; i += columns) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 16),
                  const Expanded(child: card),
                ],
              ],
            ),
          );
          if (i + columns < 4) rows.add(const SizedBox(height: 16));
        }
        return Column(children: rows);
      },
    );
  }
}

/// Matches `_KpiCard`: a 42px icon chip, a label line, a value with the mini
/// line beside it, and the trend badge's row — held as a block because every
/// tile gets an arrow there and the grid must not move when it lands.
class _KpiCardSkeleton extends StatelessWidget {
  const _KpiCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 42, height: 42, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(height: 12, width: 84, radius: 6),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(height: 22, width: 136, radius: 6),
                    SkeletonBox(width: 64, height: 26, radius: 6),
                  ],
                ),
                SizedBox(height: 6),
                SkeletonBox(height: 14, width: 62, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly chart at its 2:1 width beside the sales summary.
class _MonthlyRowSkeleton extends StatelessWidget {
  const _MonthlyRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _pair(
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(height: 16, width: 110, radius: 6),
                ),
                SizedBox(width: 12),
                SkeletonBox(width: 84, height: 32, radius: 10),
              ],
            ),
            SizedBox(height: 14),
            _MonthlyChartSkeleton(),
          ],
        ),
      ),
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, width: 118, radius: 6),
            SizedBox(height: 16),
            _SummaryRowSkeleton(),
            SizedBox(height: 14),
            _SummaryRowSkeleton(),
            SizedBox(height: 14),
            _SummaryRowSkeleton(),
            SizedBox(height: 14),
            _SummaryRowSkeleton(),
          ],
        ),
      ),
      leftFlex: 2,
      rightFlex: 1,
    );
  }
}

/// Matches `_SalesSummaryCard`: a 34px icon chip, the label, the value.
class _SummaryRowSkeleton extends StatelessWidget {
  const _SummaryRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 34, height: 34, radius: 10),
        SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SkeletonBox(height: 12, width: 96, radius: 6),
        ),
        SizedBox(width: 8),
        Flexible(
          flex: 2,
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(height: 14, width: 78, radius: 6),
          ),
        ),
      ],
    );
  }
}

/// Allocation donut and legend beside the quantity bars.
class _ChartsRowSkeleton extends StatelessWidget {
  const _ChartsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _pair(
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, width: 218, radius: 6),
            SizedBox(height: 14),
            _DonutSkeleton(),
          ],
        ),
      ),
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, width: 190, radius: 6),
            SizedBox(height: 14),
            _CategoryChartSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// The donut at its real 200x200 with the legend's rows beside it, stacking
/// on the same 560 switch the real card uses.
class _DonutSkeleton extends StatelessWidget {
  const _DonutSkeleton();

  @override
  Widget build(BuildContext context) {
    const circle = SkeletonBox(width: 200, height: 200, radius: 100);
    const divider = SkeletonBox(width: 1, height: 200, radius: 0);
    const legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendRowSkeleton(),
        SizedBox(height: 14),
        _LegendRowSkeleton(),
        SizedBox(height: 14),
        _LegendRowSkeleton(),
        SizedBox(height: 14),
        _LegendRowSkeleton(),
        SizedBox(height: 14),
        _LegendRowSkeleton(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              circle,
              SizedBox(width: 20),
              divider,
              SizedBox(width: 20),
              Expanded(child: legend),
            ],
          );
        }
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [circle, SizedBox(height: 16), legend],
        );
      },
    );
  }
}

/// Swatch, name, count, percentage — one line of the allocation legend.
class _LegendRowSkeleton extends StatelessWidget {
  const _LegendRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 10, height: 10, radius: 3),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 12, width: 96, radius: 6)),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 24, radius: 6),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 34, radius: 6),
      ],
    );
  }
}

/// Stands in for `_HorizontalCategoryChart`, which is five label-and-bar rows.
class _CategoryChartSkeleton extends StatelessWidget {
  const _CategoryChartSkeleton();

  static const _barWidths = [0.75, 0.52, 0.9, 0.41, 0.63];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

/// Three trend tiles beside the stock-status rows.
class _TrendRowSkeleton extends StatelessWidget {
  const _TrendRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _pair(
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, width: 108, radius: 6),
            SizedBox(height: 14),
            _TrendTilesSkeleton(),
          ],
        ),
      ),
      const SkeletonCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(height: 16, width: 104, radius: 6),
            SizedBox(height: 16),
            _StockRowSkeleton(),
            SizedBox(height: 16),
            _StockRowSkeleton(),
            SizedBox(height: 16),
            _StockRowSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// Three sub-cards, reflowing on the same 560/900 switches as the real row.
class _TrendTilesSkeleton extends StatelessWidget {
  const _TrendTilesSkeleton();

  @override
  Widget build(BuildContext context) {
    const tile = _TrendTileSkeleton();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              SizedBox(height: 16),
              tile,
              SizedBox(height: 16),
              tile,
            ],
          );
        }
        if (constraints.maxWidth < 900) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: tile),
                  SizedBox(width: 16),
                  Expanded(child: tile),
                ],
              ),
              SizedBox(height: 16),
              tile,
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tile),
            SizedBox(width: 16),
            Expanded(child: tile),
            SizedBox(width: 16),
            Expanded(child: tile),
          ],
        );
      },
    );
  }
}

/// Matches `_TrendTile`: a title line and two product rows of a thumbnail and
/// two text lines.
class _TrendTileSkeleton extends StatelessWidget {
  const _TrendTileSkeleton();

  @override
  Widget build(BuildContext context) {
    // No outline: the real tile is a tinted block, and a bordered placeholder
    // would be a visible jump when it is replaced.
    return SkeletonCard(
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBox(height: 13, width: 84, radius: 6),
          const SizedBox(height: 12),
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            const Row(
              children: [
                SkeletonBox(width: 30, height: 30, radius: 8),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBox(height: 12, width: 96, radius: 6),
                      SizedBox(height: 4),
                      SkeletonBox(height: 10, width: 54, radius: 5),
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

/// Matches `_StockStatusCard`: a 30px icon chip, a label, a bar, two figures.
class _StockRowSkeleton extends StatelessWidget {
  const _StockRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(width: 30, height: 30, radius: 9),
        SizedBox(width: 10),
        SkeletonBox(width: 86, height: 12, radius: 6),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 8, radius: 4)),
        SizedBox(width: 10),
        SkeletonBox(width: 30, height: 13, radius: 6),
        SizedBox(width: 8),
        SkeletonBox(width: 48, height: 12, radius: 6),
      ],
    );
  }
}

/// Two table cards side by side, on the same switch as the real row.
class _TablesRowSkeleton extends StatelessWidget {
  const _TablesRowSkeleton();

  @override
  Widget build(BuildContext context) {
    const card = SkeletonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SkeletonBox(height: 16, width: 132, radius: 6),
          ),
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _TableSkeleton(),
          ),
          SizedBox(height: 8),
        ],
      ),
    );

    return _pair(card, card);
  }
}

/// A header line plus five data rows, in the preview table's proportions.
class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  /// Flex weights, matching the widest preview's columns so the placeholder
  /// lands where the real cells do.
  static const _columnFlex = [180, 110, 64, 104];

  @override
  Widget build(BuildContext context) {
    Widget row(double height) => Row(
      children: [
        Expanded(
          flex: 30,
          child: SkeletonBox(height: height, width: 16, radius: 5),
        ),
        for (final flex in _columnFlex) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: flex,
            child: SkeletonBox(height: height, radius: 5),
          ),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(10),
        for (var i = 0; i < 5; i++) ...[
          const SizedBox(height: 16),
          row(12),
        ],
      ],
    );
  }
}

class _FooterSkeleton extends StatelessWidget {
  const _FooterSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SkeletonBox(height: 12, width: 210, radius: 6),
        SkeletonBox(height: 12, width: 158, radius: 6),
      ],
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

/// Stands in for the twelve-month column chart, so twelve columns.
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
    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in _heights)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FractionallySizedBox(
                  heightFactor: h,
                  child: const SkeletonBox(radius: 6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

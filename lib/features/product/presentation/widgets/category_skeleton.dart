import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the category showcase grid on the products page.
///
/// Mirrors `CategoryShowcaseCard`: a title bar with a trailing chevron, then a
/// two-across wrap of product tiles, each a square thumbnail over a short name
/// line. Fills come from the shared skeleton components, so the placeholder is
/// already correct in both themes and does not drift from the card it stands in
/// for.
///
/// [showBorder] is threaded through for the same reason as on the grid: the card
/// it stands in for is borderless on a phone, and a bordered placeholder under a
/// borderless card is a visible jump when the data lands.
class CategorySkeleton extends StatelessWidget {
  final bool showBorder;

  const CategorySkeleton({super.key, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          int crossAxisCount;
          if (w >= 1100) {
            crossAxisCount = 4;
          } else if (w >= 820) {
            crossAxisCount = 3;
          } else if (w >= 500) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          final spacing = showBorder ? 16.0 : 12.0;
          final cardW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              4,
              (_) => SizedBox(
                width: cardW,
                child: _SkeletonCard(showBorder: showBorder),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.showBorder});

  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      radius: 16,
      borderColor: showBorder ? null : Colors.transparent,
      padding: EdgeInsets.all(showBorder ? 16 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SkeletonBox(height: 20, width: 130)),
              const SizedBox(width: 8),
              const SkeletonBox(height: 14, width: 14, radius: 3),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonBox(height: 13, width: 180),
          const SizedBox(height: 14),
          const _SkeletonTileGrid(),
        ],
      ),
    );
  }
}

class _SkeletonTileGrid extends StatelessWidget {
  const _SkeletonTileGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final tileW = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(4, (_) {
            return SizedBox(
              width: tileW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: tileW, radius: 12),
                  const SizedBox(height: 6),
                  SkeletonBox(height: 12, width: tileW * 0.6),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
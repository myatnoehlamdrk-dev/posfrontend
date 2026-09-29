import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the category showcase grid on the products page.
///
/// Mirrors `CategoryShowcaseCard`: a title bar with a trailing arrow chip, then
/// a two-across wrap of product tiles, each a square thumbnail over a short name
/// line. Fills come from the shared skeleton components, so the placeholder is
/// already correct in both themes and does not drift from the card it stands in
/// for.
class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

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

          final spacing = 16.0;
          final cardW =
              (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              4,
              (_) => SizedBox(width: cardW, child: const _SkeletonCard()),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 18, width: 120)),
              SizedBox(width: 8),
              SkeletonBox(height: 28, width: 28, radius: 8),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonTileGrid(),
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

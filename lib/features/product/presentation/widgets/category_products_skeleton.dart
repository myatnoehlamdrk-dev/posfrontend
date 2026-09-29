import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the category product grid.
///
/// Mirrors `_ProductCard`: an image block that fills the upper part of the card,
/// then a two-line name and a price line beneath it, inside a `SkeletonCard` so
/// the border and fill match the real card.
///
/// The grid metrics are passed in rather than recomputed so the placeholder
/// occupies the same space the real grid will, and the page does not shift when
/// the products arrive.
class CategoryProductsSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const CategoryProductsSkeleton({
    super.key,
    required this.crossAxisCount,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _SkeletonProductCard(),
      ),
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      radius: 14,
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(height: double.infinity, radius: 8)),
          SizedBox(height: 10),
          SkeletonBox(height: 12, width: double.infinity),
          SizedBox(height: 6),
          SkeletonBox(height: 12, width: 80),
          SizedBox(height: 8),
          SkeletonBox(height: 15, width: 60),
        ],
      ),
    );
  }
}

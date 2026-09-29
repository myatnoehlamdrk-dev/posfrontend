import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the add-to-cart list.
///
/// Mirrors `_CardTile`: a 34px receipt chip, the item count and time, the total,
/// a delete affordance, a rule, then two dense `CartItemRow` previews and the
/// "+N more" overflow line. Two rows is the real cap, so drawing two keeps the
/// card the height it will actually be.
///
/// A plain [Column], not a [ListView]. This is only ever rendered inside
/// `RefreshableBody`, which already supplies a [SingleChildScrollView], and a
/// [ListView] under unbounded height trips a viewport assertion on screen.
class AddToCartSkeleton extends StatelessWidget {
  final int itemCount;

  const AddToCartSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              const _CardTileSkeleton(),
              if (i < itemCount - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTileSkeleton extends StatelessWidget {
  const _CardTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      radius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 34, height: 34, radius: 8),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 60, radius: 6),
                    SizedBox(height: 2),
                    SkeletonBox(height: 11, width: 84, radius: 6),
                  ],
                ),
              ),
              const SkeletonBox(height: 14, width: 58, radius: 6),
              const SizedBox(width: 10),
              const SkeletonBox(width: 18, height: 18, radius: 6),
            ],
          ),
          const SkeletonDivider(margin: EdgeInsets.symmetric(vertical: 20)),
          const _ItemRowSkeleton(),
          const SizedBox(height: 8),
          const _ItemRowSkeleton(),
          const SizedBox(height: 8),
          const SkeletonBox(height: 11, width: 54, radius: 6),
        ],
      ),
    );
  }
}

/// Matches `CartItemRow(dense: true)`: 36px thumbnail, name, optional variant
/// line, and a trailing price.
class _ItemRowSkeleton extends StatelessWidget {
  const _ItemRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox(width: 36, height: 36, radius: 8),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 13, width: 104, radius: 6),
              SizedBox(height: 2),
              SkeletonBox(height: 11, width: 62, radius: 6),
            ],
          ),
        ),
        const SkeletonBox(height: 12, width: 34, radius: 6),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the sales-items list.
///
/// Mirrors `_buildOrderCard`: a 56px thumbnail, then a voucher line carrying a
/// status pill and a delete affordance, the product name, two optional
/// secondary lines, and a footer of quantity, date and price. The optional
/// lines are always drawn, because the real card grows when they are present
/// and a placeholder that is always the same height will be wrong roughly half
/// the time.
class SaleItemsSkeleton extends StatelessWidget {
  final int itemCount;

  const SaleItemsSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const SkeletonBox(height: 13, width: 250, radius: 6),
            const SizedBox(height: 16),
            const _FilterTabsSkeleton(),
            const SizedBox(height: 16),
            for (var i = 0; i < itemCount; i++) ...[
              const _OrderCardSkeleton(),
              if (i < itemCount - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 56, height: 56, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voucher number, status pill, delete icon.
                Row(
                  children: const [
                    Expanded(child: SkeletonBox(height: 12, radius: 6)),
                    SizedBox(width: 8),
                    SkeletonBox(width: 64, height: 18, radius: 6),
                    SizedBox(width: 6),
                    SkeletonBox(width: 20, height: 20, radius: 6),
                  ],
                ),
                const SizedBox(height: 4),
                const SkeletonBox(height: 15, width: 140, radius: 6),
                const SizedBox(height: 4),
                const SkeletonBox(height: 12, width: 100, radius: 6),
                const SizedBox(height: 4),
                const SkeletonBox(height: 11, width: 78, radius: 6),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SkeletonBox(height: 12, width: 28, radius: 6),
                    const SizedBox(width: 14),
                    const SkeletonBox(width: 12, height: 12, radius: 3),
                    const SizedBox(width: 4),
                    const Expanded(child: SkeletonBox(height: 11, radius: 6)),
                    const SizedBox(width: 12),
                    const SkeletonBox(height: 14, width: 56, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three-pill tab strip. The first pill is filled, since 'All' is the tab
/// that is selected on arrival.
class _FilterTabsSkeleton extends StatelessWidget {
  const _FilterTabsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: SkeletonBox(height: 40, radius: 10)),
        SizedBox(width: 8),
        Expanded(child: SkeletonBox(height: 40, radius: 10)),
        SizedBox(width: 8),
        Expanded(child: SkeletonBox(height: 40, radius: 10)),
      ],
    );
  }
}

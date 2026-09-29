import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the purchase-items list.
///
/// Mirrors `_buildOrderCard`: a 44px thumbnail beside the order number and
/// product name with the status pill hanging on the right, then a rule, then
/// the author, supplier and quantity-and-price line, then the date and the
/// "Mark Completed" action. The action is drawn on every card because the real
/// one only appears on pending orders, and a placeholder that is always the
/// same height lands wrong on whichever tab is currently selected.
class PurchaseItemsSkeleton extends StatelessWidget {
  final int itemCount;

  const PurchaseItemsSkeleton({super.key, this.itemCount = 4});

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
            const SkeletonBox(height: 13, width: 230, radius: 6),
            const SizedBox(height: 16),
            const _FilterTabsSkeleton(),
            const SizedBox(height: 16),
            for (var i = 0; i < itemCount; i++) ...[
              const _OrderCardSkeleton(),
              if (i < itemCount - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 80),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 12, width: 80, radius: 6),
                    SizedBox(height: 2),
                    SkeletonBox(height: 15, width: 130, radius: 6),
                  ],
                ),
              ),
              const SkeletonBox(width: 66, height: 18, radius: 6),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonDivider(),
          const SizedBox(height: 10),
          const SkeletonBox(height: 11, width: 92, radius: 6),
          const SizedBox(height: 6),
          Row(
            children: const [
              SkeletonBox(width: 14, height: 14, radius: 4),
              SizedBox(width: 4),
              SkeletonBox(height: 12, width: 100, radius: 6),
              Spacer(),
              SkeletonBox(height: 12, width: 26, radius: 6),
              SizedBox(width: 4),
              SkeletonBox(height: 12, width: 48, radius: 6),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              SkeletonBox(width: 12, height: 12, radius: 3),
              SizedBox(width: 4),
              SkeletonBox(height: 11, width: 78, radius: 6),
              Spacer(),
              SkeletonBox(width: 104, height: 24, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

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

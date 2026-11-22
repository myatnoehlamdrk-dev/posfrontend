import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the purchase-items list.
///
/// Mirrors `_OrderCard`: a 48px icon, then the order-number pill, product
/// name, supplier/author line, and a footer of quantity, unit price and date.
/// On a wide card the status pill, "Mark as Shop" action and chevron sit in a
/// right-hand column above the amount; on a narrow card they drop into a
/// divided footer row beside it. The optional lines are always drawn, because
/// the real card grows when they are present and a placeholder that is always
/// the same height will be wrong roughly half the time.
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
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Same 480 breakpoint the real card switches its column on.
          final wide = constraints.maxWidth >= 480;

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(height: 12, width: 110, radius: 6),
              SizedBox(height: 6),
              SkeletonBox(height: 15, width: 140, radius: 6),
              SizedBox(height: 4),
              SkeletonBox(height: 12, width: 100, radius: 6),
              SizedBox(height: 8),
              Row(
                children: [
                  SkeletonBox(height: 12, width: 28, radius: 6),
                  SizedBox(width: 8),
                  SkeletonBox(height: 12, width: 14, radius: 6),
                  SizedBox(width: 4),
                  SkeletonBox(height: 12, width: 48, radius: 6),
                  SizedBox(width: 10),
                  SkeletonBox(width: 12, height: 12, radius: 3),
                  SizedBox(width: 4),
                  Expanded(child: SkeletonBox(height: 11, radius: 6)),
                ],
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 48, height: 48, radius: 12),
                const SizedBox(width: 14),
                Expanded(child: details),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkeletonBox(width: 84, height: 24, radius: 8),
                        SizedBox(width: 6),
                        SkeletonBox(width: 110, height: 34, radius: 10),
                        SizedBox(width: 6),
                        SkeletonBox(width: 34, height: 34, radius: 10),
                      ],
                    ),
                    SizedBox(height: 10),
                    SkeletonBox(height: 18, width: 96, radius: 6),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 48, height: 48, radius: 12),
                  const SizedBox(width: 14),
                  Expanded(child: details),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    SkeletonBox(height: 16, width: 96, radius: 6),
                    SizedBox(width: 6),
                    SkeletonBox(width: 84, height: 24, radius: 8),
                    SkeletonBox(width: 110, height: 34, radius: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

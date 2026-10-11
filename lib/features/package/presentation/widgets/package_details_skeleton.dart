import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/skeleton.dart';

/// Loading placeholder for the package details screen.
///
/// Mirrors `PackageDetailsScreen` block for block: the breadcrumb strip, the
/// summary card with its thumbnail and info tiles, the stock card with its
/// progress bar, the products header with its search field, and then the
/// product rows. Built from the shared skeleton pieces so the fill is already
/// correct in dark mode and the placeholder cannot drift from the layout it
/// stands in for.
class PackageDetailsSkeleton extends StatelessWidget {
  final int rowCount;

  const PackageDetailsSkeleton({super.key, this.rowCount = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonSweep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breadcrumb(),
          const SizedBox(height: 24),
          _summaryCard(),
          const SizedBox(height: 16),
          _stockCard(),
          const SizedBox(height: 24),
          _productsHeader(),
          const SizedBox(height: 12),
          for (var i = 0; i < rowCount; i++) ...[
            _productRow(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// Five short blocks for the Dashboard / Inventory / category / package /
  /// Package Detail trail.
  Widget _breadcrumb() {
    return const Row(
      children: [
        SkeletonBox(height: 12, width: 64),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 56),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 72),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 64),
        SizedBox(width: 8),
        SkeletonBox(height: 12, width: 88),
      ],
    );
  }

  Widget _summaryCard() {
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 120, height: 120, radius: 14),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        SkeletonBox(height: 24, width: 76, radius: 20),
                        SizedBox(width: 8),
                        SkeletonBox(height: 24, width: 56, radius: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SkeletonBox(height: 28, width: double.infinity),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 14, width: 180),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // The real info row stacks below 520 and goes three-across above
              // it, so the placeholder has to do the same or the page jumps.
              if (constraints.maxWidth < 520) {
                return const Column(
                  children: [
                    SkeletonBox(height: 64, radius: 12),
                    SizedBox(height: 8),
                    SkeletonBox(height: 64, radius: 12),
                    SizedBox(height: 8),
                    SkeletonBox(height: 64, radius: 12),
                  ],
                );
              }
              return const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 64, radius: 12)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 64, radius: 12)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 64, radius: 12)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stockCard() {
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(height: 16, width: 132),
              Spacer(),
              SkeletonBox(height: 24, width: 64, radius: 20),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonBox(height: 8, width: double.infinity, radius: 4),
        ],
      ),
    );
  }

  Widget _productsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 32)),
            SizedBox(width: 8),
            SkeletonBox(height: 44, width: 44, radius: 10),
            SizedBox(width: 8),
            SkeletonBox(height: 44, width: 44, radius: 10),
          ],
        ),
        const SizedBox(height: 12),
        SkeletonBox(height: 48, width: double.infinity, radius: 12),
      ],
    );
  }

  Widget _productRow() {
    return SkeletonCard(
      child: Row(
        children: [
          const SkeletonBox(width: 80, height: 80, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 180),
                const SizedBox(height: 6),
                SkeletonBox(height: 12, width: 120),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(height: 24, width: 52, radius: 20),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
        final cardW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(4, (_) => SizedBox(
            width: cardW,
            child: _skeletonCard(),
          )),
        );
      },
    );
  }

  Widget _skeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 18, width: 120)),
              const SizedBox(width: 8),
              _shimmerBox(height: 28, width: 28, radius: 8),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
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
                        _shimmerBox(height: tileW, radius: 12),
                        const SizedBox(height: 6),
                        _shimmerBox(height: 12, width: tileW * 0.6),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_tile.dart';

class CategoryShowcaseCard extends StatelessWidget {
  final CategoryShowcaseData category;
  final ValueChanged<CatalogProductView>? onProductTap;
  final ValueChanged<CatalogProductView>? onProductLongPress;
  final VoidCallback? onSeeAll;

  const CategoryShowcaseCard({
    super.key,
    required this.category,
    this.onProductTap,
    this.onProductLongPress,
    this.onSeeAll,
  });

  static const Color _titleColor = Color(0xFF111827);
  static const Color _gray = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSeeAll,
          hoverColor: const Color(0xFFF9FAFB),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                _productGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _gray,
          ),
        ),
      ],
    );
  }

  Widget _productGrid() {
    final products = category.products;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No products',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final tileW = (constraints.maxWidth - spacing) / 2;
        final tileH = tileW + 28;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products.map((p) {
            return SizedBox(
              width: tileW,
              height: tileH,
              child: CategoryTile(
                product: p,
                onTap: onProductTap != null ? () => onProductTap!(p) : null,
                onLongPress: onProductLongPress != null
                    ? () => onProductLongPress!(p)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

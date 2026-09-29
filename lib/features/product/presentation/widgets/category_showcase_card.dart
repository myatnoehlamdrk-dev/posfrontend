import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_tile.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow,
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
          hoverColor: p.surfaceAlt,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(p),
                const SizedBox(height: 16),
                _productGrid(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppPalette p) {
    return Row(
      children: [
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: p.chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: p.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _productGrid(AppPalette p) {
    final products = category.products;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No products',
            style: TextStyle(fontSize: 13, color: p.textMuted),
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

import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_tile.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';

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
                _header(context, p),
                const SizedBox(height: 16),
                _productGrid(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppPalette p) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
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
              // The product total, kept deliberately quiet: a count beside the
              // name is context, not a second headline, so it is set small and
              // low-contrast and aligned to the name's baseline rather than
              // given a chip of its own. Two keys so a single-product category
              // does not read "1 products".
              if (category.displayCount > 0) ...[
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    context.l10n
                        .t(
                          category.displayCount == 1
                              ? '{v1} product'
                              : '{v1} products',
                        )
                        .replaceAll('{v1}', category.displayCount.toString()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ],
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
            AppStrings.current.t('No products'),
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

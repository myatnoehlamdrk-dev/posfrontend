import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_card.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';

class CategoryShowcaseGrid extends StatelessWidget {
  final List<CategoryShowcaseData> categories;
  final ValueChanged<CatalogProductView>? onProductTap;
  final ValueChanged<CatalogProductView>? onProductLongPress;
  final ValueChanged<CategoryShowcaseData>? onCategoryTap;

  const CategoryShowcaseGrid({
    super.key,
    required this.categories,
    this.onProductTap,
    this.onProductLongPress,
    this.onCategoryTap,
  });

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
          children: categories.map((cat) {
            return SizedBox(
              width: cardW,
              child: CategoryShowcaseCard(
                category: cat,
                onProductTap: onProductTap,
                onProductLongPress: onProductLongPress,
                onSeeAll: onCategoryTap != null ? () => onCategoryTap!(cat) : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

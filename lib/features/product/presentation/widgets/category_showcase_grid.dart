import 'package:flutter/material.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_card.dart';
import 'package:posfrontend/features/product/presentation/widgets/category_showcase_data.dart';

class CategoryShowcaseGrid extends StatelessWidget {
  final List<CategoryShowcaseData> categories;

  /// Draw the hairline outline on each card. Passed in rather than derived from
  /// this widget's own width, because "is the window wide" is the screen's
  /// question to answer — it already has to make it to decide between a side
  /// drawer and a bottom nav, and the width *inside* the drawer is not the same
  /// number.
  final bool showCardBorder;

  final ValueChanged<CatalogProductView>? onProductTap;
  final ValueChanged<CatalogProductView>? onProductLongPress;
  final ValueChanged<CategoryShowcaseData>? onCategoryTap;

  const CategoryShowcaseGrid({
    super.key,
    required this.categories,
    this.showCardBorder = true,
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

        // Wider gutters when the cards are bordered, to account for the outline
        // on both sides of a run. Borderless cards at one column already read as
        // separate, and extra gutter there would just make the page loose.
        final spacing = showCardBorder ? 16.0 : 12.0;
        final cardW = (w - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: categories.map((cat) {
            return SizedBox(
              width: cardW,
              child: CategoryShowcaseCard(
                category: cat,
                showBorder: showCardBorder,
                onProductTap: onProductTap,
                onProductLongPress: onProductLongPress,
                onSeeAll: onCategoryTap != null
                    ? () => onCategoryTap!(cat)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
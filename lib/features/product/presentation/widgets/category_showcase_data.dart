import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class CategoryShowcaseData {
  final String id;
  final String name;

  /// The category's own description, as sent by
  /// `/categories/with-products`. Free text and frequently blank — older
  /// categories predate the field — so every consumer has to cope with an empty
  /// string rather than assume there is something to show.
  final String description;

  final List<CatalogProductView> products;

/// How many products the category holds in total.
  ///
  /// Not the same as [products]: the endpoint is asked for a preview
  /// (`productLimit=4`), so that list is a slice of the real thing. Whatever
  /// the server reports lands here, and [displayCount] decides what to show.
  final int productCount;

  const CategoryShowcaseData({
    required this.id,
    required this.name,
    this.description = '',
    required this.products,
    int? productCount,
  }) : productCount = productCount ?? 0;

  /// The number to print beside the category name.
  ///
  /// Never lower than [products.length]. The header sits directly above the
  /// product tiles, so a count below the visible row — "Accessories 3" above
  /// four tiles — reads as broken even when the server's figure is the
  /// technically correct one. Taking the larger of the two can only ever
  /// over-report, which is the safer way to be wrong here.
  int get displayCount =>
      productCount > products.length ? productCount : products.length;

  /// Whether [displayCount] is the real total rather than the preview size.
  bool get hasExactCount => productCount > products.length;

  /// Whether there is a description worth putting on screen.
  ///
  /// Checked here rather than at each call site so "blank" means the same thing
  /// everywhere: a description that is only whitespace collapses its line.
  bool get hasDescription => description.trim().isNotEmpty;

  /// The category as the domain entity the package screens take.
  ///
  /// The catalog holds [CategoryShowcaseData] rather than a `Category`, so
  /// opening a package detail needs a real one. The icon and colour are derived
  /// from the name using the same hash the product tiles use, which keeps a
  /// package's category badge the same colour as its category's product tiles.
  Category toCategory() => Category(
    id: id,
    name: name,
    description: description,
    icon: CatalogProductView.iconFor(name),
    iconColor: CatalogProductView.colorFor(name),
  );
}
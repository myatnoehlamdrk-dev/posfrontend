import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class CategoryShowcaseData {
  final String id;
  final String name;
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
}
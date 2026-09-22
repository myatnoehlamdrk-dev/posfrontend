import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';

class CategoryShowcaseData {
  final String id;
  final String name;
  final List<CatalogProductView> products;

  const CategoryShowcaseData({
    required this.id,
    required this.name,
    required this.products,
  });
}

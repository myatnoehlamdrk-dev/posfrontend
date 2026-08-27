import 'package:posfrontend/modules/package/model/package_models.dart';
import 'package:posfrontend/modules/package/model/product_models.dart';
import 'package:posfrontend/modules/package/repository/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  List<Product> getProducts(Package package) {
    if (package.name.toLowerCase().contains('bose')) {
      return const [
        Product(
          name: 'Bose QuietComfort Headphones',
          description:
              'Premium noise-canceling headphones with deep bass and clear audio.',
          quantity: 5,
        ),
        Product(
          name: 'Bose Audio Cable',
          description: '3.5mm to 3.5mm audio cable for wired connection.',
          quantity: 4,
        ),
        Product(
          name: 'Bose Headphone Case',
          description: 'Protective hard case for safe storage and travel.',
          quantity: 3,
        ),
        Product(
          name: 'Bose Airplane Adapter',
          description: 'Dual-prong airplane adapter for in-flight use.',
          quantity: 3,
        ),
      ];
    }

    return List.generate(3, (i) {
      final n = i + 1;
      return Product(
        name: '${package.name} Component $n',
        description: 'Product component $n included in this package.',
        quantity: n * 2,
      );
    });
  }
}

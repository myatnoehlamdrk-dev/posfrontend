import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository.dart';

class SaleProductRepositoryImpl implements SaleProductRepository {
  @override
  Future<List<CatalogProduct>> getProducts() async {
    final dio = ApiClient.create();
    final response = await dio.get('/api/products');
    final items = _asList(response.data);
    return items.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  CatalogProduct _map(Map<String, dynamic> item) {
    final variants = item['variants'];
    final variantList = variants is List ? variants : const [];
    final parsedVariants = variantList
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();
    final price = parsedVariants.isNotEmpty ? parsedVariants.first.price : 0.0;

    final image = (item['image'] as String?)?.trim();
    final category = (item['category'] as String?)?.trim() ?? '';

    return CatalogProduct(
      id: item['id']?.toString() ?? '',
      name: (item['name'] as String?)?.trim() ?? 'Unnamed',
      brand: (item['brand'] as String?)?.trim() ?? '',
      sku: (item['sku'] as String?)?.trim() ?? '',
      price: price,
      stock: (item['stock'] as num?)?.toInt() ?? 0,
      isSet: item['isSet'] as bool? ?? false,
      category: category,
      packageId: (item['packageId'] as String?)?.trim() ?? '',
      icon: CatalogProduct.iconFor(category),
      color: CatalogProduct.colorFor(category),
      imageUrl: image != null && image.isNotEmpty ? image : null,
      variants: parsedVariants,
    );
  }
}

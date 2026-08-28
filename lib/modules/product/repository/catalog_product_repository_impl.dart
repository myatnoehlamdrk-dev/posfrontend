import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';

class CatalogProductRepositoryImpl implements CatalogProductRepository {
  @override
  Future<List<CatalogProduct>> getProducts({String? packageId}) async {
    try {
      final dio = ApiClient.create();
      final query = <String, dynamic>{};
      if (packageId != null && packageId.isNotEmpty) {
        query['packageId'] = packageId;
      }
      final resp = await dio.get('/api/products', queryParameters: query);
      final list = _asList(resp.data);
      return [for (final item in list) _map(item)];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  CatalogProduct _map(Map<String, dynamic> item) {
    final variants = item['variants'];
    final variantList = variants is List ? variants : const [];
    final price = variantList.isNotEmpty
        ? (variantList.first['price'] ?? 0).toDouble()
        : 0.0;
    final category = (item['category'] as String?)?.trim() ?? '';
    final image = (item['image'] as String?)?.trim();
    return CatalogProduct(
      id: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? 'Unnamed',
      brand: item['brand']?.toString() ?? '',
      sku: item['sku']?.toString() ?? '',
      price: price,
      stock: (item['stock'] as num?)?.toInt() ?? 0,
      isSet: item['isSet'] as bool? ?? false,
      category: category,
      packageId: (item['packageId'] as String?) ?? '',
      icon: CatalogProduct.iconFor(category),
      color: CatalogProduct.colorFor(category),
      imageUrl: image != null && image.isNotEmpty ? image : null,
    );
  }
}

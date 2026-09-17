import 'package:dio/dio.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/presentation/entities/catalog_product_view.dart';
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart';

class SaleProductRepositoryImpl implements SaleProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  SaleProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  @override
  Future<List<CatalogProductView>> getProducts({CancelToken? cancelToken}) async {
    final models = await _remoteDataSource.getProducts(cancelToken: cancelToken);
    return models.map((m) {
      final entity = m.toEntity();
      return CatalogProductView(
        id: entity.id,
        name: entity.name,
        brand: entity.brand,
        sku: entity.sku,
        price: entity.price,
        stock: entity.stock,
        isSet: entity.isSet,
        category: entity.category,
        packageId: entity.packageId,
        icon: CatalogProductView.iconFor(entity.name),
        color: CatalogProductView.colorFor(entity.name),
        imageUrl: entity.imageUrl,
        variants: entity.variants.map((v) => ProductVariant(
          size: v.size,
          color: v.color,
          quantity: v.quantity,
          price: v.price,
        )).toList(),
        createdBy: entity.createdBy,
      );
    }).toList();
  }
}

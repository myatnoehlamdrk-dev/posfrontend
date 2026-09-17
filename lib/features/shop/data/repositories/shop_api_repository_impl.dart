import 'package:dio/dio.dart';
import 'package:posfrontend/features/shop/data/datasources/shop_api_data_source.dart';
import 'package:posfrontend/features/shop/data/models/shop_api_model.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class ShopApiRepositoryImpl implements ShopApiRepository {
  final ShopApiDataSource _dataSource;

  ShopApiRepositoryImpl({ShopApiDataSource? dataSource})
      : _dataSource = dataSource ?? ShopApiDataSource();

  @override
  Future<ShopEntity> createShop(ShopEntity shop, {CancelToken? cancelToken}) async {
    final model = ShopApiModel.fromEntity(shop);
    final result = await _dataSource.createShop(model);
    return result.toEntity();
  }

  @override
  Future<List<ShopEntity>> getShops({CancelToken? cancelToken}) async {
    final models = await _dataSource.getShops();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ShopEntity> getShopById(String id, {CancelToken? cancelToken}) async {
    final model = await _dataSource.getShopById(id);
    return model.toEntity();
  }
}

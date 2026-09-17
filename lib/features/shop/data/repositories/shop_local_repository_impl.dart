import 'package:posfrontend/features/shop/data/datasources/shop_local_data_source.dart';
import 'package:posfrontend/features/shop/data/models/shop_api_model.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class ShopLocalRepositoryImpl implements ShopLocalRepository {
  final ShopLocalDataSource _dataSource;

  ShopLocalRepositoryImpl({ShopLocalDataSource? dataSource})
      : _dataSource = dataSource ?? ShopLocalDataSource();

  @override
  Future<void> saveShop(ShopEntity shop) async {
    final model = ShopApiModel.fromEntity(shop);
    await _dataSource.saveShop(model);
  }

  @override
  Future<ShopEntity?> getShop() async {
    final model = await _dataSource.getShop();
    return model?.toEntity();
  }

  @override
  Future<void> clearShop() async {
    await _dataSource.clearShop();
  }
}

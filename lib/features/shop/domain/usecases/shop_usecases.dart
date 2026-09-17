import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

class CreateShopUseCase {
  final ShopApiRepository _repository;

  CreateShopUseCase(this._repository);

  Future<ShopEntity> call(ShopEntity shop) => _repository.createShop(shop);
}

class GetShopsUseCase {
  final ShopApiRepository _repository;

  GetShopsUseCase(this._repository);

  Future<List<ShopEntity>> call() => _repository.getShops();
}

class GetShopByIdUseCase {
  final ShopApiRepository _repository;

  GetShopByIdUseCase(this._repository);

  Future<ShopEntity> call(String id) => _repository.getShopById(id);
}

class SaveLocalShopUseCase {
  final ShopLocalRepository _repository;

  SaveLocalShopUseCase(this._repository);

  Future<void> call(ShopEntity shop) => _repository.saveShop(shop);
}

class GetLocalShopUseCase {
  final ShopLocalRepository _repository;

  GetLocalShopUseCase(this._repository);

  Future<ShopEntity?> call() => _repository.getShop();
}

class ClearLocalShopUseCase {
  final ShopLocalRepository _repository;

  ClearLocalShopUseCase(this._repository);

  Future<void> call() => _repository.clearShop();
}

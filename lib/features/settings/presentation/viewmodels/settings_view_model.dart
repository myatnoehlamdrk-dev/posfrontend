import 'dart:typed_data';
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:posfrontend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_local_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsRepository _repository;
  final ImgbbRepository _imgbbRepository;
  final ShopLocalRepository _shopLocalRepository;

  SettingsViewModel({SettingsRepository? repository, ImgbbRepository? imgbbRepository, ShopLocalRepository? shopLocalRepository})
      : _repository = repository ?? SettingsRepositoryImpl(),
        _imgbbRepository = imgbbRepository ?? ImgbbRepositoryImpl(),
        _shopLocalRepository = shopLocalRepository ?? ShopLocalRepositoryImpl();

  SettingsEntity _settings = const SettingsEntity();

  SettingsEntity get settings => _settings;
  AppThemeMode get themeMode => _settings.themeMode;
  String get language => _settings.language;
  ShopType get shopType => _settings.shopType;
  String get shopImage => _settings.shopImage;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isUploadingImage = false;
  bool get isUploadingImage => _isUploadingImage;

  Future<void> loadSettings() async {
    setLoading(true);
    resetError();
    try {
      _settings = await _repository.getSettings();
      _isInitialized = true;
    } catch (e) {
      setError('Failed to load settings');
    } finally {
      setLoading(false);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _settings.themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    _settings = _settings.copyWith(themeMode: newMode);
    notifyListeners();
    try {
      _settings = await _repository.updateSettings(
        themeMode: newMode == AppThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      setError('Failed to update theme');
    }
  }

  Future<void> setLanguage(String lang) async {
    _settings = _settings.copyWith(language: lang);
    notifyListeners();
    try {
      _settings = await _repository.updateSettings(language: lang);
    } catch (e) {
      setError('Failed to update language');
    }
  }

  Future<void> setShopType(ShopType type) async {
    _settings = _settings.copyWith(shopType: type);
    notifyListeners();
    try {
      _settings = await _repository.updateSettings(
        shopType: shopTypeValue(type),
      );
    } catch (e) {
      setError('Failed to update shop type');
    }
  }

  String shopTypeLabel(ShopType type) {
    switch (type) {
      case ShopType.shop:
        return 'Shop';
      case ShopType.service:
        return 'Service';
      case ShopType.restaurant:
        return 'Restaurant';
      case ShopType.store:
        return 'Store';
    }
  }

  String shopTypeValue(ShopType type) {
    switch (type) {
      case ShopType.shop:
        return 'shop';
      case ShopType.service:
        return 'service';
      case ShopType.restaurant:
        return 'restaurant';
      case ShopType.store:
        return 'store';
    }
  }

  Future<void> updateShopImage(Uint8List imageBytes, {String? fileName}) async {
    _isUploadingImage = true;
    notifyListeners();
    try {
      final result = await _imgbbRepository.uploadImage(
        imageBytes,
        fileName: fileName ?? 'shop_image.jpg',
      );
      _settings = _settings.copyWith(shopImage: resolveMediaUrl(result.url) ?? '');
      notifyListeners();
      _settings = await _repository.updateSettings(shopImage: result.url);

      final shop = await _shopLocalRepository.getShop();
      if (shop != null) {
        await _shopLocalRepository.saveShop(shop.copyWith(logoData: '', logoUrl: result.url));
      }
    } catch (e) {
      setError('Failed to upload image');
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }
}

import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/modules/settings/model/settings_models.dart';
import 'package:posfrontend/modules/settings/repository/setting_repository.dart';
import 'package:posfrontend/modules/settings/repository/setting_repository_impl.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingRepository _repository;

  SettingsViewModel({SettingRepository? repository})
      : _repository = repository ?? SettingRepositoryImpl();

  SettingsData _settings = const SettingsData();

  SettingsData get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  String get language => _settings.language;
  ShopType get shopType => _settings.shopType;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

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
    final newMode = _settings.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _settings = _settings.copyWith(themeMode: newMode);
    notifyListeners();
    try {
      _settings = await _repository.updateSettings(
        themeMode: newMode == ThemeMode.dark ? 'dark' : 'light',
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
}

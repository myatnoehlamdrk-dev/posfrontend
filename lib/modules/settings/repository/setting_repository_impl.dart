import 'package:dio/dio.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/settings/model/settings_models.dart';
import 'package:posfrontend/modules/settings/repository/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final Dio _dio;

  SettingRepositoryImpl([Dio? dio]) : _dio = dio ?? ApiClient.create();

  @override
  Future<SettingsData> getSettings() async {
    try {
      final response = await _dio.get('/api/settings');
      final data = response.data as Map<String, dynamic>;
      return SettingsData(
        themeMode: data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
        language: data['language'] as String? ?? 'Myanmar',
        shopType: _parseShopType(data['shopType'] as String? ?? 'shop'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SettingsData> updateSettings({String? themeMode, String? language, String? shopType}) async {
    try {
      final body = <String, dynamic>{};
      if (themeMode != null) body['theme_mode'] = themeMode;
      if (language != null) body['language'] = language;
      if (shopType != null) body['shop_type'] = shopType;

      final response = await _dio.put('/api/settings', data: body);
      final data = response.data as Map<String, dynamic>;
      return SettingsData(
        themeMode: data['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
        language: data['language'] as String? ?? 'Myanmar',
        shopType: _parseShopType(data['shopType'] as String? ?? 'shop'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  ShopType _parseShopType(String value) {
    switch (value) {
      case 'service':
        return ShopType.service;
      case 'restaurant':
        return ShopType.restaurant;
      case 'store':
        return ShopType.store;
      default:
        return ShopType.shop;
    }
  }
}

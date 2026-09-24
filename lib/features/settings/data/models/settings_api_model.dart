import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';

class SettingsApiModel {
  static SettingsEntity fromJson(Map<String, dynamic> json) {
    return SettingsEntity(
      themeMode: json['themeMode'] == 'dark' ? AppThemeMode.dark : AppThemeMode.light,
      language: json['language'] as String? ?? 'Myanmar',
      shopType: _parseShopType(json['shopType'] as String? ?? 'shop'),
      shopImage: resolveMediaUrl(json['shopImage'] as String?) ?? '',
    );
  }

  static ShopType _parseShopType(String value) {
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

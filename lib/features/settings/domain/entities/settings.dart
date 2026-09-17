import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark }
enum ShopType { shop, service, restaurant, store }

class SettingsEntity extends Equatable {
  final AppThemeMode themeMode;
  final String language;
  final ShopType shopType;
  final String shopImage;
  final String appVersion;
  final String privacyPolicyVersion;
  final String termsOfServiceVersion;
  final bool isAuthenticated;

  const SettingsEntity({
    this.themeMode = AppThemeMode.light,
    this.language = 'Myanmar',
    this.shopType = ShopType.shop,
    this.shopImage = '',
    this.appVersion = '1.0.0',
    this.privacyPolicyVersion = '1.0',
    this.termsOfServiceVersion = '1.0',
    this.isAuthenticated = true,
  });

  SettingsEntity copyWith({
    AppThemeMode? themeMode,
    String? language,
    ShopType? shopType,
    String? shopImage,
    String? appVersion,
    String? privacyPolicyVersion,
    String? termsOfServiceVersion,
    bool? isAuthenticated,
  }) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      shopType: shopType ?? this.shopType,
      shopImage: shopImage ?? this.shopImage,
      appVersion: appVersion ?? this.appVersion,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      termsOfServiceVersion: termsOfServiceVersion ?? this.termsOfServiceVersion,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props => [themeMode, language, shopType];
}

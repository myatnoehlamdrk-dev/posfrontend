enum ThemeMode { light, dark }

enum ShopType { shop, service, restaurant, store }

class SettingsData {
  final ThemeMode themeMode;
  final String language;
  final ShopType shopType;
  final String appVersion;
  final String privacyPolicyVersion;
  final String termsOfServiceVersion;
  final bool isAuthenticated;

  const SettingsData({
    this.themeMode = ThemeMode.light,
    this.language = 'Myanmar',
    this.shopType = ShopType.shop,
    this.appVersion = '1.0.0',
    this.privacyPolicyVersion = '1.0',
    this.termsOfServiceVersion = '1.0',
    this.isAuthenticated = true,
  });

  SettingsData copyWith({
    ThemeMode? themeMode,
    String? language,
    ShopType? shopType,
    String? appVersion,
    String? privacyPolicyVersion,
    String? termsOfServiceVersion,
    bool? isAuthenticated,
  }) {
    return SettingsData(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      shopType: shopType ?? this.shopType,
      appVersion: appVersion ?? this.appVersion,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      termsOfServiceVersion: termsOfServiceVersion ?? this.termsOfServiceVersion,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

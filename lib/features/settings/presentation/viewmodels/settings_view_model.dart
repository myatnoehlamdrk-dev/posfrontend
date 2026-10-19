import 'dart:typed_data';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/shared/theme/theme_mode_notifier.dart';
import 'package:posfrontend/features/settings/domain/entities/feedback.dart';
import 'package:posfrontend/features/settings/domain/entities/settings.dart';
import 'package:posfrontend/features/settings/domain/repositories/feedback_repository.dart';
import 'package:posfrontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:posfrontend/features/settings/data/repositories/feedback_repository_impl.dart';
import 'package:posfrontend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:posfrontend/features/settings/presentation/server_preferences.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_local_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';

class SettingsViewModel extends BaseViewModel {
  final SettingsRepository _repository;
  final ImgbbRepository _imgbbRepository;
  final ShopLocalRepository _shopLocalRepository;
  final FeedbackRepository _feedbackRepository;

  SettingsViewModel({
    SettingsRepository? repository,
    ImgbbRepository? imgbbRepository,
    ShopLocalRepository? shopLocalRepository,
    FeedbackRepository? feedbackRepository,
  }) : _repository = repository ?? SettingsRepositoryImpl(),
       _imgbbRepository = imgbbRepository ?? ImgbbRepositoryImpl(),
       _shopLocalRepository = shopLocalRepository ?? ShopLocalRepositoryImpl(),
       _feedbackRepository = feedbackRepository ?? FeedbackRepositoryImpl();

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

  /// True when the shop photo was kept on the API host instead of ImgBB.
  ///
  /// [updateShopImage] still succeeds in that case — the file is saved and the
  /// URL works — but it lives on one machine only, so the Settings screen
  /// shows a warning in place of the success toast.
  bool _imageStoredLocally = false;
  bool get imageStoredLocally => _imageStoredLocally;

  bool _isSubmittingFeedback = false;
  bool get isSubmittingFeedback => _isSubmittingFeedback;

  Future<void> loadSettings() async {
    setLoading(true);
    resetError();
    try {
      _settings = await _repository.getSettings();
      _isInitialized = true;
      // Theme and language go through the same helper the post-login sync
      // uses, so the Settings screen and session start always agree.
      applyServerPreferences(_settings);
    } catch (e) {
      setError('Failed to load settings');
    } finally {
      setLoading(false);
    }
  }

  /// The brightness actually on screen. A residual "system" (only possible
  /// before the first load pins it) resolves to the OS value.
  ThemeMode get _effectiveMode {
    final mode = ThemeModeNotifier.instance.value;
    if (mode != ThemeMode.system) return mode;
    return ThemeModeNotifier.system;
  }

  Future<void> toggleTheme() async {
    final newMode = _effectiveMode == ThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    _settings = _settings.copyWith(themeMode: newMode);
    ThemeModeNotifier.instance.setMode(
      newMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
    );
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
    _imageStoredLocally = false;
    notifyListeners();
    try {
      final result = await _imgbbRepository.uploadImage(
        imageBytes,
        fileName: fileName ?? 'shop_image.jpg',
      );
      _imageStoredLocally = result.storedLocally;
      _settings = _settings.copyWith(
        shopImage: resolveMediaUrl(result.url) ?? '',
      );
      notifyListeners();
      _settings = await _repository.updateSettings(shopImage: result.url);

      try {
        final shop = await _shopLocalRepository.getShop();
        if (shop != null) {
          await _shopLocalRepository.saveShop(
            shop.copyWith(logoData: '', logoUrl: result.url),
          );
        }
      } catch (_) {}
    } catch (e) {
      setError('Failed to upload image: ${formatApiError(e)}');
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Post the Settings > Feedback form to the API. Returns true only when the
  /// server accepted it, so the caller can keep the dialog open on failure.
  Future<bool> submitFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    _isSubmittingFeedback = true;
    resetError();
    notifyListeners();
    try {
      await _feedbackRepository.submitFeedback(type: type, message: message);
      return true;
    } catch (e) {
      setError('Failed to submit feedback');
      return false;
    } finally {
      _isSubmittingFeedback = false;
      notifyListeners();
    }
  }
}

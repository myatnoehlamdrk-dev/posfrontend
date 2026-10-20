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
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 0.0–1.0 while the shop photo is uploading, null when nothing measurable
  /// is happening (compressing the picked file, or not uploading at all).
  ///
  /// A determinate value is what lets the Settings card draw a real progress
  /// bar: on a slow connection the upload takes long enough that "still
  /// running" and "silently stalled" look identical without one.
  double? _imageProgress;
  double? get imageProgress => _imageProgress;

  /// What the current upload wait is for, for the card's label.
  String? _imageUploadPhase;
  String? get imageUploadPhase => _imageUploadPhase;

  /// Marks the pick/compress/upload sequence as running, before any of it
  /// starts.
  ///
  /// Called by the screen the moment the picker returns: compression happens
  /// before [updateShopImage] runs, and on a large photo that is seconds of
  /// work that used to happen with no indicator at all.
  void beginImageUpload() {
    _isUploadingImage = true;
    _imageProgress = null;
    _imageUploadPhase = 'Optimising';
    notifyListeners();
  }

  /// True when the upload only reached the API host because ImgBB did not —
  /// the fallback path, not the planned one.
  ///
  /// [updateShopImage] still succeeds in that case — the file is saved and the
  /// URL works — but it lives on one machine only, so the Settings screen
  /// shows a warning in place of the success toast. Under the default
  /// local-first storage this is false for a normal upload: keeping the photo
  /// on the shop server is the plan there, and warning about every upload
  /// would train the warning away.
  bool _imageUploadFellBack = false;
  bool get imageUploadFellBack => _imageUploadFellBack;

  /// SharedPreferences key holding the shop image URL that last loaded —
  /// the "last known good" shown when a fetch comes back empty or not at all.
  static const String _lastShopImageKey = 'last_known_shop_image';

  bool _isSubmittingFeedback = false;
  bool get isSubmittingFeedback => _isSubmittingFeedback;

  Future<void> loadSettings() async {
    setLoading(true);
    resetError();
    try {
      _settings = await _repository.getSettings();
      _isInitialized = true;
      if (_settings.shopImage.isEmpty) {
        // The server answered but handed back no image (shop row missing a
        // logo, a partially-seeded database…). Rather than dropping the card
        // to its default state, fall back to the last image that did load —
        // the same last-known-good copy the offline start uses.
        final lastKnown = await _lastKnownShopImage();
        if (lastKnown.isNotEmpty) {
          _settings = _settings.copyWith(shopImage: lastKnown);
        }
      } else {
        await _rememberShopImage(_settings.shopImage);
      }
      // Theme and language go through the same helper the post-login sync
      // uses, so the Settings screen and session start always agree.
      applyServerPreferences(_settings);
    } catch (e) {
      // The server did not answer at all: show the last image it did give us
      // rather than an empty card.
      final lastKnown = await _lastKnownShopImage();
      if (lastKnown.isNotEmpty && _settings.shopImage.isEmpty) {
        _settings = _settings.copyWith(shopImage: lastKnown);
      }
      setError('Failed to load settings');
    } finally {
      setLoading(false);
    }
  }

  /// The shop image URL that last loaded successfully, or '' if none is
  /// recorded yet. Never throws: a preferences failure must not mask the
  /// error being reported by the caller.
  Future<String> _lastKnownShopImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastShopImageKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Records [url] as the last-known shop image. An empty value clears the
  /// record; failures are ignored — this is a cache, not a save.
  Future<void> _rememberShopImage(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url.isEmpty) {
        await prefs.remove(_lastShopImageKey);
      } else {
        await prefs.setString(_lastShopImageKey, url);
      }
    } catch (_) {}
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
    _imageUploadFellBack = false;
    // The bytes are about to move, so the bar switches from sweeping
    // ("Optimising") to filling. Set before the request so a fast connection
    // never shows the previous phase's label over a finished bar.
    _imageProgress = 0;
    _imageUploadPhase = 'Uploading';
    notifyListeners();
    try {
      final result = await _imgbbRepository.uploadImage(
        imageBytes,
        fileName: fileName ?? 'shop_image.jpg',
        onProgress: (sent, total) {
          if (total <= 0) return;
          _imageProgress = (sent / total).clamp(0.0, 1.0);
          notifyListeners();
        },
      );
      _imageUploadFellBack = result.fellBack;
      _settings = _settings.copyWith(
        shopImage: resolveMediaUrl(result.url) ?? '',
      );
      // A successful upload is by definition the new last-known-good image.
      await _rememberShopImage(_settings.shopImage);
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
      // Cleared so the next upload starts from a clean bar rather than
      // flashing the previous run's final percentage.
      _imageProgress = null;
      _imageUploadPhase = null;
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

import 'package:posfrontend/shared/l10n/strings/japanese.dart';
import 'package:posfrontend/shared/l10n/strings/myanmar.dart';
import 'package:posfrontend/shared/l10n/strings/thai.dart';
import 'package:posfrontend/shared/l10n/app_language.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';
import 'package:flutter/widgets.dart';

/// The app's translation store.
///
/// ## Why the maps are keyed by English text
///
/// Translations are looked up by the English source string rather than by an
/// invented key like `product.stockAdd`. That buys three things:
///
/// 1. A missing translation is a no-op, not a crash or a raw key on screen —
///    `t` returns the English it was given. This is what makes it safe to ship
///    with [myStrings]/[thaiStrings]/[japaneseStrings] empty while the
///    translations are still being written.
/// 2. ViewModels, repositories and services have no [BuildContext], so they
///    cannot call `context.l10n`. Because they already produce English text,
///    translating at the point of *display* covers every one of them without
///    touching a single ViewModel.
/// 3. English needs no map of its own — it is the lookup key, so an absent
///    entry is the English string.
///
/// The trade-off is that a typo is silent rather than a compile error, since
/// `t('Cancel')` and `t('Cancle')` both type-check. `tool/extract_strings.sh`
/// exists to catch that: it scans the tree for user-facing literals and
/// reports the ones missing from the translation maps, so run it after adding
/// screens rather than trusting the compiler.
///
/// Use a typed getter ([cancel], [addProduct], ...) for anything that appears
/// more than once or is load-bearing, so a mistake is visible in review. Reach
/// for [t] for one-off copy.
class AppStrings {
  const AppStrings(this.language, this._overrides);

  final AppLanguage language;
  final Map<String, String> _overrides;

  static const AppStrings _myanmar = AppStrings(AppLanguage.myanmar, myStrings);
  static const AppStrings _thai = AppStrings(AppLanguage.thai, thaiStrings);
  static const AppStrings _japanese = AppStrings(
    AppLanguage.japanese,
    japaneseStrings,
  );

  /// English is the key space, so it needs no overrides of its own.
  static const AppStrings _english = AppStrings(AppLanguage.english, {});

  static const Map<AppLanguage, AppStrings> _all = {
    AppLanguage.myanmar: _myanmar,
    AppLanguage.english: _english,
    AppLanguage.thai: _thai,
    AppLanguage.japanese: _japanese,
  };

  static AppStrings ofLanguage(AppLanguage language) =>
      _all[language] ?? _english;

  static AppStrings of(BuildContext context) =>
      ofLanguage(AppLanguage.fromLocale(Localizations.localeOf(context)));

  /// The active language, resolved without a [BuildContext].
  ///
  /// For widget helper methods that were not handed a context, and for
  /// services such as the receipt PDF writer. Prefer [of] anywhere a context is
  /// actually in scope: the whole subtree is rebuilt when the app locale
  /// changes, but reading [current] does not itself register a dependency, so
  /// only prefer it where there is no context to be had.
  static AppStrings get current => ofLanguage(LocaleNotifier.instance.language);

  /// Translates [english], returning it unchanged when no translation exists.
  String t(String english) => _overrides[english] ?? english;

  // -- Actions -------------------------------------------------------------
  String get cancel => t('Cancel');
  String get add => t('Add');
  String get edit => t('Edit');
  String get update => t('Update');
  String get save => t('Save');
  String get delete => t('Delete');
  String get remove => t('Remove');
  String get create => t('Create');
  String get close => t('Close');
  String get confirm => t('Confirm');
  String get retry => t('Retry');
  String get search => t('Search');
  String get clear => t('Clear');
  String get apply => t('Apply');
  String get select => t('Select');
  String get submit => t('Submit');
  String get logout => t('Logout');
  String get login => t('Login');
  String get register => t('Register');
  String get back => t('Back');
  String get next => t('Next');
  String get upload => t('Upload');
  String get change => t('Change');
  String get all => t('All');
  String get yes => t('Yes');
  String get no => t('No');
  String get more => t('More');

  // -- Navigation ----------------------------------------------------------
  String get dashboard => t('Dashboard');
  String get inventory => t('Inventory');
  String get product => t('Product');
  String get addProduct => t('Add Product');
  String get addToCart => t('Add to Cart');
  String get saleItem => t('Sale Item');
  String get purchaseItem => t('Purchase Item');
  String get setting => t('Setting');

  // -- Common field labels -------------------------------------------------
  String get name => t('Name');
  String get price => t('Price');
  String get qty => t('Qty');
  String get quantity => t('Quantity');
  String get stock => t('Stock');
  String get category => t('Category');
  String get total => t('Total');
  String get date => t('Date');
  String get time => t('Time');
  String get notes => t('Notes');
  String get type => t('Type');
  String get status => t('Status');
  String get order => t('Order');
  String get active => t('Active');
  String get pending => t('Pending');
  String get completed => t('Completed');
  String get unknown => t('Unknown');
  String get inStock => t('In Stock');
  String get outOfStock => t('Out of Stock');
  String get outOfStockNotification => t('{v1} is out of stock');
  String get lowStock => t('Low Stock');
  String get midCapStock => t('Mid-Cap Stock');
  String get highStock => t('High Stock');
}

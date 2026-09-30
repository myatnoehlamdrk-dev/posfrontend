import 'package:posfrontend/shared/l10n/app_strings.dart';

/// Display helpers for status values that arrive as English text.
///
/// These are Tier C strings: they are produced by the API or computed from raw
/// stock counts, compared literally in logic, and in Package's case persisted
/// verbatim in the database. They must never be translated *in place* —
/// `stockStatus == 'High Stock'` is a real comparison that has to keep
/// matching. Only the rendering goes through a translation.
///
/// The distinction matters: `context.l10n.t(status)` localises a value that is
/// already canonical English, while [canonicalStockStatus] first folds the
/// aliases the API is known to return ('out_of_stock', 'critical',
/// 'mid_cap_stock') onto one spelling so a single translation covers them.
extension StatusL10n on String {
  /// This value as a user sees it.
  String localized(AppStrings strings) => strings.t(canonicalStockStatus);

  /// Folds known aliases onto the canonical spelling used by the UI.
  ///
  /// Defensive rather than essential: the product path computes its status
  /// locally so the spelling is already canonical, but Package round-trips
  /// through the database and has historically held the alias forms.
  String get canonicalStockStatus {
    switch (trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')) {
      case 'high_stock' || 'optimal' || 'overstock':
        return 'High Stock';
      case 'mid_stock' || 'mid_cap_stock' || 'midcap_stock':
        return 'Mid-Cap Stock';
      case 'low_stock':
        return 'Low Stock';
      case 'no_stock' || 'out_of_stock' || 'critical':
        return 'Out of Stock';
      default:
        return this;
    }
  }
}

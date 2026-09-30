import 'package:posfrontend/shared/l10n/app_strings.dart';

/// Localises the messages the API generates itself.
///
/// The backend is Laravel with no custom validation strings, so failures come
/// back as English prose already baked into the response body — the client sees
/// them via `data['message']` and `data['errors']`. Translating on the client
/// is a deliberate choice over an `Accept-Language` round trip: the set is
/// small and closed, and a POS client that is mid-sale on a poor connection
/// should not gain a network dependency for an error message.
///
/// Anything unrecognised falls through to [AppStrings.t] and is shown as the
/// English sentence the server sent. That is the intended behaviour — a new
/// server message should read as plain English, never as a raw key.
///
/// ## Known limitation
///
/// `InsufficientStockException` interpolates values into its message:
///
///     Insufficient stock for 'Silk Scarf': requested 5, available 2
///
/// No whole-string lookup can ever match that, so it stays English. Fixing it
/// properly means the backend returns a stable error *code* plus a params
/// object (`{code: 'stock.insufficient', params: {name, requested, available}}`)
/// and the client formats the code. Recorded as a backend follow-up rather
/// than worked around here with a fragile prefix match.
extension ApiMessageL10n on String {
  /// The canonical English this maps onto, or null if the server did not send
  /// something we recognise.
  String? get canonicalApiMessage => switch (trim()) {
    // Laravel's default validation phrasing, verbatim.
    'The email field is required.' => 'The email field is required.',
    'The password field is required.' => 'The password field is required.',
    'The name field is required.' => 'The name field is required.',
    'The phone field is required.' => 'The phone field is required.',
    'The email has already been taken.' => 'The email has already been taken.',
    'The password confirmation does not match.' =>
      'The password confirmation does not match.',
    // Messages raised from the service layer.
    'Customer not found' => 'Customer not found',
    'Feedback not found' => 'Feedback not found',
    'Sale item does not belong to this sale.' =>
      'Sale item does not belong to this sale.',
    _ => null,
  };

  /// This message as the user should see it.
  String localizedMessage(AppStrings strings) =>
      strings.t(canonicalApiMessage ?? this);
}

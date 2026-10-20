import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';
export 'package:posfrontend/shared/widgets/app_message.dart';
export 'package:posfrontend/shared/widgets/error_snackbar.dart';

/// Backwards-compatible wrapper for the unified [showSuccessMessage]
/// (green, like the login screen's "Login successful" message).
void showSuccessSnackBar(BuildContext context, String message) {
  showSuccessMessage(context, message);
}

/// Tells the user that an upload only reached the API host because ImgBB did
/// not.
///
/// The photo still works, so this is a warning rather than a failure — but the
/// file now exists on one machine and disappears with it, and no other device
/// is guaranteed to reach that host. Saying nothing would leave someone
/// believing a photo is backed up when it is not.
///
/// Gated on [ImgbbUploadResult.fellBack], not `storedLocally`: under the
/// default local-first storage every upload lands on the shop server by
/// design, and warning about each one would only train the warning away.
void showStoredLocallyWarning(
  BuildContext context,
  ImgbbUploadResult result,
) {
  if (!result.fellBack) return;
  showWarningMessage(context, AppStrings.of(context).imageSavedLocally);
}

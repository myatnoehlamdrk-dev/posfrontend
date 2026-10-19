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

/// Tells the user that an upload was kept on the API host instead of ImgBB.
///
/// The photo still works, so this is a warning rather than a failure — but the
/// file now exists on one machine and disappears with it, and no other device
/// is guaranteed to reach that host. Saying nothing would leave someone
/// believing a photo is backed up when it is not.
void showStoredLocallyWarning(
  BuildContext context,
  ImgbbUploadResult result,
) {
  if (!result.storedLocally) return;
  showWarningMessage(context, AppStrings.of(context).imageSavedLocally);
}

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';
export 'package:posfrontend/shared/widgets/app_message.dart';
export 'package:posfrontend/shared/widgets/error_snackbar.dart';

/// Backwards-compatible wrapper for the unified [showSuccessMessage]
/// (green, like the login screen's "Login successful" message).
void showSuccessSnackBar(BuildContext context, String message) {
  showSuccessMessage(context, message);
}
import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';

/// Backwards-compatible wrapper for the unified [showErrorMessage]
/// (always red, like the login screen's failure message).
void showErrorSnackBar(BuildContext context, Object error) {
  showErrorMessage(context, error);
}
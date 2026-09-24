import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

/// Unified success/error message style for the whole app.
///
/// Success looks like the login screen's "Login successful" message (green),
/// failure is always red. Use [AppMessageBanner] for inline messages, or
/// [showSuccessMessage] / [showErrorMessage] for a floating toast.
enum AppMessageKind { success, error }

const Color kAppSuccessColor = Color(0xFF16A34A);
const Color kAppErrorColor = Color(0xFFEF4444);

class AppMessageBanner extends StatelessWidget {
  final String message;
  final AppMessageKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppMessageBanner({
    super.key,
    required this.message,
    this.kind = AppMessageKind.success,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final success = kind == AppMessageKind.success;
    final background = success ? kAppSuccessColor : kAppErrorColor;
    final icon = success
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

void showSuccessMessage(BuildContext context, String message) {
  _showMessage(
    context,
    AppMessageBanner(message: message, kind: AppMessageKind.success),
  );
}

void showErrorMessage(BuildContext context, Object error) {
  _showMessage(
    context,
    AppMessageBanner(
      message: error is AppException ? error.message : error.toString(),
      kind: AppMessageKind.error,
    ),
  );
}

void _showMessage(BuildContext context, AppMessageBanner banner) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: banner,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
}
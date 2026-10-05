import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/shared/l10n/api_message_l10n.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Unified success/error message style for the whole app.
///
/// Success looks like the login screen's "Login successful" message (green),
/// failure is always red. Use [AppMessageBanner] for inline messages, or
/// [showSuccessMessage] / [showErrorMessage] for a floating toast.
enum AppMessageKind { success, error }

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
    final p = context.palette;
    final success = kind == AppMessageKind.success;
    final background = success ? p.successBg : p.dangerBg;
    final foreground = success ? p.successFg : p.dangerFg;
    final icon = success
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              // Translated here rather than at each call site. Most messages
              // originate in ViewModels, which have no BuildContext, so this is
              // the one place that can localise them. `localizedMessage` also
              // normalises the fixed English sentences the API returns;
              // anything unrecognised is passed through untouched.
              message.localizedMessage(AppStrings.of(context)),
              style: TextStyle(
                color: foreground,
                fontSize: AppTypography.bodySmallSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.s8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: Text(AppStrings.of(context).t(actionLabel!)),
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
        margin: const EdgeInsets.all(AppSpacing.s16),
        duration: const Duration(seconds: 3),
      ),
    );
}

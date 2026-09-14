import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';

/// Global standard error SnackBar — red background, white text, icon.
/// Use anywhere: `showErrorSnackBar(context, exception);`
void showErrorSnackBar(BuildContext context, Object error) {
  final message = _extractMessage(error);
  final icon = _iconForError(error);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
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
          ],
        ),
        backgroundColor: _colorForError(error),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: error is AuthException ? 3 : 4),
        action: error is AuthException
            ? SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  // Navigator push to login is handled by the caller
                },
              )
            : null,
      ),
    );
}

String _extractMessage(Object error) {
  if (error is AppException) return error.message;
  return error.toString();
}

Color _colorForError(Object error) {
  if (error is NetworkException) return const Color(0xFFDC2626); // red-600
  if (error is TimeoutException) return const Color(0xFFEA580C); // orange-600
  if (error is AuthException) return const Color(0xFFDC2626); // red-600
  if (error is ValidationException) return const Color(0xFFDC2626); // red-600
  if (error is ServerException) return const Color(0xFF7C2D12); // red-900
  return const Color(0xFFDC2626); // default red
}

IconData _iconForError(Object error) {
  if (error is NetworkException) return Icons.wifi_off_rounded;
  if (error is TimeoutException) return Icons.timer_off_rounded;
  if (error is AuthException) return Icons.lock_outline_rounded;
  if (error is ValidationException) return Icons.error_outline_rounded;
  if (error is ServerException) return Icons.cloud_off_rounded;
  return Icons.error_outline_rounded;
}

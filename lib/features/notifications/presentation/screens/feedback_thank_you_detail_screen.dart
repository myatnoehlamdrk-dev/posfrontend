import 'package:flutter/material.dart';
import 'package:posfrontend/features/notifications/domain/entities/app_notification.dart';
import 'package:posfrontend/features/settings/domain/entities/feedback.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

/// Detail page behind the "Thank You" push that follows a feedback
/// submission.
///
/// Deliberately NOT an alert: the payload carries `category: system`, so it
/// lives in the System tab, and it opens here instead of on a product page —
/// the same document shape as [StockReportDetailScreen]: heading, date,
/// divider, then the message built from the `{v1}` tags in `data` so the
/// sentence is translated at display time, with the type and the submitted
/// text echoed underneath.
class FeedbackThankYouDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const FeedbackThankYouDetailScreen({super.key, required this.notification});

  String _data(String key) => (notification.data[key] ?? '').toString();

  String _dateLine(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final userName = _data('user_name');
    final message = _data('message');
    final reference = _data('feedback_id');
    final type = FeedbackType.fromValue(_data('feedback_type'));

    // The name travels as a {v1} tag so each language composes its own
    // sentence rather than inheriting the English body from the push.
    final greeting = userName.isEmpty
        ? context.l10n.t('Thank you for your feedback!')
        : context.l10n
            .t('Thank you for your feedback, {v1}!')
            .replaceFirst('{v1}', userName);

    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: notification.title,
              showBackButton: true,
              showMenuButton: false,
              showNotificationsButton: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            notification.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: AppTypography.titleMediumSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            _dateLine(notification.receivedAt),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: AppTypography.bodySmallSize,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Divider(height: 1, color: p.border),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          greeting,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: AppTypography.bodyMediumSize,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        _DocLine(
                          label: context.l10n.t('Type'),
                          value: context.l10n.t(type.label),
                        ),
                        if (reference.isNotEmpty)
                          _DocLine(
                            label: context.l10n.t('Reference'),
                            value: '#$reference',
                          ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            context.l10n.t('Your message'),
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: AppTypography.bodyMediumSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Divider(height: 1, color: p.border),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            message,
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: AppTypography.bodyMediumSize,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value row of the document, e.g. `Type  Suggestion`.
class _DocLine extends StatelessWidget {
  final String label;
  final String value;

  const _DocLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: p.textMuted,
                fontSize: AppTypography.bodySmallSize,
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: AppTypography.bodyMediumSize,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

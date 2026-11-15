import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// A standard empty state: icon, title, optional subtitle and optional action.
///
/// Replaces the ad-hoc `Container(padding:…, child: Text('No …'))` blocks that
/// were scattered across the finance, inventory and product screens, so every
/// empty state shares one layout, spacing and tone.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  /// Headline, e.g. "No sales recorded in November 2026."
  final String title;

  /// Supporting line, e.g. "Try a different month or check your filters."
  final String? subtitle;

  /// Leading glyph. Defaults to an inbox icon.
  final IconData icon;

  /// Tint for the icon. Defaults to the muted text token.
  final Color? iconColor;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback for the optional action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.xl,
              color: iconColor ?? p.textMuted,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.titleSmallSize,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.bodySmallSize,
                  color: p.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.s16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

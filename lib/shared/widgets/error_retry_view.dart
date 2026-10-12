import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The one place a screen renders "load failed → Retry".
///
/// Every feature used to hand-roll its own copy of this, and the copies
/// disagreed on all three things that make it read as broken:
///
///  * **centring** — a bare `Center` inside a scroll view collapses to its
///    child and pins the message to the top of the page; the fix is a floor
///    of one viewport, which [LayoutBuilder] applies here (falling back to
///    the screen height when the incoming constraints are unbounded, so it
///    centres without the caller having to remember `RefreshableBody.fill`);
///    pass [fill] as `false` when the state sits *inside* a page (under a
///    breadcrumb or search bar) and should keep its natural height instead
///    of claiming a screenful;
///  * **width** — a raw API error is one long line, and without a cap it
///    runs edge to edge. The block is capped at [_maxWidth] and the message
///    is centre-aligned, so it stops spanning the screen;
///  * **height** — a very long message inside a fixed-height box (the old
///    `SizedBox(height: 300)`) overflowed the RenderFlex. Here the content
///    scrolls, so it can never paint over the rest of the page.
class ErrorRetryView extends StatelessWidget {
  /// Widest the message block is allowed to get. Anything longer wraps to a
  /// centred paragraph instead of a screen-wide line.
  static const double _maxWidth = 340;

  /// Kept outside [_maxWidth] so the block keeps its breathing room without
  /// eating into the message width.
  static const EdgeInsets _padding = EdgeInsets.all(AppSpacing.s24);

  const ErrorRetryView({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.icon = Icons.error_outline,
    this.accentColor = AppColors.brandPurple,
    this.retryLabel,
    this.messageColor,
    this.fill = true,
  });

  /// The failure, straight from the view model. `null`/empty shows the
  /// heading alone.
  final String? message;

  /// Re-runs the load. `null` renders no button (an error with no way to
  /// recover, e.g. an empty state that only pull-to-refresh can clear).
  final VoidCallback? onRetry;

  /// Optional heading above the message, for states that name the failure
  /// ("Could not load") before explaining it.
  final String? title;

  final IconData icon;
  final Color accentColor;
  final String? retryLabel;

  /// Message colour; failures read red unless the caller says otherwise
  /// (an empty state rendered through the same widget is not an error).
  final Color? messageColor;

  /// Stretches the block to at least one viewport so it lands in the middle
  /// of the screen. Turn it off for a state that is only one section of a
  /// larger page: a screenful there would push the message far below its
  /// heading and add dead scroll.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasMessage = message != null && message!.trim().isNotEmpty;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: p.textMuted),
        if (title != null || hasMessage) const SizedBox(height: AppSpacing.s16),
        if (title != null)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: AppTypography.bodyMediumSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (title != null && hasMessage) const SizedBox(height: AppSpacing.s8),
        if (hasMessage)
          Text(
            message!.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: messageColor ?? p.dangerFg,
              fontSize: AppTypography.bodyMediumSize,
              height: 1.45,
            ),
          ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.s20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(context.l10n.t(retryLabel ?? 'Retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // A viewport floor is what turns "top of the page" into "middle of
        // the page". Inside a scroll view the height is unbounded, so fall
        // back to the screen: the block then occupies a screenful and the
        // content is centred within it.
        final floor = !fill
            ? 0.0
            : constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;

        // The padding lives INSIDE the floor: a viewport-floor box plus an
        // outer inset would be taller than the screen and leave a dead
        // scroll of a few dozen pixels.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: floor),
            // Center fills the floor and centres [inner] in both axes; when
            // the content is taller than the floor the box grows with it and
            // the scroll view above takes over — no overflow.
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxWidth + _padding.horizontal,
                ),
                child: Padding(
                  padding: _padding,
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

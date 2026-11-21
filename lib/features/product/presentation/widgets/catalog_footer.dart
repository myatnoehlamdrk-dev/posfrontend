import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// The catalog page's footer.
///
/// Three locale facts — the UI language, the currency and the country — which is
/// what a shop owner checks before trusting a price on screen.
///
/// These are labels, not controls. Nothing here navigates: the currency and
/// country are fixed in this app (MMK throughout, Myanmar-only shops) and the
/// language is changed from Settings, which a chevron here would only imply
/// without adding a second route to the same picker. None of the three carries a
/// tap target, and none is drawn like something tappable.
///
/// The whole footer rebuilds when the locale changes because it reads
/// [LocaleNotifier], which `MaterialApp` listens to.
class CatalogFooter extends StatelessWidget {
  const CatalogFooter({super.key});

  /// Below this the three tiles are stacked instead of laid out in a row.
  ///
  /// Three across at a phone's width leaves roughly 90px per tile, which is
  /// enough for "MMK" and not enough for "Myanmar" next to a caption — the
  /// country name is the one here most likely to be truncated into uselessness.
  /// Stacking trades a little vertical space for all three being readable, which
  /// is the right way round for something whose whole job is to be read.
  static const double _inlineBreakpoint = 460;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.cardShadow.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Clip so the accent rule laid over the top edge follows the corners.
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The accent rule: a brand-coloured hairline that fades out at both
          // ends, rather than the flat grey line that used to cap the block.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.primary.withValues(alpha: 0),
                    p.primary.withValues(alpha: 0.9),
                    p.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tiles = [
                  _FooterTile(
                    icon: Icons.language_rounded,
                    // The autonym rather than the English name: a shop owner who
                    // cannot read the current UI still has to be able to find
                    // their own language here.
                    label: LocaleNotifier.instance.language.autonym,
                    caption: context.l10n.t('Language'),
                  ),
                  _FooterTile(
                    icon: Icons.payments_outlined,
                    label: 'MMK',
                    caption: context.l10n.t('Currency'),
                  ),
                  _FooterTile(
                    icon: Icons.public_rounded,
                    label: context.l10n.t('Myanmar'),
                    caption: context.l10n.t('Country'),
                  ),
                ];

                return constraints.maxWidth < _inlineBreakpoint
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final tile in tiles) ...[
                            tile,
                            const SizedBox(height: 8),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: tiles[i]),
                          ],
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  const _FooterTile({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Plain GestureDetector-free Container, deliberately not InkWell: these are
    // read-only, and a press ripple would promise an action that does not exist.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          // The icon sits in a tinted badge so the three facts read as a set of
          // indicators rather than as three plain list rows.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: p.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.labelMediumSize,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmallSize,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

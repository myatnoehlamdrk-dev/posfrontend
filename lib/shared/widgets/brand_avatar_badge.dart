import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// A circular brand avatar with a small gradient badge on the bottom-right.
///
/// The auth screens use it as the visual anchor of their form cards: login
/// shows the shop illustration with a lock badge, forgot-password shows the
/// recovery artwork with a key badge. The ring and the badge use
/// [AppColors.brandRamp] by default; [accent] lets a screen override that when
/// its artwork already fills with the brand hue and the default frame would
/// disappear into the image.
///
/// The badge is deliberately a parameter rather than fixed to a lock: the
/// symbol is the only thing that changes between the two screens, and a lock on
/// a "forgot password" card is the wrong message.
class BrandAvatarBadge extends StatelessWidget {
  const BrandAvatarBadge({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.badgeIcon = Icons.lock_rounded,
    this.size = standardSize,
    this.imageScale = 1.0,
    this.imageAlignment = Alignment.center,
    this.accent = AppColors.brandRamp,
  });

  /// The diameter shared by the auth cards.
  ///
  /// Both login and forgot-password use this rather than a literal, so the two
  /// avatars cannot drift apart when one screen is edited.
  static const double standardSize = 108;

  /// The artwork drawn inside the avatar.
  final String image;

  /// Spoken description for screen readers.
  final String semanticLabel;

  /// The symbol shown in the corner badge.
  final IconData badgeIcon;

  /// Overall diameter, including the gradient ring.
  final double size;

  /// Zoom applied to the artwork inside the circle.
  ///
  /// Landscape artwork that is mostly scene (the login illustration) needs a
  /// value above 1 so the figure reads as a portrait; a square mark
  /// (forgot-password) is left at 1.
  final double imageScale;

  /// Anchor used when [imageScale] is not 1, in the image widget's space.
  final Alignment imageAlignment;

  /// Colours for the ring and the corner badge.
  ///
  /// Defaults to the brand ramp. Pass a different ramp when the artwork is
  /// already violet — the default would leave the frame blending into the
  /// image instead of separating it.
  final List<Color> accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ring = size >= 96 ? 4.0 : 3.0;
    final badgeSize = size / 3;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(ring),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: accent,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surface,
                ),
                child: Transform.scale(
                  scale: imageScale,
                  alignment: imageAlignment,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    cacheWidth: (size * 6).round(),
                  ),
                ),
              ),
            ),
            // The badge sits a couple of pixels outside the ring, with a
            // surface-coloured border so it reads as a separate object rather
            // than as a notch cut out of the avatar.
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: accent,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: p.surface, width: ring),
                ),
                child: Icon(
                  badgeIcon,
                  color: Colors.white,
                  size: badgeSize * 0.44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

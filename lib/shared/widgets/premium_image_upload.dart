import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';

/// Premium, mobile-first image upload surface.
///
/// Visual layers (bottom → top):
///   1. Soft ambient glow behind the surface
///   2. Rounded surface with tinted fill and subtle primary outline
///   3. Image / empty state
///   4. Optional gradient scrim for legibility over photos
///   5. Solid outline stays visible over any photo
///   6. Optional "change" chip anchored bottom-right
///   7. Busy overlay — scrim, label and [progress] bar, drawn over whatever
///      is underneath so a *replace* is as visible as a first upload
///
/// Colours come from [AppPalette] so the control follows the active theme.
class PremiumImageUpload extends StatelessWidget {
  final VoidCallback? onTap;

  /// Rendered inside the surface. Provide exactly one image source, or a
  /// fully custom [image] widget.
  final Widget? image;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? imageBase64;

  /// When true the surface shows a busy overlay instead of the empty state —
  /// and, when an image is already there, over the top of it too.
  final bool isBusy;

  /// How far the upload has got, 0.0–1.0.
  ///
  /// A real value (from the transport's send callback) draws a determinate
  /// bar, which is what a slow connection needs — "waiting with no number" is
  /// what makes people tap again or assume it failed. Leave null for phases
  /// with no measurable progress, such as compressing the picked photo: the
  /// bar is still drawn, just sweeping.
  final double? progress;

  /// What the wait is for — "Uploading…", "Optimising…". Null shows just the
  /// bar.
  final String? busyLabel;

  final String title;
  final String subtitle;
  final String hint;
  final IconData icon;
  final double height;

  /// Corner rounding of the surface. Kept independent of [height] so the
  /// control reads as a rounded rectangle instead of collapsing into a pill.
  final double borderRadius;
  final bool showChangeChip;
  final String changeLabel;
  final EdgeInsetsGeometry margin;

  const PremiumImageUpload({
    super.key,
    this.onTap,
    this.image,
    this.imageUrl,
    this.imageBytes,
    this.imageBase64,
    this.isBusy = false,
    this.progress,
    this.busyLabel,
    this.title = 'Upload image',
    this.subtitle = 'Tap to browse your gallery',
    this.hint = 'JPG or PNG',
    this.icon = Icons.add_a_photo_outlined,
    this.height = 192,
    this.borderRadius = 20,
    this.showChangeChip = true,
    this.changeLabel = 'Change photo',
    this.margin = EdgeInsets.zero,
  });

  bool get _hasImage {
    if (image != null) return true;
    if (imageUrl != null && imageUrl!.isNotEmpty) return true;
    if (imageBytes != null && imageBytes!.isNotEmpty) return true;
    if (imageBase64 != null && imageBase64!.isNotEmpty) return true;
    return false;
  }

  Widget _buildImage(BuildContext context) {
    final custom = image;
    if (custom != null) return custom;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      // cap the decode at ~1024px: this control is at most a screen wide, and
      // the bytes may be an untrimmed camera photo.
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 1024,
      );
    }
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(imageBase64!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 1024,
      );
    }
    return CachedProductImage(
      url: imageUrl!,
      memCacheWidth: 1024,
      // Same reasoning as the avatar: an empty box on failure would be
      // indistinguishable from a broken control. The retry budget lives in
      // `CachedProductImage`, so this icon only appears once it has given up.
      errorWidget: Center(
        child: Icon(icon, size: 34, color: context.palette.accentText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasImage = _hasImage;

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius + 8),
          boxShadow: [
            BoxShadow(
              color: p.primary.withValues(alpha: 0.18),
              blurRadius: 32,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: hasImage ? p.surfaceAlt : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: hasImage
                        ? p.primary.withValues(alpha: 0.14)
                        : p.border,
                    width: hasImage ? 1.2 : 1.4,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage) _buildImage(context),
                      if (hasImage)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x59000000)],
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: _EmptyState(title: title, icon: icon),
                        ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: hasImage
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : p.primary.withValues(alpha: 0.30),
                              width: hasImage ? 2 : 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (hasImage && showChangeChip && !isBusy)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _ChangeChip(label: changeLabel),
                        ),
                      if (isBusy)
                        Positioned.fill(
                          child: UploadProgressOverlay(
                            progress: progress,
                            label: busyLabel,
                            borderRadius: borderRadius,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The busy state: a dimming scrim, an optional label, and a determinate
/// **linear** progress bar.
///
/// A bar rather than a spinner because the wait has a known length: the bytes
/// go out with a content length, so the transport can say how far along the
/// upload is. On a free/slow connection a 5MB photo can take a minute, and a
/// spinner that never changes is indistinguishable from one that has stalled.
///
/// [progress] null means "busy but unmeasurable" (compressing the picked
/// photo, for example) and draws the same bar sweeping, so the control never
/// changes shape between the two phases.
class UploadProgressOverlay extends StatelessWidget {
  final double? progress;
  final String? label;
  final double borderRadius;

  const UploadProgressOverlay({
    super.key,
    this.progress,
    this.label,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress?.clamp(0.0, 1.0);
    final percent = value == null ? null : (value * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        // Opaque enough to read over a bright or busy photo, translucent
        // enough that the picture underneath still says which one is being
        // replaced.
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: label == null
                  ? const SizedBox.shrink()
                  : Text(
                      percent == null ? label! : '$label $percent%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
            // Pinned to the bottom edge: it reads as the surface filling up,
            // and it does not cover the photo's centre.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final IconData icon;

  const _EmptyState({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: AppTypography.bodyMediumSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              // The shared brand ramp rather than a primary-to-primaryDark pair,
              // so the empty-state badge is recognisably the same gradient as the
              // button the user will press to submit the form it sits above.
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: AppColors.brandRamp,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final String label;

  const _ChangeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 14, color: p.primary),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: TextStyle(
              color: p.primary,
              fontSize: AppTypography.labelSmallSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular sibling of [PremiumImageUpload] for avatar-style pickers, keeping
/// the same glow / solid-outline / badge language.
class PremiumAvatarUpload extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? image;
  final String? imageUrl;
  final String? imageBase64;
  final bool isBusy;

  /// How far the upload has got, 0.0–1.0. Null draws the bar sweeping — see
  /// [UploadProgressOverlay].
  final double? progress;
  final IconData icon;
  final double radius;

  const PremiumAvatarUpload({
    super.key,
    this.onTap,
    this.image,
    this.imageUrl,
    this.imageBase64,
    this.isBusy = false,
    this.progress,
    this.icon = Icons.person_outline,
    this.radius = 54,
  });

  bool get _hasImage {
    if (image != null) return true;
    if (imageUrl != null && imageUrl!.isNotEmpty) return true;
    if (imageBase64 != null && imageBase64!.isNotEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasImage = _hasImage;

    return Container(
      width: radius * 2 + 28,
      height: radius * 2 + 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.20),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: GestureDetector(
          onTap: isBusy ? null : onTap,
          child: Stack(
            children: [
              Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceAlt,
                  border: Border.all(color: p.primary.withValues(alpha: 0.16)),
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        (image ??
                            (imageBase64 != null && imageBase64!.isNotEmpty
                                ? Image.memory(
                                    base64Decode(imageBase64!),
                                    fit: BoxFit.cover,
                                    cacheWidth: 512,
                                  )
                                : CachedProductImage(
                                    url: imageUrl!,
                                    memCacheWidth: 512,
                                    // A failed load must not leave an empty
                                    // circle. Without this the widget is given
                                    // *something* to paint, so `_hasImage` stays
                                    // true and the placeholder glyph below is
                                    // never reached -- and a transparent or
                                    // zero-size error box then reads as a black
                                    // avatar. `CachedProductImage` retries first
                                    // and only gives up after three attempts.
                                    errorWidget: Icon(
                                      icon,
                                      size: radius * 0.8,
                                      color: p.accentText,
                                    ),
                                  )))
                      else
                        Center(
                          // `accentText`: this placeholder glyph sits on
                          // `surfaceAlt`, where `primary` is only 2.25:1 in dark
                          // and fails the 3:1 that SC 1.4.11 sets for a non-text
                          // graphic.
                          child: Icon(
                            icon,
                            size: radius * 0.8,
                            color: p.accentText,
                          ),
                        ),
                      if (hasImage)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      // Over the top of the avatar, not instead of it: an
                      // avatar being replaced used to show no feedback at all,
                      // because the old branch only drew a spinner when there
                      // was no image to fall back on.
                      if (isBusy)
                        Positioned.fill(
                          child: UploadProgressOverlay(
                            progress: progress,
                            borderRadius: radius,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: AppColors.brandRamp,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: p.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

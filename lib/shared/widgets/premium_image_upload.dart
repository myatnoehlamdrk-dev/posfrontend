import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';

/// Premium, mobile-first image upload surface.
///
/// Visual layers (bottom → top):
///   1. Soft ambient glow behind the surface
///   2. Rounded surface with tinted fill and subtle primary outline
///   3. Image / empty state / busy spinner
///   4. Optional gradient scrim for legibility over photos
///   5. Solid outline stays visible over any photo
///   6. Optional "change" chip anchored bottom-right
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

  /// When true the surface shows a busy indicator instead of the empty state.
  final bool isBusy;

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
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return Image.memory(
        base64Decode(imageBase64!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
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
          padding: const EdgeInsets.all(10),
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
                      else if (isBusy)
                        const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: _EmptyState(
                            title: title,
                            icon: icon,
                          ),
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
                      if (hasImage && showChangeChip)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _ChangeChip(label: changeLabel),
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

class _EmptyState extends StatelessWidget {
  final String title;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.icon,
  });

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
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.primary, p.primaryDark],
              ),
              borderRadius: BorderRadius.circular(22),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
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
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: p.primary,
              fontSize: 12,
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
  final IconData icon;
  final double radius;

  const PremiumAvatarUpload({
    super.key,
    this.onTap,
    this.image,
    this.imageUrl,
    this.imageBase64,
    this.isBusy = false,
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
        padding: const EdgeInsets.all(14),
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
                                  )
                                : Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                  )))
                      else if (isBusy)
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            icon,
                            size: radius * 0.8,
                            color: p.primary,
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
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: p.primary,
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

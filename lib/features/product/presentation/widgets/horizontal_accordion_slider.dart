import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';
import 'package:posfrontend/shared/widgets/price_text.dart';

class HorizontalAccordionSlide {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? brand;
  final double? price;
  final VoidCallback? onTap;

  const HorizontalAccordionSlide({
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.brand,
    this.price,
    this.onTap,
  });
}

class HorizontalAccordionSlider extends StatefulWidget {
  final List<HorizontalAccordionSlide> items;
  final double height;
  final int initialActiveIndex;
  final ValueChanged<int>? onActiveChanged;
  final int maxItems;

  /// Hide the "1 / 1" counter when one image is shown as a hero rather than as
  /// part of a real carousel (the product detail page).
  final bool showSlideIndicator;

  /// Paint the dark photographic scrim. Product detail shows the original,
  /// undimmed image and uses themed text panels instead.
  final bool dimImage;

  /// Override the active slide's button label, e.g. "Update" on product detail.
  final String? actionLabel;

  const HorizontalAccordionSlider({
    super.key,
    required this.items,
    this.height = 320,
    this.initialActiveIndex = 0,
    this.onActiveChanged,
    this.maxItems = 7,
    this.showSlideIndicator = true,
    this.dimImage = true,
    this.actionLabel,
  });

  @override
  State<HorizontalAccordionSlider> createState() =>
      _HorizontalAccordionSliderState();
}

class _HorizontalAccordionSliderState
    extends State<HorizontalAccordionSlider>
    with SingleTickerProviderStateMixin {
  late int _activeIndex;
  late final AnimationController _textAnimController;

  @override
  void initState() {
    super.initState();
    final count = widget.items.length.clamp(0, widget.maxItems);
    _activeIndex = widget.initialActiveIndex.clamp(0, count > 0 ? count - 1 : 0);
    _textAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimController.forward();
  }

  @override
  void dispose() {
    _textAnimController.dispose();
    super.dispose();
  }

  void _setActive(int index) {
    if (index == _activeIndex || !mounted) return;
    setState(() => _activeIndex = index);
    _textAnimController.forward(from: 0);
    widget.onActiveChanged?.call(index);
  }

  static const _accents = [
    Color(0xFFE07A5F),
    Color(0xFFF4A261),
    Color(0xFF2A9D8F),
    Color(0xFFE76F51),
    Color(0xFF8AB17D),
  ];

  Color _accentFor(int index) => _accents[index % _accents.length];

  Widget _buildSlide(HorizontalAccordionSlide item, int index, bool active, int totalItems) {
    final accent = _accentFor(index);

    final image = (item.imageUrl.isNotEmpty)
        ? CachedProductImage(
            url: item.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: active ? 900 : 300,
            errorWidget: _errorTile(accent),
          )
        : _errorTile(accent);

    final overlayFill = widget.dimImage
        ? Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: active ? 0.75 : 0.55),
                    Colors.black.withValues(alpha: active ? 0.85 : 0.65),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Without the scrim the brand reads straight off the photo, with a soft
    // shadow for contrast instead of a block covering part of the image.
    final brand = widget.dimImage
        ? ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accent, Colors.white],
            ).createShader(bounds),
            child: Text(
              item.brand ?? 'Brand',
              style: GoogleFonts.pacifico(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          )
        : Text(
            item.brand ?? 'Brand',
            style: GoogleFonts.pacifico(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
              color: context.isDark ? Colors.white : const Color(0xFF111827),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            overlayFill,
            // Top-right: branch name + slide indicator
            if (item.brand != null || widget.dimImage || widget.showSlideIndicator)
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    brand,
                    if (widget.showSlideIndicator) ...[
                      const SizedBox(height: 10),
                      // Slide indicator: 1 / 3
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              ' / $totalItems',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (active)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _activeOverlay(item, accent, !widget.dimImage),
              ),
          ],
        ),
      ),
    );
  }

  /// Stand-in for a slide with no photo.
  ///
  /// Dark mode already read well, so it keeps its original treatment. In light
  /// mode the same faint accent tint made the glyph almost invisible; there it
  /// gets a solid contrasting badge and a darkened accent icon.
  Widget _errorTile(Color accent) {
    if (context.isDark) {
      return Container(
        color: accent.withValues(alpha: 0.12),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: accent.withValues(alpha: 0.8),
            size: 44,
          ),
        ),
      );
    }

    final iconColor = Color.lerp(accent, Colors.black, 0.6)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.9)!,
            Color.lerp(accent, Colors.white, 0.78)!,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: iconColor,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _activeOverlay(
    HorizontalAccordionSlide item,
    Color accent,
    bool plain,
  ) {
    final p = context.palette;
    final subtitleColor = plain ? p.accentText : accent;
    final titleColor = plain ? p.textPrimary : Colors.white;
    final priceColor = plain ? p.primary : Colors.white;
    final onImageShadows = <Shadow>[
      Shadow(
        color: Colors.black.withValues(alpha: 0.7),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ];
    final children = <Widget>[
      if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _textAnimController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _textAnimController,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
            child: Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: AppTypography.labelSmallSize,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
                letterSpacing: 0.8,
                shadows: plain ? onImageShadows : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _textAnimController,
          curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _textAnimController,
            curve: const Interval(0.15, 0.75, curve: Curves.easeOut),
          ),
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bebasNeue(
              fontSize: AppTypography.titleLargeSize + 4,
              fontWeight: FontWeight.w900,
              color: titleColor,
              height: 1.05,
              letterSpacing: 1.2,
              shadows: onImageShadows,
            ),
          ),
        ),
      ),
      if (item.price != null) ...[
        const SizedBox(height: 12),
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _textAnimController,
            curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _textAnimController,
              curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
            ),
            child: PriceText(
              item.price!,
              style: GoogleFonts.spaceMono(
                fontSize: AppTypography.titleLargeSize + 2,
                fontWeight: FontWeight.w700,
                color: priceColor,
                shadows: onImageShadows,
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _textAnimController,
          curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _textAnimController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
          ),
          child: SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: item.onTap,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: GoogleFonts.spaceGrotesk(
                  fontSize: AppTypography.bodySmallSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              child: Text(widget.actionLabel ?? 'View Details'),
            ),
          ),
        ),
      ),
    ];

    final overlay = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    // No panel behind the copy: the photo stays fully visible, and contrast
    // comes from the text colours and their soft shadows instead.
    return overlay;
  }

  @override
  Widget build(BuildContext context) {
    final showItems = widget.items.take(widget.maxItems).toList();
    if (showItems.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                size: 48,
                color: context.palette.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'No images',
                style: TextStyle(
                  color: context.palette.textMuted,
                  fontSize: AppTypography.bodySmallSize,
                ),
              ),
            ],
          ),
        ),
      );
    }

return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Responsive maxItems: wider screens can show more slides
        int effectiveMaxItems;
        if (w >= 1200) {
          effectiveMaxItems = 7;
        } else if (w >= 900) {
          effectiveMaxItems = 5;
        } else if (w >= 600) {
          effectiveMaxItems = 4;
        } else {
          effectiveMaxItems = 3;
        }
        final displayItems = showItems.take(effectiveMaxItems).toList();
        final count = displayItems.length;
        const activeFlex = 5;
        const inactiveFlex = 1;
        final totalFlex = activeFlex + (count - 1) * inactiveFlex;
        final activeWidth = w * activeFlex / totalFlex;
        final inactiveWidth = w * inactiveFlex / totalFlex;

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: List.generate(count, (index) {
              final item = displayItems[index];
              final isActive = index == _activeIndex;
              final width = isActive ? activeWidth : inactiveWidth;
              final left = index == 0
                  ? 0.0
                  : index < _activeIndex
                      ? index * inactiveWidth
                      : index == _activeIndex
                          ? _activeIndex * inactiveWidth
                          : activeWidth + (index - 1) * inactiveWidth;
              return AnimatedPositioned(
                key: ValueKey('slide_$index'),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                left: left,
                top: 0,
                bottom: 0,
                width: width,
                child: GestureDetector(
                  onTap: () => _setActive(index),
                  child: _buildSlide(item, index, isActive, count),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

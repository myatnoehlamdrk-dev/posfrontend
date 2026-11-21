import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/media_url.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/cached_product_image.dart';

/// Square product photo that replaces the row number in the stock tables.
///
/// The stock rows are one per variant, so the same product photo repeats down
/// the list — that is the point: the photo identifies the product faster than
/// a position number, and the size/color columns distinguish the variants.
///
/// Falls back to an inventory glyph when the product has no image or the
/// download fails, so a row never collapses or shows a broken-image icon.
class ProductRowThumb extends StatelessWidget {
  final String? url;
  final double size;

  const ProductRowThumb({super.key, required this.url, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final resolved = resolveMediaUrl(url);
    final fallback = Icon(
      Icons.inventory_2_outlined,
      size: size * 0.55,
      color: p.textSecondary,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: p.chipBg,
        child: resolved == null
            ? fallback
            : CachedProductImage(
                url: resolved,
                width: size,
                height: size,
                // A 30dp avatar decodes at 4x the largest cell it can appear
                // in: enough for a high-DPI till, far less than the full
                // product photo.
                memCacheWidth: (size * 4).round(),
                errorWidget: fallback,
              ),
      ),
    );
  }
}

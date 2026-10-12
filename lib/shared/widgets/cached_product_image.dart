import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Product/category image that survives app restarts.
///
/// Tills are offline-capable: product photos live on imgbb (or the backend
/// origin) and were re-downloaded on every launch and every grid rebuild.
/// [CachedNetworkImage] keeps them on disk, so a restart — and a shop with
/// no internet — still shows the shelf.
///
/// `memCacheWidth` is pinned to roughly 2x the largest on-screen size (200dp
/// grid tiles): without it the full-resolution photo is decoded into memory
/// for a 40dp row, which is the classic source of grid-jank on cheap POS
/// hardware. Bump it if a surface renders larger than 200dp.
class CachedProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;

  const CachedProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      // The grid is re-scanned constantly while the cashier scrolls; a fade
      // on every tile re-entering the viewport is visual noise. Disk hits
      // are already instant; network first-hits keep the old shimmer-style
      // placeholder behaviour.
      fadeInDuration: const Duration(milliseconds: 120),
      memCacheWidth: memCacheWidth ?? 400,
      placeholder: placeholder == null
          ? null
          : (_, _) => SizedBox(
                width: width,
                height: height,
                child: placeholder,
              ),
      errorWidget: (_, _, _) =>
          errorWidget ?? const Icon(Icons.broken_image_outlined),
    );
  }
}

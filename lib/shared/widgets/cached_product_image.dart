import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Product/category image that survives app restarts *and* flaky networks.
///
/// Tills are offline-capable: product photos live on imgbb (or the backend
/// origin) and were re-downloaded on every launch and every grid rebuild.
/// [CachedNetworkImage] keeps them on disk, so a restart — and a shop with
/// no internet — still shows the shelf.
///
/// Two failure modes this widget is built to survive:
///
///  * A single dropped packet used to park a tile on its default/broken icon
///    forever — the widget never tried again. Now a failed download is
///    retried (with a short delay, so a dead host isn't hammered) before the
///    error icon is allowed to stay.
///
///  * On the **web** build, [CachedNetworkImage]'s byte fetch is an XHR. A
///    host that answers without an `Access-Control-Allow-Origin` header can
///    never satisfy it, so every local upload showed the broken icon even
///    though the file was right there. The browser's own `<img>` element
///    (`Image.network`) is *not* CORS-restricted for display, so the web
///    build loads through the element and lets the browser's HTTP cache do
///    what the disk cache does elsewhere.
///
/// `memCacheWidth` is pinned to roughly 2x the largest on-screen size (200dp
/// grid tiles): without it the full-resolution photo is decoded into memory
/// for a 40dp row, which is the classic source of grid-jank on cheap POS
/// hardware. Bump it if a surface renders larger than 200dp.
class CachedProductImage extends StatefulWidget {
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
  State<CachedProductImage> createState() => _CachedProductImageState();
}

class _CachedProductImageState extends State<CachedProductImage> {
  /// How many times a failed download is retried before the error icon is
  /// allowed to stay put. Three attempts over a few seconds rides out a
  /// Wi-Fi blip without turning a dead host into a hammer.
  static const int _maxAttempts = 3;

  /// Pause between retries. Long enough to not hammer a struggling host,
  /// short enough that a transient blip is invisible to the cashier.
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Which attempt the last render was. Bumped (via [setState]) to force a
  /// fresh load after a failure.
  int _attempt = 0;

  /// Guards against scheduling two timers for one failure (errorWidget
  /// builders can be invoked more than once per failed load).
  bool _retryScheduled = false;

  @override
  void didUpdateWidget(CachedProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different URL is a different image: start the retry budget over.
    if (oldWidget.url != widget.url) {
      _attempt = 0;
      _retryScheduled = false;
    }
  }

  /// True while more attempts remain — used to tell "still retrying" apart
  /// from "given up" when painting the error state.
  bool get _willRetry => _attempt + 1 < _maxAttempts;

  void _scheduleRetry() {
    if (_retryScheduled || !_willRetry) return;
    _retryScheduled = true;
    Timer(_retryDelay, () {
      if (!mounted) return;
      _retryScheduled = false;
      // A failed load can stick in the framework's image cache; drop the
      // entry so the next build genuinely re-fetches instead of replaying
      // the cached failure instantly.
      _evict();
      setState(() => _attempt++);
    });
  }

  void _evict() {
    if (kIsWeb) {
      NetworkImage(widget.url).evict();
    } else {
      CachedNetworkImageProvider(widget.url).evict();
    }
  }

  Widget _fallback() =>
      widget.errorWidget ?? const Icon(Icons.broken_image_outlined);

  @override
  Widget build(BuildContext context) {
    // The key changes per attempt: a new State tree is created, which forces
    // a fresh provider resolution even if something upstream memoised the
    // previous failure.
    final loadKey = ValueKey('${widget.url}#$_attempt');

    if (kIsWeb) {
      // See class doc: on the web build an <img> element sidesteps the CORS
      // restriction that breaks CachedNetworkImage's XHR byte fetch.
      return Image.network(
        widget.url,
        key: loadKey,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth ?? 400,
        errorBuilder: (_, _, _) {
          _scheduleRetry();
          return _fallback();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.url,
      key: loadKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // The grid is re-scanned constantly while the cashier scrolls; a fade
      // on every tile re-entering the viewport is visual noise. Disk hits
      // are already instant; network first-hits keep the old shimmer-style
      // placeholder behaviour.
      fadeInDuration: const Duration(milliseconds: 120),
      memCacheWidth: widget.memCacheWidth ?? 400,
      placeholder: widget.placeholder == null
          ? null
          : (_, _) => SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.placeholder,
              ),
      errorWidget: (_, _, _) {
        _scheduleRetry();
        return _fallback();
      },
    );
  }
}

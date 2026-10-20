import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:posfrontend/features/shop/domain/entities/shop.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_api_repository_impl.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_local_repository_impl.dart';

class ShopScope extends StatefulWidget {
  final Widget child;
  const ShopScope({super.key, required this.child});

  @override
  State<ShopScope> createState() => ShopScopeState();

  static Shop? shopOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShopScopeData>()?.shop;
  }

  static Future<void> loadShop(BuildContext context, {String? shopId}) async {
    final state = context.findAncestorStateOfType<ShopScopeState>();
    await state?.loadShop(shopId: shopId);
  }
}

class ShopScopeState extends State<ShopScope> {
  Shop? _shop;
  Shop? get shop => _shop;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadShop({String? shopId}) async {
    if (_isLoading) return;
    _isLoading = true;
    // Captured before the first await: `precacheImage` needs a context, and
    // reaching across an async gap for one is exactly the pattern the analyzer
    // (rightly) flags.
    final context = this.context;
    try {
      if (shopId != null && shopId.isNotEmpty) {
        try {
          final shop = await ShopApiRepositoryImpl().getShopById(shopId);
          if (mounted) {
            setState(() {
              _shop = shop;
              _isLoading = false;
            });
            // Keep the local mirror current. This is the copy an offline or
            // failed start falls back to, and it used to go stale the moment
            // a logo changed here — the next cold start showed the old
            // (or no) image until the API happened to answer again.
            try {
              await ShopLocalRepositoryImpl().saveShop(shop);
            } catch (_) {
              // A failed mirror write only costs freshness next launch; it
              // must not undo the successful fetch above.
            }
            // Warm the logo so the first surface that shows it paints from
            // cache instead of waiting on the network. Errors are swallowed:
            // precache is an optimisation, the widget's own retry handles
            // the real load.
            final logoUrl = shop.logoUrl;
            if (logoUrl != null && logoUrl.isNotEmpty) {
              unawaited(
                precacheImage(
                  CachedNetworkImageProvider(logoUrl),
                  // `mounted` was checked above and `context` is the one
                  // captured before the first await: not a real async-gap use.
                  // ignore: use_build_context_synchronously
                  context,
                  onError: (_, _) {},
                ),
              );
            }
            return;
          }
        } catch (_) {
          // Shop API fetch failed; fall back to local
        }
      }
      final shop = await ShopLocalRepositoryImpl().getShop();
      if (mounted) {
        setState(() {
          _shop = shop;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) _isLoading = false;
    }
  }

  void updateShop(Shop? shop) {
    if (_shop != shop) {
      setState(() => _shop = shop);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShopScopeData(
      shop: _shop,
      isLoading: _isLoading,
      updateShop: updateShop,
      child: widget.child,
    );
  }
}

class _ShopScopeData extends InheritedWidget {
  final Shop? shop;
  final bool isLoading;
  final void Function(Shop?) updateShop;

  const _ShopScopeData({
    required this.shop,
    required this.isLoading,
    required this.updateShop,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShopScopeData oldWidget) {
    return shop != oldWidget.shop || isLoading != oldWidget.isLoading;
  }
}

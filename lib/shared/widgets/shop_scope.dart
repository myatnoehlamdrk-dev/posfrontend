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
    try {
      if (shopId != null && shopId.isNotEmpty) {
        try {
          final shop = await ShopApiRepositoryImpl().getShopById(shopId);
          if (mounted) {
            setState(() {
              _shop = shop;
              _isLoading = false;
            });
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

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:posfrontend/modules/shop/model/shop.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository.dart';

class ShopLocalRepositoryImpl implements ShopLocalRepository {
  static const String _key = 'pos_shop_data';

  @override
  Future<void> saveShop(Shop shop) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(shop.toJson()));
  }

  @override
  Future<Shop?> getShop() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return Shop.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearShop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:posfrontend/features/shop/data/models/shop_api_model.dart';

class ShopLocalDataSource {
  static const String _key = 'pos_shop_data';

  Future<void> saveShop(ShopApiModel shop) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(shop.toJson()));
  }

  Future<ShopApiModel?> getShop() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return ShopApiModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearShop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

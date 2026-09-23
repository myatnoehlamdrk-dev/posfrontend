import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/cart_card_entity.dart';
import '../domain/entities/cart_item_entity.dart';

class CartStore extends ValueNotifier<List<CartCardEntity>> {
  static final CartStore instance = CartStore._();
  CartStore._() : super(const []);

  static const String _storageKey = 'cart_cards_v1';

  bool _loaded = false;

  int get totalQuantity =>
      value.fold(0, (sum, card) => sum + card.totalQuantity);

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CartCardEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      value = list;
    } catch (_) {
      // Corrupted/invalid storage is treated as an empty cart
    }
  }

  Future<CartCardEntity?> addCard(
    List<CartItemEntity> items, {
    String orderId = '',
  }) async {
    if (items.isEmpty) return null;
    final card = CartCardEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderId: orderId,
      createdAt: DateTime.now(),
      items: List<CartItemEntity>.from(items),
    );
    final updated = [...value, card];
    value = List.of(updated);
    await _persist(updated);
    return card;
  }

  Future<void> removeCard(String id) async {
    final updated = value.where((c) => c.id != id).toList();
    value = List.of(updated);
    await _persist(updated);
  }

  Future<CartCardEntity?> appendToCard(
    String id,
    List<CartItemEntity> items,
  ) async {
    if (items.isEmpty) return null;
    final index = value.indexWhere((c) => c.id == id);
    if (index < 0) return null;
    final card = value[index];
    final updatedCard = CartCardEntity(
      id: card.id,
      orderId: card.orderId,
      createdAt: card.createdAt,
      items: [...card.items, ...items],
    );
    final updated = [...value];
    updated[index] = updatedCard;
    value = List.of(updated);
    await _persist(updated);
    return updatedCard;
  }

  Future<void> mergeCards(List<CartCardEntity> extras) async {
    if (extras.isEmpty) return;
    final existing = value;
    final existingOrderIds =
        existing.map((c) => c.orderId).where((o) => o.isNotEmpty).toSet();
    final toAdd =
        extras.where((c) => !existingOrderIds.contains(c.orderId)).toList();
    if (toAdd.isEmpty) return;
    final updated = [...existing, ...toAdd];
    value = List.of(updated);
    await _persist(updated);
  }

  Future<void> clear() async {
    value = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<void> _persist(List<CartCardEntity> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(cards.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Persistence failure is non-critical; keep cart in memory
    }
  }
}
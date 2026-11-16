import 'dart:convert';

import 'package:posfrontend/features/settings/domain/entities/printer_profile.dart';
import 'package:posfrontend/shared/services/receipt_print_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device storage for printer profiles.
///
/// Local by design: the printer belongs to the counter this device sits on,
/// not to the shop's server, so a till works out which roll to lay receipts
/// out for even when the backend is unreachable. A corrupted or absent key
/// reads as "no printers" rather than an error — losing the list costs a
/// re-entry of one IP address, not a broken settings screen.
class PrinterProfileStore {
  static const String _key = 'printer_profiles_v1';

  /// Saved printers, default first, rest in creation order.
  Future<List<PrinterProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final printers = decoded
          .whereType<Map<String, dynamic>>()
          .map(PrinterProfile.fromJson)
          .where((p) => p.id.isNotEmpty && p.host.isNotEmpty)
          .toList();
      // A list can only have come from this store, but a hand-edited or
      // partially written value could hold two defaults — first one wins.
      var seenDefault = false;
      for (var i = 0; i < printers.length; i++) {
        if (!printers[i].isDefault) continue;
        if (seenDefault) printers[i] = printers[i].copyWith(isDefault: false);
        seenDefault = true;
      }
      printers.sort((a, b) {
        if (a.isDefault) return -1;
        if (b.isDefault) return 1;
        return 0;
      });
      return printers;
    } on FormatException {
      return const [];
    }
  }

  /// Inserts [profile] or replaces the profile holding the same id.
  ///
  /// When [profile] is the default, every other profile loses the flag, and
  /// its paper size is mirrored into the sale sheet's key so the receipt
  /// layout and the physical roll stay in agreement.
  Future<void> save(PrinterProfile profile) async {
    final printers = await load();
    final index = printers.indexWhere((p) => p.id == profile.id);

    var updated = [...printers];
    if (profile.isDefault) {
      updated = updated.map((p) => p.copyWith(isDefault: false)).toList();
    }
    if (index >= 0) {
      updated[index] = profile;
    } else {
      updated.add(profile);
    }

    await _write(updated);
    if (profile.isDefault) {
      await SalePrintSettings.setPaperSize(profile.paperSize);
    }
  }

  Future<void> delete(String id) async {
    final printers = await load();
    final removed = printers.where((p) => p.id == id).toList();
    if (removed.isEmpty) return;

    var remaining = printers.where((p) => p.id != id).toList();
    // Deleting the default must not leave receipts laying out for a roll
    // nobody picked: the next printer in line takes over, paper size and all.
    if (removed.first.isDefault && remaining.isNotEmpty) {
      final next = remaining.first.copyWith(isDefault: true);
      remaining = [next, ...remaining.skip(1)];
      await SalePrintSettings.setPaperSize(next.paperSize);
    }

    await _write(remaining);
  }

  /// Makes the printer with [id] the default and syncs its paper size.
  Future<void> setDefault(String id) async {
    final printers = await load();
    final target = printers.where((p) => p.id == id).toList();
    if (target.isEmpty) return;

    final updated = printers
        .map((p) => p.copyWith(isDefault: p.id == id))
        .toList();
    await _write(updated);
    await SalePrintSettings.setPaperSize(target.first.paperSize);
  }

  Future<void> _write(List<PrinterProfile> printers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(printers.map((p) => p.toJson()).toList()),
    );
  }
}

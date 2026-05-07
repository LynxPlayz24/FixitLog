import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

/// Simple local persistence service using SharedPreferences.
///
/// Stores the entire item list (including nested tasks) as a JSON string.
class StorageService {
  static const _kItemsKey = 'fixitlog_items';

  // ── Singleton ─────────────────────────────────────────────────────────
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Load all saved items from local storage.
  Future<List<Item>> loadItems() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_kItemsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persist the full item list to local storage.
  Future<void> saveItems(List<Item> items) async {
    final prefs = await _preferences;
    final jsonString = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_kItemsKey, jsonString);
  }

  /// Clear all stored data.
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_kItemsKey);
  }
}

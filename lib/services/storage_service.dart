import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
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

  /// Export data as a JSON file and open share sheet.
  /// Returns null on success, or an error message.
  Future<String?> exportData() async {
    try {
      final prefs = await _preferences;
      final jsonString = prefs.getString(_kItemsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return 'No data to export.';
      }

      final xfile = XFile.fromData(
        utf8.encode(jsonString),
        mimeType: 'application/json',
        name: 'fixitlog_backup.json',
      );

      final result = await Share.shareXFiles([xfile], text: 'FixitLog Backup');
      if (result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed) {
        return null; // success
      }
      return 'Export cancelled or failed.';
    } catch (e) {
      return 'Failed to export data: $e';
    }
  }

  /// Import data from a JSON file.
  /// Returns null on success, or an error message.
  Future<String?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        // Validate JSON
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        // Try parsing to make sure it's valid items
        decoded.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();

        final prefs = await _preferences;
        await prefs.setString(_kItemsKey, jsonString);
        return null; // success
      }
      return 'Import cancelled.';
    } catch (e) {
      return 'Failed to import data. Invalid file format.';
    }
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Persists user profiles in SharedPreferences, keyed by email.
class ProfileService {
  static const _kProfilePrefix = 'fixitlog_profile_';

  // ── Singleton ─────────────────────────────────────────────────────────
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _key(String email) => '$_kProfilePrefix${email.toLowerCase()}';

  // ── Public API ────────────────────────────────────────────────────────

  /// Load a profile for [email]. Returns a new empty profile if none exists.
  Future<UserProfile> loadProfile(String email) async {
    final prefs = await _preferences;
    final raw = prefs.getString(_key(email));
    if (raw == null || raw.isEmpty) {
      return UserProfile(email: email);
    }
    return UserProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  /// Save [profile] to local storage.
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _preferences;
    await prefs.setString(
      _key(profile.email),
      jsonEncode(profile.toJson()),
    );
  }
}

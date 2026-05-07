import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local auth service that stores registered users in SharedPreferences.
///
/// Each user is stored as: { email, username, password }
/// Passwords are stored in plain-text for this local-only demo.
class AuthService {
  static const _kUsersKey = 'fixitlog_users';

  // ── Singleton ─────────────────────────────────────────────────────────
  AuthService._();
  static final AuthService instance = AuthService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_kUsersKey);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await _preferences;
    await prefs.setString(_kUsersKey, jsonEncode(users));
  }

  // ── Session ────────────────────────────────────────────────────────────
  String? currentUserEmail;
  String? currentUsername;

  void clearSession() {
    currentUserEmail = null;
    currentUsername = null;
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Register a new user. Returns an error message or `null` on success.
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    // Check if email is already taken
    final exists = users.any(
      (u) => (u['email'] as String).toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      return 'An account with this email already exists.';
    }

    users.add({
      'username': username,
      'email': email.toLowerCase(),
      'password': password,
    });

    await _saveUsers(users);
    return null; // success
  }

  /// Attempt to log in. Returns the username on success, or an error message
  /// prefixed with `"ERROR:"`.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    final match = users.where(
      (u) => (u['email'] as String).toLowerCase() == email.toLowerCase(),
    );

    if (match.isEmpty) {
      return 'ERROR:No account found with this email. Please register first.';
    }

    final user = match.first;
    if (user['password'] != password) {
      return 'ERROR:Incorrect password.';
    }

    // Store session info
    currentUserEmail = email.toLowerCase();
    currentUsername = user['username'] as String;

    return user['username'] as String;
  }

  /// Update the current user's email. Returns error string or null on success.
  Future<String?> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    if (currentUserEmail == null) return 'Not logged in.';

    final users = await _loadUsers();
    final index = users.indexWhere(
      (u) => (u['email'] as String) == currentUserEmail,
    );
    if (index == -1) return 'User not found.';

    // Verify current password
    if (users[index]['password'] != currentPassword) {
      return 'Current password is incorrect.';
    }

    // Check new email isn't taken
    final taken = users.any(
      (u) =>
          (u['email'] as String).toLowerCase() == newEmail.toLowerCase() &&
          (u['email'] as String) != currentUserEmail,
    );
    if (taken) return 'That email is already in use.';

    users[index]['email'] = newEmail.toLowerCase();
    await _saveUsers(users);
    currentUserEmail = newEmail.toLowerCase();
    return null;
  }

  /// Update the current user's password. Returns error string or null on success.
  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentUserEmail == null) return 'Not logged in.';

    final users = await _loadUsers();
    final index = users.indexWhere(
      (u) => (u['email'] as String) == currentUserEmail,
    );
    if (index == -1) return 'User not found.';

    if (users[index]['password'] != currentPassword) {
      return 'Current password is incorrect.';
    }

    users[index]['password'] = newPassword;
    await _saveUsers(users);
    return null;
  }
}

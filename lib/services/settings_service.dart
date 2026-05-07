import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';

/// Persists user settings and notifies listeners when they change.
///
/// Listens to this via [SettingsService.instance.addListener] or
/// [ListenableBuilder] in the widget tree.
class SettingsService extends ChangeNotifier {
  static const _kThemeModeKey = 'fixitlog_theme_mode';
  static const _kNotifEnabledKey = 'fixitlog_notif_enabled';
  static const _kNotifReminderKey = 'fixitlog_notif_reminder';
  static const _kNotifSoundKey = 'fixitlog_notif_sound';

  // ── Singleton ─────────────────────────────────────────────────────────
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ── Current values (in-memory cache) ──────────────────────────────────
  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;
  bool _soundEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get reminderNotifications => _reminderNotifications;
  bool get soundEnabled => _soundEnabled;

  // ── Init ──────────────────────────────────────────────────────────────

  /// Must be called once at app startup (before runApp or right after).
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    final themeIndex = _prefs!.getInt(_kThemeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];

    _notificationsEnabled = _prefs!.getBool(_kNotifEnabledKey) ?? true;
    _reminderNotifications = _prefs!.getBool(_kNotifReminderKey) ?? true;
    _soundEnabled = _prefs!.getBool(_kNotifSoundKey) ?? true;

    _initialized = true;
  }

  // ── Setters (persist + notify) ────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_kThemeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_kNotifEnabledKey, value);
    notifyListeners();

    // Sync scheduled notifications with the new preference.
    if (value) {
      await LocalNotificationService.instance.rescheduleAll();
    } else {
      await LocalNotificationService.instance.cancelAll();
    }
  }

  Future<void> setReminderNotifications(bool value) async {
    _reminderNotifications = value;
    await _prefs?.setBool(_kNotifReminderKey, value);
    notifyListeners();

    // Sync scheduled notifications with the new preference.
    if (value) {
      await LocalNotificationService.instance.rescheduleAll();
    } else {
      await LocalNotificationService.instance.cancelAll();
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool(_kNotifSoundKey, value);
    notifyListeners();

    // Re-schedule with the correct channel (sound vs silent).
    await LocalNotificationService.instance.rescheduleAll();
  }
}

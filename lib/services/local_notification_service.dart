import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/item.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Manages scheduled local notifications for maintenance task reminders.
///
/// Respects the three toggles in [SettingsService]:
///   • notificationsEnabled – master switch
///   • reminderNotifications – maintenance-specific reminders
///   • soundEnabled – choose between sound / silent notification channel
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification channel definitions ────────────────────────────────

  static const _channelId = 'fixitlog_reminders';
  static const _channelName = 'Maintenance Reminders';
  static const _channelDesc = 'Notifications for upcoming maintenance tasks';

  static const _silentChannelId = 'fixitlog_reminders_silent';
  static const _silentChannelName = 'Maintenance Reminders (Silent)';
  static const _silentChannelDesc =
      'Silent notifications for upcoming maintenance tasks';

  // ── Initialisation ──────────────────────────────────────────────────

  /// Call once at app startup, after [SettingsService.init].
  Future<void> init() async {
    if (_initialized) return;

    // Initialise timezone database
    tz.initializeTimeZones();

    // Android setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS setup
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Request runtime permission on Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// Re-read items from storage and schedule/cancel notifications based
  /// on the current user preferences.
  Future<void> rescheduleAll() async {
    final settings = SettingsService.instance;

    // If notifications or reminders are off, just clear everything.
    if (!settings.notificationsEnabled || !settings.reminderNotifications) {
      await cancelAll();
      return;
    }

    final items = await StorageService.instance.loadItems();
    await scheduleTaskReminders(items);
  }

  /// Schedule a notification for every task whose [nextDueDate] is in the
  /// future. Any previously pending notifications are cancelled first so
  /// this is safe to call repeatedly (idempotent).
  Future<void> scheduleTaskReminders(List<Item> items) async {
    await _plugin.cancelAll();

    final settings = SettingsService.instance;
    if (!settings.notificationsEnabled || !settings.reminderNotifications) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    for (final item in items) {
      for (final task in item.tasks) {
        final dueDate = tz.TZDateTime.from(task.nextDueDate, tz.local);

        // Only schedule if the due date is in the future
        if (dueDate.isAfter(now)) {
          final id = _notificationId(task.id);
          final details = _buildNotificationDetails(
            useSilent: !settings.soundEnabled,
          );

          await _plugin.zonedSchedule(
            id: id,
            title: '🔧 ${task.name} — maintenance due',
            body: '${item.name} needs attention today.',
            scheduledDate: dueDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: null, // one-shot, not repeating
          );
        }
      }
    }
  }

  /// Cancel all pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Build platform-specific notification details, picking the sound or
  /// silent channel based on user preference.
  NotificationDetails _buildNotificationDetails({required bool useSilent}) {
    final android = AndroidNotificationDetails(
      useSilent ? _silentChannelId : _channelId,
      useSilent ? _silentChannelName : _channelName,
      channelDescription: useSilent ? _silentChannelDesc : _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: !useSilent,
      enableVibration: true,
    );

    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  /// Deterministic notification ID from a task ID string.
  int _notificationId(String taskId) => taskId.hashCode & 0x7FFFFFFF;
}

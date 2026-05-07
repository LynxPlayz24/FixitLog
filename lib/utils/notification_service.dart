import 'package:flutter/material.dart';

/// Lightweight notification helper.
///
/// Currently shows in-app SnackBars. Can be extended to support
/// platform-level push notifications via flutter_local_notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Show a success notification.
  void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green);
  }

  /// Show an error notification.
  void showError(BuildContext context, String message) {
    _show(context, message, Colors.redAccent);
  }

  /// Show an informational notification.
  void showInfo(BuildContext context, String message) {
    _show(context, message, const Color(0xFF7F5AF0));
  }

  void _show(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

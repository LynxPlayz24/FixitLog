import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/local_notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService.instance;
  final _auth = AuthService.instance;

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ─── Appearance ─────────────────────────────────────
              _sectionHeader('Appearance'),
              _buildThemeTile(colorScheme),
              const Divider(height: 32),

              // ─── Notifications ──────────────────────────────────
              _sectionHeader('Notifications'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts from the app'),
                value: _settings.notificationsEnabled,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: (v) => _settings.setNotificationsEnabled(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.alarm_outlined),
                title: const Text('Maintenance Reminders'),
                subtitle:
                    const Text('Get reminded when maintenance is due'),
                value: _settings.reminderNotifications,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: _settings.notificationsEnabled
                    ? (v) => _settings.setReminderNotifications(v)
                    : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Notification Sound'),
                subtitle: const Text('Play a sound with notifications'),
                value: _settings.soundEnabled,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: _settings.notificationsEnabled
                    ? (v) => _settings.setSoundEnabled(v)
                    : null,
              ),
              const Divider(height: 32),

              // ─── Data Management ────────────────────────────────
              _sectionHeader('Data Management'),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export Data (Backup)'),
                subtitle: const Text('Save a backup file of all your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final error = await StorageService.instance.exportData();
                  if (!context.mounted) return;
                  if (error != null) {
                    NotificationService.instance.showError(context, error);
                  } else {
                    NotificationService.instance.showSuccess(context, 'Backup exported!');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Import Data (Restore)'),
                subtitle: const Text('Restore data from a backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final error = await StorageService.instance.importData();
                  if (!context.mounted) return;
                  if (error != null) {
                    NotificationService.instance.showError(context, error);
                  } else {
                    LocalNotificationService.instance.rescheduleAll();
                    NotificationService.instance.showSuccess(context, 'Data restored successfully!');
                  }
                },
              ),
              const Divider(height: 32),

              // ─── Account ────────────────────────────────────────
              _sectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Change Email'),
                subtitle: Text(_auth.currentUserEmail ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangeEmailDialog,
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                subtitle: const Text('Update your login password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeTile(ColorScheme colorScheme) {
    return ListTile(
      leading: Icon(
        _settings.themeMode == ThemeMode.dark
            ? Icons.dark_mode
            : _settings.themeMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.brightness_auto,
      ),
      title: const Text('Theme'),
      subtitle: Text(_themeModeLabel(_settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showThemePicker,
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  // ── Theme picker dialog ─────────────────────────────────────────────

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Choose Theme'),
          children: ThemeMode.values.map((mode) {
            final selected = mode == _settings.themeMode;
            return SimpleDialogOption(
              onPressed: () {
                _settings.setThemeMode(mode);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? AppTheme.primaryPurple : null,
                  ),
                  const SizedBox(width: 12),
                  Text(_themeModeLabel(mode)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Change email dialog ─────────────────────────────────────────────

  void _showChangeEmailDialog() {
    final passwordCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordCtrl.text.trim();
                final newEmail = emailCtrl.text.trim();
                if (password.isEmpty || newEmail.isEmpty) {
                  NotificationService.instance
                      .showError(ctx, 'Please fill in both fields.');
                  return;
                }
                final error = await _auth.updateEmail(
                  currentPassword: password,
                  newEmail: newEmail,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                if (error != null) {
                  NotificationService.instance.showError(context, error);
                } else {
                  setState(() {});
                  NotificationService.instance
                      .showSuccess(context, 'Email updated!');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // ── Change password dialog ──────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final newPw = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
                  NotificationService.instance
                      .showError(ctx, 'Please fill in all fields.');
                  return;
                }
                if (newPw.length < 6) {
                  NotificationService.instance.showError(
                      ctx, 'New password must be at least 6 characters.');
                  return;
                }
                if (newPw != confirm) {
                  NotificationService.instance
                      .showError(ctx, 'New passwords do not match.');
                  return;
                }

                final error = await _auth.updatePassword(
                  currentPassword: current,
                  newPassword: newPw,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                if (error != null) {
                  NotificationService.instance.showError(context, error);
                } else {
                  NotificationService.instance
                      .showSuccess(context, 'Password updated!');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

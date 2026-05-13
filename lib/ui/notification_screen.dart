import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/notification_service.dart';
import '../logic/settings_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enabled  = settings.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('notifications'))),
      body: ListView(
        children: [
          // ── Daily reminder toggle ──────────────────────────────────────────
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title:     Text(context.t('daily_reminder')),
            subtitle:  Text(context.t('daily_reminder_desc')),
            value:     enabled,
            onChanged: (v) => _toggle(context, settings, v),
          ),
          // ── Reminder time ──────────────────────────────────────────────────
          ListTile(
            enabled: enabled,
            leading: const Icon(Icons.access_time_outlined),
            title:   Text(context.t('reminder_time')),
            trailing: Text(
              _fmt(settings.reminderHour, settings.reminderMinute),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: enabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
            ),
            onTap: enabled ? () => _pickTime(context, settings) : null,
          ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
              child: Text(
                context.t('notifications_hint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _toggle(
      BuildContext context, SettingsProvider settings, bool enable) async {
    if (enable) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted || !context.mounted) return;
      await settings.setNotificationsEnabled(true);
      if (!context.mounted) return;
      await NotificationService.instance.scheduleDailyReminder(
        hour:   settings.reminderHour,
        minute: settings.reminderMinute,
        title:  context.tr('notif_title'),
        body:   context.tr('notif_body'),
      );
    } else {
      await settings.setNotificationsEnabled(false);
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _pickTime(
      BuildContext context, SettingsProvider settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour:   settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null || !context.mounted) return;
    await settings.setReminderTime(picked.hour, picked.minute);
    if (!context.mounted) return;
    await NotificationService.instance.scheduleDailyReminder(
      hour:   picked.hour,
      minute: picked.minute,
      title:  context.tr('notif_title'),
      body:   context.tr('notif_body'),
    );
  }
}

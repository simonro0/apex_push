import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/notification_service.dart';
import '../logic/settings_provider.dart';
import '../logic/workout_provider.dart';

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
          // ── Daily reminder ─────────────────────────────────────────────────
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

          const Divider(indent: 16, endIndent: 16),

          // ── Streak protection ──────────────────────────────────────────────
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title:     Text(context.t('streak_reminder')),
            subtitle:  Text(context.t('streak_reminder_desc')),
            value:     settings.streakReminderEnabled,
            onChanged: (v) => _toggleStreakReminder(context, settings, v),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _streakBody(SettingsProvider settings) {
    final hoursLeft = 24 - settings.reminderHour;
    return AppLocalizations
        .translate('streak_notif_body', settings.locale)
        .replaceAll('{h}', '$hoursLeft');
  }

  // ── Daily reminder toggle ──────────────────────────────────────────────────

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
      // Cancel only the daily reminder; streak reminder is independent.
      await NotificationService.instance.cancelDailyReminder();
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

    // Reschedule daily reminder at the new time.
    await NotificationService.instance.scheduleDailyReminder(
      hour:   picked.hour,
      minute: picked.minute,
      title:  context.tr('notif_title'),
      body:   context.tr('notif_body'),
    );

    // If streak reminder is on, reschedule it at the new time too.
    if (!context.mounted) return;
    if (settings.streakReminderEnabled) {
      final lastWorkout =
          context.read<WorkoutProvider>().history.firstOrNull;
      if (lastWorkout != null) {
        await NotificationService.instance.scheduleStreakReminder(
          lastWorkoutDate: lastWorkout.date,
          hour:   picked.hour,
          minute: picked.minute,
          title:  AppLocalizations.translate('streak_notif_title', settings.locale),
          body:   _streakBody(settings),
        );
      }
    }
  }

  // ── Streak reminder toggle ─────────────────────────────────────────────────

  Future<void> _toggleStreakReminder(
      BuildContext context, SettingsProvider settings, bool enable) async {
    await settings.setStreakReminderEnabled(enable);
    if (!context.mounted) return;

    if (enable) {
      final lastWorkout =
          context.read<WorkoutProvider>().history.firstOrNull;
      if (lastWorkout != null && context.mounted) {
        await NotificationService.instance.scheduleStreakReminder(
          lastWorkoutDate: lastWorkout.date,
          hour:   settings.reminderHour,
          minute: settings.reminderMinute,
          title:  AppLocalizations.translate('streak_notif_title', settings.locale),
          body:   _streakBody(settings),
        );
      }
    } else {
      await NotificationService.instance.cancelStreakReminder();
    }
  }
}

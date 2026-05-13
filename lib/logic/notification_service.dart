import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _reminderId  = 0;
  static const _channelId   = 'apex_push_reminder';
  static const _channelName = 'Daily Reminder';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS:     DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedules a daily notification at [hour]:[minute] local time.
  /// Cancels any previously scheduled reminder first.
  Future<void> scheduleDailyReminder({
    required int    hour,
    required int    minute,
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(id: _reminderId);

    final now       = tz.TZDateTime.now(tz.local);
    var   scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority:   Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode:     AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}

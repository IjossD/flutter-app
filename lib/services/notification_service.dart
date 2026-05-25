import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showImmediate(int id, String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('wellbeing_channel', 'Wellbeing',
          channelDescription: 'Recordatorios suaves',
          importance: Importance.defaultImportance),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'wellbeing_channel',
      'Wellbeing',
      channelDescription: 'Recordatorios suaves',
      importance: Importance.defaultImportance,
    );

    final details = NotificationDetails(
        android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id: id);

  static tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

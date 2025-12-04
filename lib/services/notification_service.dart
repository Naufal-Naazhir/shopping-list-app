import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // Initialize the notification service
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle ketika notifikasi ditekan
      },
    );
  }

  Future<void> scheduleExpiryNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) {
      // For web, use a simpler approach
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pantry_expiry_channel',
            'Notifikasi Kadaluwarsa',
            channelDescription: 'Notifikasi untuk item yang akan kadaluwarsa',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } else {
      // For mobile, use zonedSchedule
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'pantry_expiry_channel',
              'Notifikasi Kadaluwarsa',
              channelDescription: 'Notifikasi untuk item yang akan kadaluwarsa',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
              enableVibration: true,
              playSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

import 'dart:io';
import 'dart:typed_data'; // Required for Int64List
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Aggressive vibration pattern (like a phone call)
  static final Int64List _aggressiveVibrationPattern = Int64List.fromList([
    0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000
  ]);

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Android Setup
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Setup
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Notification clicked: ${response.payload}');
      },
    );

    // Create aggressive prayer channel on Android
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'prayer_alerts',
          'Prayer Time Alerts',
          description: 'Urgent notifications for prayer times',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF14B8A6), // Teal
        ),
      );
    }

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized with aggressive prayer channel');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      // Also request exact alarm permission for scheduled notifications
      await androidImplementation?.requestExactAlarmsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // iOS Critical Alerts (requires Apple approval in production)
      );
      return granted ?? false;
    }
    return false;
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule an aggressive prayer notification (like a phone call)
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Aggressive Android notification details
    final androidDetails = AndroidNotificationDetails(
      'prayer_alerts',
      'Prayer Time Alerts',
      channelDescription: 'Urgent notifications for prayer times',
      importance: Importance.max,
      priority: Priority.max, // Maximum priority
      category: AndroidNotificationCategory.alarm, // Alarm category
      fullScreenIntent: true, // Wake up screen like a phone call
      vibrationPattern: _aggressiveVibrationPattern,
      enableVibration: true,
      playSound: true,
      ongoing: false,
      autoCancel: true,
      ticker: 'It\'s time for $prayerName',
      styleInformation: BigTextStyleInformation(
        'حَيَّ عَلَى الصَّلَاةِ\nHayya \'alas-salah - Come to prayer',
        contentTitle: '🕌 $prayerName Time',
        summaryText: 'Tap to open MEEK',
      ),
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      '🕌 It\'s $prayerName Time',
      'حَيَّ عَلَى الصَّلَاةِ - Come to prayer',
      scheduledDate,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
    
    debugPrint('📅 Scheduled $prayerName at ${time.hour}:${time.minute}');
  }

  /// Legacy method for backwards compatibility
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    // Redirect to the aggressive prayer notification
    await schedulePrayerNotification(
      id: id,
      prayerName: title.replaceAll('It\'s time for ', ''),
      time: time,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

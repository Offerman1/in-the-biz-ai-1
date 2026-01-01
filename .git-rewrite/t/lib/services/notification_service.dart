import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on the payload
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule end-of-shift notification
  Future<void> scheduleEndOfShiftReminder({
    required String shiftId,
    required DateTime shiftEndTime,
    required String jobName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_end_of_shift') ?? true;

    if (!enabled) return;

    // Schedule notification 15 minutes after shift ends
    final notificationTime = shiftEndTime.add(const Duration(minutes: 15));

    // Don't schedule if time has already passed
    if (notificationTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      shiftId.hashCode, // Use shift ID hash as notification ID
      'Log Your Earnings',
      'How did your $jobName shift go? Tap to log your tips and hours.',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminders',
          'Shift Reminders',
          channelDescription: 'Reminders to log earnings after shifts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'shift:$shiftId',
    );
  }

  /// Schedule shift start reminder
  Future<void> scheduleShiftReminder({
    required String shiftId,
    required DateTime shiftStartTime,
    required String jobName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_shift_reminders') ?? true;

    if (!enabled) return;

    // Schedule notification 1 hour before shift
    final notificationTime = shiftStartTime.subtract(const Duration(hours: 1));

    // Don't schedule if time has already passed
    if (notificationTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      shiftId.hashCode + 1, // Different ID for start reminder
      'Upcoming Shift',
      'Your $jobName shift starts in 1 hour',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_start_reminders',
          'Shift Start Reminders',
          channelDescription: 'Reminders before shifts start',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'shift:$shiftId',
    );
  }

  /// Cancel all notifications for a shift
  Future<void> cancelShiftNotifications(String shiftId) async {
    await _notifications.cancel(shiftId.hashCode);
    await _notifications.cancel(shiftId.hashCode + 1);
  }

  /// Schedule weekly summary notification
  Future<void> scheduleWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_weekly_summary') ?? true;

    if (!enabled) return;

    // Schedule for every Monday at 9 AM
    final now = DateTime.now();
    var nextMonday = DateTime(now.year, now.month, now.day);

    // Find next Monday
    while (nextMonday.weekday != DateTime.monday) {
      nextMonday = nextMonday.add(const Duration(days: 1));
    }

    // Set to 9 AM
    nextMonday = DateTime(
      nextMonday.year,
      nextMonday.month,
      nextMonday.day,
      9,
      0,
    );

    await _notifications.zonedSchedule(
      'weekly_summary'.hashCode,
      'Weekly Summary',
      'Check out your earnings from last week!',
      tz.TZDateTime.from(nextMonday, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summaries',
          'Weekly Summaries',
          channelDescription: 'Weekly earnings summaries',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (_initialized) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

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

    // Schedule for every Monday at 12 PM (noon) in device's local time
    final now = DateTime.now();
    var nextMonday = DateTime(now.year, now.month, now.day);

    // Find next Monday
    while (nextMonday.weekday != DateTime.monday) {
      nextMonday = nextMonday.add(const Duration(days: 1));
    }

    // Set to 12 PM (noon) - uses device's local time automatically
    nextMonday = DateTime(
      nextMonday.year,
      nextMonday.month,
      nextMonday.day,
      12,
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

  /// Schedule monthly summary notification
  Future<void> scheduleMonthlySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_monthly_summary') ?? true;

    if (!enabled) return;

    // Schedule for the 1st of next month at 1 PM in device's local time
    final now = DateTime.now();
    var firstOfNextMonth = DateTime(now.year, now.month + 1, 1, 13, 0);

    // If we're already past this month's notification, schedule for next month
    if (firstOfNextMonth.isBefore(now)) {
      firstOfNextMonth = DateTime(now.year, now.month + 2, 1, 13, 0);
    }

    await _notifications.zonedSchedule(
      'monthly_summary'.hashCode,
      '📊 Monthly Summary',
      'Check out your earnings from last month!',
      tz.TZDateTime.from(firstOfNextMonth, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_summaries',
          'Monthly Summaries',
          channelDescription: 'Monthly earnings summaries',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Request notification permissions (iOS & Android)
  Future<bool> requestPermissions() async {
    if (!_initialized) return false;

    // iOS permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android permissions (Android 13+)
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iosResult ?? androidResult ?? false;
  }

  /// Send schedule change alert
  Future<void> sendScheduleChangeAlert({
    required String message,
    String? jobName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_schedule_changes') ?? true;

    if (!enabled) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'Schedule Updated',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_changes',
          'Schedule Changes',
          channelDescription: 'Alerts when shifts are modified or synced',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedule quarterly tax reminders (Jan 15, Apr 15, Jun 15, Sep 15)
  Future<void> scheduleQuarterlyTaxReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_tax_reminders') ?? true;

    if (!enabled) return;

    final now = DateTime.now();
    final taxDates = [
      DateTime(now.year, 1, 15, 10, 0), // Q4 previous year
      DateTime(now.year, 4, 15, 10, 0), // Q1
      DateTime(now.year, 6, 15, 10, 0), // Q2
      DateTime(now.year, 9, 15, 10, 0), // Q3
    ];

    for (final taxDate in taxDates) {
      if (taxDate.isAfter(now)) {
        // Schedule 2 weeks before
        final reminderDate = taxDate.subtract(const Duration(days: 14));

        if (reminderDate.isAfter(now)) {
          await _notifications.zonedSchedule(
            taxDate.month * 1000,
            '📋 Tax Reminder',
            'Quarterly taxes due ${taxDate.month}/${taxDate.day}. Review your earnings in Stats.',
            tz.TZDateTime.from(reminderDate, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'tax_reminders',
                'Tax Reminders',
                channelDescription: 'Quarterly tax deadline reminders',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/launcher_icon',
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  /// Check for inactivity and send reminder if needed
  Future<void> checkInactivityReminder(DateTime? lastShiftDate) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_inactivity') ?? true;

    if (!enabled || lastShiftDate == null) return;

    final daysSinceLastShift = DateTime.now().difference(lastShiftDate).inDays;

    if (daysSinceLastShift >= 5) {
      await _notifications.show(
        'inactivity_reminder'.hashCode,
        '📅 Still Working?',
        "You haven't logged a shift in $daysSinceLastShift days. Tap to add one!",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'inactivity_reminders',
            'Inactivity Reminders',
            channelDescription: 'Reminds you to log shifts',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'add_shift',
      );
    }
  }

  /// Send milestone celebration
  Future<void> sendMilestoneCelebration({
    required double totalEarnings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_milestones') ?? true;

    if (!enabled) return;

    // Check if this milestone was already celebrated
    final lastMilestone = prefs.getDouble('last_milestone') ?? 0;

    // Define milestones
    final milestones = [
      100,
      500,
      1000,
      2500,
      5000,
      10000,
      25000,
      50000,
      100000
    ];

    for (final milestone in milestones) {
      if (totalEarnings >= milestone && lastMilestone < milestone) {
        await _notifications.show(
          milestone.toInt(),
          '🎉 Milestone Reached!',
          'Congratulations! You\'ve earned \$${milestone.toStringAsFixed(0)} total!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'milestone_celebrations',
              'Milestone Celebrations',
              channelDescription: 'Celebrate earning milestones',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              styleInformation: BigTextStyleInformation(''),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: 'stats',
        );

        // Save this milestone so we don't celebrate it again
        await prefs.setDouble('last_milestone', milestone.toDouble());
        break; // Only celebrate one milestone at a time
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

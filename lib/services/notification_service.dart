import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/item.dart';

enum UnreviewedReminderFrequency {
  maxOncePerDay('max_once_per_day', 'Max once per day'),
  maxOncePerWeek('max_once_per_week', 'Max once per week'),
  maxOncePerMonth('max_once_per_month', 'Max once per month');

  final String code;
  final String label;
  const UnreviewedReminderFrequency(this.code, this.label);

  static UnreviewedReminderFrequency fromCode(String? code) {
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () => UnreviewedReminderFrequency.maxOncePerWeek,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const int monthlyResetNotificationId = 1001;
  static const int unreviewedItemsNotificationId = 1002;

  static const String channelId = 'brazier_notifications_channel';
  static const String channelName = 'Brazier Reminders';
  static const String channelDescription =
      'Notifications for monthly review resets and unreviewed item reminders';

  /// Initializes local notifications and timezone database.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Error initializing timezones: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Requests permissions for notifications on Android (13+) and iOS.
  Future<bool> requestPermissions() async {
    await init();
    bool granted = false;

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? androidGranted =
            await androidImplementation.requestNotificationsPermission();
        granted = androidGranted ?? false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final bool? iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted || (iosGranted ?? false);
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }

    return granted;
  }

  /// Updates scheduled notifications based on current user preferences and item list.
  Future<void> updateNotifications({
    required bool notifyMonthlyReset,
    required bool notifyUnreviewedItems,
    required UnreviewedReminderFrequency frequency,
    List<Item>? items,
  }) async {
    await init();

    if (notifyMonthlyReset) {
      await _scheduleMonthlyResetNotification();
    } else {
      await _cancelNotification(monthlyResetNotificationId);
    }

    if (notifyUnreviewedItems) {
      await _scheduleUnreviewedItemsNotification(frequency, items: items);
    } else {
      await _cancelNotification(unreviewedItemsNotificationId);
    }
  }

  /// Schedules repeating notification when monthly review resets (1st day of month at 09:00 AM).
  Future<void> _scheduleMonthlyResetNotification() async {
    try {
      final scheduledDate = _nextMonthlyDate(dayOfMonth: 1, hour: 9, minute: 0);

      await _notificationsPlugin.zonedSchedule(
        monthlyResetNotificationId,
        'Monthly Review Reset 🗓️',
        'A new month has started! Check your items and update their monthly usage.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling monthly reset notification: $e');
    }
  }

  /// Schedules repeating reminder notification for unreviewed items.
  Future<void> _scheduleUnreviewedItemsNotification(
    UnreviewedReminderFrequency frequency, {
    List<Item>? items,
  }) async {
    try {
      // If items list is provided and there are no unreviewed items, cancel current active notification
      if (items != null) {
        final pendingCount =
            items.where((i) => i.currentMonthlyStatus == MonthlyReviewStatus.pending).length;
        if (pendingCount == 0) {
          await _cancelNotification(unreviewedItemsNotificationId);
          return;
        }
      }

      tz.TZDateTime scheduledDate;
      DateTimeComponents matchComponents;

      switch (frequency) {
        case UnreviewedReminderFrequency.maxOncePerDay:
          scheduledDate = _nextDailyDate(hour: 10, minute: 0);
          matchComponents = DateTimeComponents.time;
          break;
        case UnreviewedReminderFrequency.maxOncePerWeek:
          // Weekly on Monday at 10:00 AM
          scheduledDate = _nextWeeklyDate(dayOfWeek: DateTime.monday, hour: 10, minute: 0);
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
          break;
        case UnreviewedReminderFrequency.maxOncePerMonth:
          // Monthly on the 15th at 10:00 AM
          scheduledDate = _nextMonthlyDate(dayOfMonth: 15, hour: 10, minute: 0);
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
          break;
      }

      await _notificationsPlugin.zonedSchedule(
        unreviewedItemsNotificationId,
        'Unreviewed Items Reminder 📋',
        'You have unreviewed items waiting for your monthly check-in!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e) {
      debugPrint('Error scheduling unreviewed items notification: $e');
    }
  }

  Future<void> _cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  tz.Location get _location {
    try {
      return tz.local;
    } catch (_) {
      try {
        return tz.getLocation('UTC');
      } catch (_) {
        return tz.UTC;
      }
    }
  }

  /// Helper to calculate the next daily trigger time.
  tz.TZDateTime _nextDailyDate({required int hour, required int minute}) {
    final location = _location;
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Helper to calculate the next weekly trigger time.
  tz.TZDateTime _nextWeeklyDate(
      {required int dayOfWeek, required int hour, required int minute}) {
    tz.TZDateTime scheduledDate = _nextDailyDate(hour: hour, minute: minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Helper to calculate the next monthly trigger time.
  tz.TZDateTime _nextMonthlyDate(
      {required int dayOfMonth, required int hour, required int minute}) {
    final location = _location;
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(location, now.year, now.month, dayOfMonth, hour, minute);
    if (scheduledDate.isBefore(now)) {
      var nextMonth = now.month + 1;
      var nextYear = now.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      scheduledDate = tz.TZDateTime(location, nextYear, nextMonth, dayOfMonth, hour, minute);
    }
    return scheduledDate;
  }
}

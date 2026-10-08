import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service to handle adaptive daily practice reminders.
///
/// Features:
/// 1. Learns the player's favorite game play hours dynamically over time.
/// 2. Calculates the optimal reminder hour based on weighted play history.
/// 3. Schedules daily local notifications via [FlutterLocalNotificationsPlugin].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const int _dailyNotificationId = 888;
  static const String _playHistoryKey = 'player_game_hour_history';
  static const String _defaultReminderHourKey = 'daily_reminder_hour';

  /// Initialize time zones and local notification plugin.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (e) {
        debugPrint('NotificationService: fallback to local/UTC: $e');
      }

      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: initialization error: $e');
    }
  }

  /// Check whether notification permissions are currently granted.
  Future<bool> arePermissionsGranted() async {
    if (!_initialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final androidImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.areNotificationsEnabled() ?? false;
        return granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final settings = await darwinImpl?.checkPermissions();
        return settings?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService: arePermissionsGranted error: $e');
    }
    return false;
  }

  /// Request permissions for notification on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final androidImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwinImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      debugPrint('NotificationService: requestPermissions error: $e');
    }
    return false;
  }

  /// Opens the device's system notification settings screen for this app.
  Future<bool> openNotificationSettings() async {
    if (!_initialized) await initialize();

    try {
      if (Platform.isAndroid) {
        final androidImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.openAppNotificationSettings() ?? false;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinImpl =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await darwinImpl?.openAppNotificationSettings() ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService: openNotificationSettings error: $e');
    }
    return false;
  }

  /// Track when a game was started by recording the current hour.
  ///
  /// Stores recent game hours in SharedPreferences to adapt the notification
  /// timing to when the user actually plays chess most frequently.
  Future<void> recordGamePlayTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final currentHour = now.hour;

      final history = prefs.getStringList(_playHistoryKey) ?? [];
      // Keep recent 30 game timestamps/hours
      history.add(currentHour.toString());
      if (history.length > 30) {
        history.removeRange(0, history.length - 30);
      }
      await prefs.setStringList(_playHistoryKey, history);

      // Check if notifications are enabled before re-scheduling
      final enabled = prefs.getBool('dailyPracticeNotification') ?? true;
      if (enabled) {
        await scheduleAdaptiveDailyReminder();
      }
    } catch (e) {
      debugPrint('NotificationService: recordGamePlayTime error: $e');
    }
  }

  /// Calculates the best daily practice hour based on recorded gameplay timings.
  /// If insufficient data exists, defaults to 20:00 (8:00 PM).
  Future<int> getRecommendedReminderHour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_playHistoryKey) ?? [];

      if (history.length >= 3) {
        final counts = <int, int>{};
        for (final item in history) {
          final h = int.tryParse(item);
          if (h != null) {
            counts[h] = (counts[h] ?? 0) + 1;
          }
        }

        if (counts.isNotEmpty) {
          // Sort by frequency descending
          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return sorted.first.key;
        }
      }

      return prefs.getInt(_defaultReminderHourKey) ?? 20; // 8:00 PM default
    } catch (e) {
      return 20;
    }
  }

  /// Schedules the recurring daily chess practice notification.
  Future<void> scheduleAdaptiveDailyReminder(
      {int? customHour, int? customMinute}) async {
    if (!_initialized) await initialize();

    try {
      final hour = customHour ?? await getRecommendedReminderHour();
      final minute = customMinute ?? 0;

      await _notificationsPlugin.cancel(id: _dailyNotificationId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'daily_practice_channel',
        'Daily Chess Practice',
        channelDescription:
            'Reminds you to train and play chess daily at your optimal time.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final messages = [
        ('Daily Chess Training', 'Time for your daily chess practice!'),
        (
          'Keep Your Mind Sharp',
          'Your chessboard awaits! Jump in for a quick tactical match.'
        ),
        (
          'Daily Chess Match',
          'Sharpen your tactics today. Challenge the engine and level up!'
        ),
      ];
      final selectedMessage = messages[hour % messages.length];

      await _notificationsPlugin.zonedSchedule(
        id: _dailyNotificationId,
        title: selectedMessage.$1,
        body: selectedMessage.$2,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
          'NotificationService: Scheduled daily reminder for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint(
          'NotificationService: scheduleAdaptiveDailyReminder error: $e');
    }
  }

  /// Cancel all scheduled daily reminders.
  Future<void> cancelDailyReminder() async {
    if (!_initialized) await initialize();
    try {
      await _notificationsPlugin.cancel(id: _dailyNotificationId);
      debugPrint('NotificationService: Cancelled daily reminder');
    } catch (e) {
      debugPrint('NotificationService: cancelDailyReminder error: $e');
    }
  }
}

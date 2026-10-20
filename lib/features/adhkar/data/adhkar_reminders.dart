import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// The two daily nudges: «أذكار الصباح» and «أذكار المساء».
///
/// Kept apart from the prayer scheduler because the two have different lives:
/// the prayer schedule is rebuilt every day and calls `cancelAll()`, so these
/// are re-armed after every rebuild by [rearm]. Repeating notifications
/// (`matchDateTimeComponents.time`) survive a reboot on their own, but not a
/// blanket cancel.
class AdhkarReminders {
  AdhkarReminders({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int morningId = 7101;
  static const int eveningId = 7102;
  static const String channelId = 'adhkar_reminders_v1';

  static const String _keyEnabled = 'adhkar_reminders_enabled';
  static const String _keyMorning = 'adhkar_morning_minutes';
  static const String _keyEvening = 'adhkar_evening_minutes';

  /// 06:00 and 18:00 — the two ends the chapter is named after.
  static const int defaultMorningMinutes = 6 * 60;
  static const int defaultEveningMinutes = 18 * 60;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> _ensure() async {
    if (_ready) return;
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'أذكار الصباح والمساء',
          description: 'تنبيه يومي بأذكار الصباح والمساء',
          importance: Importance.high,
        ),
      );
    }
    _ready = true;
  }

  Future<bool> enabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<int> morningMinutes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMorning) ?? defaultMorningMinutes;
  }

  Future<int> eveningMinutes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyEvening) ?? defaultEveningMinutes;
  }

  /// Stores the two times and the switch, then (re)arms the schedule.
  Future<void> save({
    required bool enabled,
    required int morning,
    required int evening,
    required String morningTitle,
    required String morningBody,
    required String eveningTitle,
    required String eveningBody,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyMorning, morning);
    await prefs.setInt(_keyEvening, evening);
    if (enabled) {
      await _schedule(
        morning: morning,
        evening: evening,
        morningTitle: morningTitle,
        morningBody: morningBody,
        eveningTitle: eveningTitle,
        eveningBody: eveningBody,
      );
    } else {
      await cancel();
    }
  }

  /// The same two nudges, with the wording the notifications always use — for
  /// callers that have no `BuildContext` (the prayer scheduler re-arming them
  /// after its monthly rebuild).
  Future<void> rearmDefaults() => rearm(
        morningTitle: 'أذكار الصباح',
        morningBody: 'حان وقت أذكار الصباح — أربعة وعشرون ذكرًا.',
        eveningTitle: 'أذكار المساء',
        eveningBody: 'حان وقت أذكار المساء — أربعة وعشرون ذكرًا.',
      );

  /// Called after the prayer scheduler's `cancelAll()` so the nudges are not
  /// silently lost every time the month is replanned.
  Future<void> rearm({
    required String morningTitle,
    required String morningBody,
    required String eveningTitle,
    required String eveningBody,
  }) async {
    if (!await enabled()) return;
    await _schedule(
      morning: await morningMinutes(),
      evening: await eveningMinutes(),
      morningTitle: morningTitle,
      morningBody: morningBody,
      eveningTitle: eveningTitle,
      eveningBody: eveningBody,
    );
  }

  Future<void> cancel() async {
    await _ensure();
    await _plugin.cancel(morningId);
    await _plugin.cancel(eveningId);
  }

  Future<void> _schedule({
    required int morning,
    required int evening,
    required String morningTitle,
    required String morningBody,
    required String eveningTitle,
    required String eveningBody,
  }) async {
    await _ensure();
    await _plugin.cancel(morningId);
    await _plugin.cancel(eveningId);
    await _one(morningId, morning, morningTitle, morningBody, 'adhkar:morning');
    await _one(eveningId, evening, eveningTitle, eveningBody, 'adhkar:evening');
  }

  Future<void> _one(
    int id,
    int minutes,
    String title,
    String body,
    String payload,
  ) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'أذكار الصباح والمساء',
          channelDescription: 'تنبيه يومي بأذكار الصباح والمساء',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
}

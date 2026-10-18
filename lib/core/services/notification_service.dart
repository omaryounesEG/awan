import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';

/// Everything that talks to `flutter_local_notifications`.
///
/// **Zero tracking, zero network.** This class only ever hands a finished list
/// of instants to the operating system's own scheduler; it opens no socket, reads
/// no analytics, and starts no background service. Nothing here runs at prayer
/// time — the OS wakes, shows the notification, and goes back to sleep.
///
/// Design notes:
/// * **Timezone-aware scheduling** — `zonedSchedule` needs a real IANA zone, so
///   the zone id is read from the platform channel (Android
///   `TimeZone.getDefault().id`) and only then handed to `timezone`. A UTC
///   default would silently shift every adhan by the device's offset.
/// * **Exact alarms** — `AndroidScheduleMode.exactAllowWhileIdle` is requested
///   (a delayed adhan is a wrong adhan) and the user is sent to the system screen
///   that grants it if the OEM blocks it.
/// * **Battery** — the adhan channel is `Importance.max` / `Priority.max` with
///   the *alarm* audio usage, so it sounds like an alarm rather than a message,
///   even when the app is closed.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const MethodChannel _platform = MethodChannel('awan/location');

  /// The prayer card: posted and dismissed natively (see `MainActivity`).
  static const MethodChannel _cardChannel = MethodChannel('awan/clock');

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  String? _lastError;

  /// Non-null when the last platform call failed — surfaced in settings so a
  /// silent failure ("no adhan today") can never go unnoticed.
  String? get lastError => _lastError;

  Future<void> init({void Function(String payload)? onTap}) async {
    if (_initialized) return;
    try {
      await _initTimeZone();

      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final String? payload = response.payload;
          if (payload != null) onTap?.call(payload);
        },
      );
      _initialized = true;
    } catch (error) {
      _lastError = '$error';
      if (kDebugMode) debugPrint('NotificationService.init failed: $error');
    }
  }

  /// `zonedSchedule` is meaningless without a real local zone.
  Future<void> _initTimeZone() async {
    tz_data.initializeTimeZones();
    String? id;
    if (Platform.isAndroid) {
      try {
        id = await _platform.invokeMethod<String>('timeZoneId');
      } on PlatformException {
        id = null;
      } on MissingPluginException {
        id = null;
      }
    }
    id ??= DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(id));
    } catch (_) {
      // Unknown abbreviation: keep UTC rather than shifting every alarm by the
      // device offset — the prayer times themselves are computed locally and
      // remain correct.
      _lastError = 'timezone_unknown:$id';
    }
  }

  /// Android 13+ (`POST_NOTIFICATIONS`) and iOS both require an explicit ask.
  /// Exact-alarm access is requested too: without it the adhan still fires, but
  /// the system may delay it.
  Future<bool> requestPermissions() async {
    await init();
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool granted =
          await android?.requestNotificationsPermission() ?? false;
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {
        // Some OEM builds do not implement the intent; the alarm still fires
        // inexactly instead of failing the whole schedule.
      }
      return granted;
    }
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Creates/updates the three channels. On Android 8+ the channel — not the
  /// per-notification details — owns the importance, so this must run before
  /// anything is scheduled.
  Future<void> ensureChannels({
    required String adhanName,
    required String adhanDescription,
    required String reminderName,
    required String fridayName,
    String lockScreenName = 'مواقيت الصلاة',
    AdhanSound adhanSound = AdhanSound.system,
  }) async {
    await init();
    if (!Platform.isAndroid) return;
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kAdhanChannelId,
        adhanName,
        description: adhanDescription,
        importance: Importance.max,
        playSound: adhanSound.audible,
        // The phone's own **alarm** tone, not its notification blip. A channel's
        // sound is frozen at creation and later edits are ignored, so the adhan
        // channel is versioned (`…v2`): on a device where an older build created
        // it silent, the same id would stay silent forever and «مفيش تنبيه صوتي»
        // would look like a code bug that no edit can fix.
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    // Two reminder channels, not one with a mutable flag: Android bakes a
    // channel's sound in at creation and ignores later edits, so the only honest
    // way to let the reader switch the chime on and off is two channels — the
    // silent one and the one with the sound — and pick per notification.
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kReminderChannelId,
        reminderName,
        description: adhanDescription,
        importance: Importance.high,
        playSound: false,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kReminderSoundChannelId,
        reminderName,
        description: adhanDescription,
        importance: Importance.high,
        playSound: true,
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        enableVibration: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    // The all-day lock-screen card. Silent by design: it lives on the lock
    // screen from Fajr to Isha and must never make a sound of its own — the
    // adhan, twenty minutes later or at the hour, is what rings.
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kLockScreenChannelId,
        lockScreenName,
        description: adhanDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );
    // One channel per alert mode. A channel's sound and vibration are baked in at
    // creation and later edits are ignored, so «إشعار» / «اهتزاز» / «اهتزاز ونغمة»
    // cannot be a flag on a single adhan channel — they are three channels, and
    // each notification picks the one it was planned with.
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kAdhanVibrateChannelId,
        adhanName,
        description: adhanDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kAdhanQuietChannelId,
        adhanName,
        description: adhanDescription,
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        kFridayChannelId,
        fridayName,
        description: adhanDescription,
        importance: Importance.max,
        playSound: adhanSound.audible,
      ),
    );
    // One channel per bundled clip, for the adhan and for the reminder before it.
    // A channel's sound cannot be changed after it exists, so the clip *is* the
    // channel: choosing «أذان الصلاة» posts on `awan.adhan.s-adhan`, and choosing
    // it back later is the same channel with the same sound. The clips live in
    // `android/app/src/main/res/raw`, because the sound of a notification is
    // played by the system, which cannot read a Flutter asset.
    for (final AdhanSound sound in AdhanSound.bundled) {
      final String? raw = sound.rawResource;
      if (raw == null) continue;
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          sound.adhanChannelId(),
          adhanName,
          description: adhanDescription,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(raw),
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          sound.reminderChannelId(),
          reminderName,
          description: adhanDescription,
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(raw),
          enableVibration: false,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }
  }

  /// Replaces the whole pending set in one shot and returns how many were armed.
  Future<int> replaceSchedule(
    List<ScheduledAdhan> items, {
    bool playSound = true,
    bool vibrate = true,
    AdhanSound adhanSound = AdhanSound.system,
    AdhanSound preAdhanSound = AdhanSound.silent,
    String? channelName,
  }) async {
    await init();
    await _plugin.cancelAll();
    int armed = 0;
    final DateTime now = DateTime.now();

    // A month of prayers is more than iOS will hold: it keeps at most 64
    // pending notifications per app and silently drops the rest, which would
    // arm the first days and lose the tail with no error anywhere. So iOS gets
    // the nearest 60 and the app re-plans on every open. Android has no such
    // cap and keeps the whole month.
    final List<ScheduledAdhan> planned = items
        .where((ScheduledAdhan item) => item.at.isAfter(now))
        .toList()
      ..sort((ScheduledAdhan a, ScheduledAdhan b) => a.at.compareTo(b.at));
    final List<ScheduledAdhan> horizon =
        Platform.isIOS ? planned.take(60).toList() : planned;

    for (final ScheduledAdhan item in horizon) {
      // A reminder is audible only when the reader asked for it *and* this item
      // was planned with sound; the adhan keeps its own choice.
      final bool reminderAudible = item.playsSound && preAdhanSound.audible;
      // The chosen clip *is* the channel id: a channel's sound is frozen when it
      // is created, so picking a different clip must mean a different channel.
      final String channel = item.isReminder
          ? preAdhanSound.reminderChannelId()
          : switch (item.alertMode) {
              AdhanAlertMode.tone => adhanSound.adhanChannelId(),
              AdhanAlertMode.vibrate => AdhanSound.vibrateChannelId,
              AdhanAlertMode.quiet => AdhanSound.quietChannelId,
            };
      final bool sounds = item.isReminder
          ? reminderAudible
          : (adhanSound.audible && item.alertMode == AdhanAlertMode.tone);
      final bool buzzes = item.alertMode != AdhanAlertMode.quiet;
      try {
        await _plugin.zonedSchedule(
          item.id,
          item.title,
          item.body,
          tz.TZDateTime.from(item.at, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel,
              channelName ?? 'Adhan',
              channelDescription: 'Prayer time notifications',
              importance: item.isReminder
                  ? Importance.high
                  : (item.alertMode == AdhanAlertMode.quiet
                      ? Importance.defaultImportance
                      : Importance.max),
              priority: item.isReminder
                  ? Priority.high
                  : (item.alertMode == AdhanAlertMode.quiet
                      ? Priority.defaultPriority
                      : Priority.max),
              category: AndroidNotificationCategory.alarm,
              playSound: sounds,
              // Tapping it goes away by itself: a heads-up that lingers is a
              // heads-up that gets swiped instead of read.
              autoCancel: true,
              ongoing: false,
              enableVibration: buzzes && vibrate,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              fullScreenIntent: false,
              // The hourglass keeps ticking where the phone is actually looked at:
              // a countdown to the adhan, drawn by the system on the lock screen,
              // which keeps running after the screen goes off because the OS owns
              // it — no wake-up, no timer of ours, nothing to drain.
              when: item.countdownTo?.millisecondsSinceEpoch,
              // A prayer alert that is still sitting on the lock screen a
              // quarter of an hour later has stopped being a reminder and become
              // litter. `setTimeoutAfter` is enforced by the notification
              // service itself, so it clears even if the app never runs again —
              // the same trick the architecture note asks for the iqama
              // countdown, applied to the alert we actually schedule.
              timeoutAfter: item.countdownTo == null
                  ? null
                  : const Duration(minutes: 15).inMilliseconds,
              usesChronometer: item.countdownTo != null,
              chronometerCountDown: item.countdownTo != null,
              visibility: item.isReminder
                  ? NotificationVisibility.public
                  : NotificationVisibility.private,
              styleInformation:
                  BigTextStyleInformation(item.body, htmlFormatBigText: false),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: sounds,
              // iOS cannot point at an Android `res/raw` file; it plays a file
              // bundled with the app. Null keeps the system tone.
              sound: sounds
                  ? (item.isReminder ? preAdhanSound : adhanSound)
                      .darwinSoundName
                  : null,
              interruptionLevel: item.isReminder
                  ? InterruptionLevel.active
                  : InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // Required on 17.x (iOS < 15 wall-clock semantics); harmless on newer
          // releases because it is interpreted as the absolute instant, which is
          // exactly what a prayer time is.
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.payload,
        );
        armed++;
      } catch (error) {
        _lastError = '$error';
        if (kDebugMode) {
          debugPrint('zonedSchedule failed for id ${item.id}: $error');
        }
      }
    }
    return armed;
  }

  Future<void> cancelAdhan() async {
    await init();
    final List<PendingNotificationRequest> pending = await _pendingOrEmpty();
    for (final PendingNotificationRequest request in pending) {
      // Silence windows belong to the audio manager, not to the adhan set.
      if (NotificationIds.isAdhanId(request.id)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  /// Puts the *next* prayer on the lock screen as one silent, ongoing card with
  /// the system's own ticking chronometer — clock, hourglass and the time left,
  /// all day, with nothing of ours awake.
  ///
  /// The card is a single fixed id, so each call replaces the previous one
  /// instead of stacking. [target] is the adhan instant the system counts down
  /// to; once it arrives the chronometer sits at zero until the next refresh.
  /// [enabled] false removes the card outright.
  Future<bool> showNextPrayerCard({
    required bool enabled,
    required String title,
    required String body,
    required DateTime? target,
    DateTime? since,
    bool countUp = false,
  }) async {
    await init();
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (!enabled || target == null) {
      await cancelNextPrayerCard();
      return false;
    }
    // Android: posted natively, because the card must be *dismissed* by a tap
    // rather than opening the app, and the system chronometer has to run in both
    // directions — down to the adhan, up from it in the twenty minutes after.
    if (Platform.isAndroid) {
      try {
        await _cardChannel.invokeMethod<void>('postCard', <String, Object?>{
          'title': title,
          'body': body,
          'when': (since ?? target).millisecondsSinceEpoch,
          'countUp': countUp,
        });
        return true;
      } catch (error) {
        _lastError = '$error';
        if (kDebugMode) debugPrint('postCard failed: $error');
        return false;
      }
    }
    try {
      await _plugin.show(
        NotificationIds.lockScreenCard,
        title,
        body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
          ),
        ),
        payload: 'lockscreen:next',
      );
      return true;
    } catch (error) {
      _lastError = '$error';
      if (kDebugMode) debugPrint('showNextPrayerCard failed: $error');
      return false;
    }
  }

  Future<void> cancelNextPrayerCard() async {
    await init();
    try {
      if (Platform.isAndroid) {
        await _cardChannel.invokeMethod<void>('cancelCard');
      } else {
        await _plugin.cancel(NotificationIds.lockScreenCard);
      }
    } catch (error) {
      _lastError = '$error';
    }
  }

  /// How many adhan notifications the OS currently holds — the settings screen
  /// shows it, so "no adhan today" can never be a silent failure.
  Future<int> pendingCount() async {
    await init();
    final List<PendingNotificationRequest> pending = await _pendingOrEmpty();
    return pending
        .where((PendingNotificationRequest r) => NotificationIds.isAdhanId(r.id))
        .length;
  }

  /// The plugin's cache load can fail on the platform side (it is a known
  /// release-build fragility in flutter_local_notifications + Gson). Reporting
  /// adhan state is not worth crashing a settings screen over, so a failure
  /// here reads as "nothing pending" and is recorded in [_lastError].
  Future<List<PendingNotificationRequest>> _pendingOrEmpty() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (error) {
      _lastError = '$error';
      if (kDebugMode) {
        debugPrint('pendingNotificationRequests failed: $error');
      }
      return const <PendingNotificationRequest>[];
    }
  }

  // The `-v2` suffix is load-bearing, not cosmetic: Android freezes a channel's
  // sound at creation. A device that first created `awan.adhan` without a sound
  // keeps it silent for the life of the install, so fixing the sound means a new
  // channel id — the old one is simply abandoned.
  static const String kAdhanChannelId = AdhanSound.systemAdhanChannelId;
  static const String kAdhanVibrateChannelId = AdhanSound.vibrateChannelId;
  static const String kAdhanQuietChannelId = AdhanSound.quietChannelId;
  static const String kReminderChannelId = AdhanSound.silentReminderChannelId;
  static const String kLockScreenChannelId = 'awan.lockscreen-v2';
  static const String kReminderSoundChannelId =
      AdhanSound.systemReminderChannelId;
  static const String kFridayChannelId = 'awan.friday';
}

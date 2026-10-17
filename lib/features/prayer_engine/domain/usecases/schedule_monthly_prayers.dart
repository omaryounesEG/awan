import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Builds and arms the whole adhan plan for the coming month — **entirely
/// offline**.
///
/// ### Zero-tracking guarantee
///
/// The five instants of each day are computed on the device by `adhan_dart`
/// (see [CalculatePrayerTimes]); nothing about this use case can reach the
/// network. It has exactly two collaborators — the offline engine and the port
/// that hands finished instants to the OS. No HTTP client, no analytics, no
/// remote config, no polling. The OS delivers the adhan from its own alarm
/// manager, so the app is not running at prayer time either.
///
/// A month is 150 notifications (5 × 30) — plus, if the user asked for them,
/// 150 quieter pre-adhan reminders. They are handed over in a single pass, are
/// one-shot, and survive a reboot because Android re-arms them by itself.
class ScheduleMonthlyPrayers {
  const ScheduleMonthlyPrayers({
    required this.engine,
    required this.scheduler,
    this.reminderText,
  });

  final CalculatePrayerTimes engine;
  final AdhanSchedulerPort scheduler;

  /// Wording for the hourglass. Null keeps the old behaviour (the reminder
  /// repeats the adhan's own wording) so an existing caller never breaks.
  final AdhanReminderTextBuilder? reminderText;

  /// [onDay] is a seam for the caller (data layer) to persist each computed day
  /// without the domain ever knowing about Isar.
  Future<int> call({
    required AppSettings settings,
    required PrayerCalcSpec spec,
    required AdhanTextBuilder adhanText,
    int days = AppConstants.notificationDaysAhead,
    String channelName = 'Adhan',
    int shiftMinutes = 0,
    void Function(DayPrayerTimes day)? onDay,
  }) async {
    final List<PrayerName> prayers = <PrayerName>[
      for (final PrayerName prayer in PrayerName.obligatory)
        if (settings.isPrayerEnabled(prayer.key)) prayer,
    ];

    // Off, or every prayer muted: the correct schedule is no schedule at all.
    if (!settings.notificationsEnabled || prayers.isEmpty) {
      await scheduler.cancelAll();
      return 0;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<ScheduledAdhan> items = <ScheduledAdhan>[];

    for (int offset = 0; offset < days; offset++) {
      // Calendar arithmetic, **not** `today.add(Duration(days: offset))`.
      //
      // Adding 24-hour blocks moves by an absolute duration, so a DST transition
      // inside the window makes one day 25 hours long: the next "day" then starts
      // at 23:00 of the *previous* date, the plan repeats a date, and every later
      // instant is shifted an hour. Egypt ends DST at the end of October — inside
      // this 30-day window — so this is not hypothetical: it was caught by the
      // 30-distinct-days assertion in `schedule_monthly_prayers_test.dart`.
      final DateTime date = DateTime(today.year, today.month, today.day + offset);
      final DayPrayerTimes day = engine.forDate(date: date, spec: spec);
      onDay?.call(day);

      // Friday is different in two ways, and both are the reader's own rules:
      //
      // * the pre-adhan warning belongs to Jumu'ah alone — a nudge before the
      //   khutbah is useful, a nudge before every prayer is noise;
      // * for one hour after the Jumu'ah adhan the phone stays quiet: that hour
      //   is the khutbah, and a notification during it is an interruption of
      //   worship, not information.
      final DateTime jumuahAt = day
          .timeOf(PrayerName.dhuhr)
          .add(Duration(minutes: shiftMinutes));
      final bool isFriday = date.weekday == DateTime.friday;

      for (final PrayerName prayer in prayers) {
        // The alarm must ring at the clock the user actually reads, so the
        // manual summer/winter correction applies here too. [onDay] still
        // receives the *unshifted* day, which keeps the local cache purely
        // astronomical — flipping the setting re-plans without recomputing.
        final DateTime at =
            day.timeOf(prayer).add(Duration(minutes: shiftMinutes));
        // Nothing else may ring inside the khutbah hour.
        if (isFriday &&
            prayer != PrayerName.dhuhr &&
            at.isAfter(jumuahAt) &&
            at.difference(jumuahAt) < const Duration(hours: 1)) {
          continue;
        }
        final ({String title, String body}) text = adhanText(prayer, at);

        items.add(ScheduledAdhan(
          id: NotificationIds.adhan(prayer.notificationIndex, offset),
          at: at,
          title: text.title,
          body: text.body,
          payload: 'prayer:${prayer.key}:${date.toIso8601String()}',
          // Per prayer: quiet, a buzz, or a buzz with the tone.
          alertMode: settings.adhanPreferences.alertModeFor(prayer.key),
        ));

        // The pre-prayer hourglass: off unless the reader asked for it, and
        // silent unless they asked for the chime too. Minutes default to 20 in
        // the settings model, so an install that enabled the switch but never
        // touched the number still gets a sane lead time.
        final int lead = settings.preAdhanMinutes > 0
            ? settings.preAdhanMinutes
            : AppConstants.defaultPreAdhanMinutes;
        if (settings.preAdhanEnabled &&
            lead > 0 &&
            isFriday &&
            prayer == PrayerName.dhuhr) {
          final ({String title, String body}) reminder =
              reminderText?.call(prayer, at, lead) ?? text;
          items.add(ScheduledAdhan(
            id: NotificationIds.preAdhan(prayer.notificationIndex, offset),
            at: at.subtract(Duration(minutes: lead)),
            title: reminder.title,
            body: reminder.body,
            isReminder: true,
            playsSound: settings.preAdhanSound.audible,
            // The hourglass counts down to the *adhan*, not to itself: the
            // notification lands 20 minutes early, and the number on the lock
            // screen has to be time left until the prayer.
            countdownTo: at,
            payload: 'reminder:${prayer.key}',
          ));
        }
      }
    }

    return scheduler.replaceAll(
      items,
      adhanSound: settings.adhanSound,
      preAdhanSound: settings.preAdhanSound,
      vibrate: settings.notificationVibration,
      channelName: channelName,
    );
  }
}

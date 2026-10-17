import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/pre_prayer_due.dart';
import 'package:awan/features/prayer_engine/domain/usecases/schedule_monthly_prayers.dart';

/// The hourglass has two halves that must agree: the OS plan (which fires when the
/// app is closed) and the floating card (which fires when it is open). Both are
/// driven by the same `preAdhan*` settings, so both are tested here — the plan
/// through the port fake, the card through the pure rule.
class _FakeScheduler implements AdhanSchedulerPort {
  List<ScheduledAdhan> items = <ScheduledAdhan>[];
  AdhanSound? preAdhanSound;

  @override
  Future<int> replaceAll(
    List<ScheduledAdhan> items, {
    required AdhanSound adhanSound,
    required AdhanSound preAdhanSound,
    required bool vibrate,
    required String channelName,
  }) async {
    this.items = items;
    this.preAdhanSound = preAdhanSound;
    return items.length;
  }

  @override
  Future<void> cancelAll() async => items = <ScheduledAdhan>[];
}

const PrayerCalcSpec _spec = PrayerCalcSpec(
  latitude: 30.0444,
  longitude: 31.2357,
  method: PrayerMethod.egyptian,
  madhab: AsrMadhab.shafi,
  highLatitude: HighLatitude.middleOfTheNight,
);

({String title, String body}) _adhanText(PrayerName prayer, DateTime at) =>
    (title: 'adhan ${prayer.key}', body: at.toIso8601String());

({String title, String body}) _reminderText(
  PrayerName prayer,
  DateTime at,
  int minutes,
) =>
    (
      title: 'باقي $minutes دقيقة على ${prayer.key}',
      body: at.toIso8601String(),
    );

Map<PrayerName, DateTime> _times({DateTime? asr, DateTime? isha}) =>
    <PrayerName, DateTime>{
      PrayerName.fajr: DateTime(2026, 10, 10, 5, 0),
      PrayerName.dhuhr: DateTime(2026, 10, 10, 12, 0),
      PrayerName.asr: asr ?? DateTime(2026, 10, 10, 15, 45),
      PrayerName.isha: isha ?? DateTime(2026, 10, 10, 19, 15),
    };

void main() {
  group('duePrePrayer — the floating hourglass', () {
    test('stays hidden until the window opens', () {
      final Map<PrayerName, DateTime> times = _times();
      // 21 minutes before Asr with a 20-minute lead: one minute too early.
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 24),
          minutes: 20,
          enabled: true,
        ),
        isNull,
      );
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 25),
          minutes: 20,
          enabled: true,
        )?.prayer,
        PrayerName.asr,
      );
    });

    test('counts down the minutes that are left', () {
      final PrePrayerDue? due = duePrePrayer(
        times: _times(),
        now: DateTime(2026, 10, 10, 15, 31),
        minutes: 20,
        enabled: true,
      );
      expect(due?.prayer, PrayerName.asr);
      expect(due?.minutesLeft, 14);
      expect(due?.at, DateTime(2026, 10, 10, 15, 45));
    });

    test('leaves on its own the moment the prayer arrives', () {
      final Map<PrayerName, DateTime> times = _times();
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 45),
          minutes: 20,
          enabled: true,
        ),
        isNull,
        reason: 'the adhan silences the hourglass',
      );
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 46),
          minutes: 20,
          enabled: true,
        ),
        isNull,
      );
    });

    test('is silent when the reader turned it off, or asked for no lead time',
        () {
      final Map<PrayerName, DateTime> times = _times();
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 40),
          minutes: 20,
          enabled: false,
        ),
        isNull,
      );
      expect(
        duePrePrayer(
          times: times,
          now: DateTime(2026, 10, 10, 15, 40),
          minutes: 0,
          enabled: true,
        ),
        isNull,
      );
    });

    test('does not come back once it is dismissed', () {
      final DateTime now = DateTime(2026, 10, 10, 15, 40);
      final PrePrayerDue? first = duePrePrayer(
        times: _times(),
        now: now,
        minutes: 20,
        enabled: true,
      );
      expect(first, isNotNull);
      expect(
        duePrePrayer(
          times: _times(),
          now: now,
          minutes: 20,
          enabled: true,
          dismissed: <String>{first!.key},
        ),
        isNull,
      );
      // …and dismissing today's Asr leaves tomorrow's alone: the key carries the
      // instant, not just the name.
      expect(
        duePrePrayer(
          times: _times(asr: DateTime(2026, 10, 11, 15, 44)),
          now: DateTime(2026, 10, 11, 15, 30),
          minutes: 20,
          enabled: true,
          dismissed: <String>{first.key},
        )?.prayer,
        PrayerName.asr,
      );
    });

    test('picks the earliest prayer when two windows overlap', () {
      // Artificial but cheap: two prayers ten minutes apart, ten-minute lead.
      final PrePrayerDue? due = duePrePrayer(
        times: _times(
          asr: DateTime(2026, 10, 10, 15, 45),
          isha: DateTime(2026, 10, 10, 15, 50),
        ),
        now: DateTime(2026, 10, 10, 15, 41),
        minutes: 10,
        enabled: true,
      );
      expect(due?.prayer, PrayerName.asr);
      expect(due?.minutesLeft, 4);
    });
  });

  group('the pre-prayer plan handed to the OS', () {
    ScheduleMonthlyPrayers planner(_FakeScheduler scheduler) =>
        ScheduleMonthlyPrayers(
          engine: const CalculatePrayerTimes(),
          scheduler: scheduler,
          reminderText: _reminderText,
        );

    // Eight days, not one: the reminder belongs to Jumu'ah alone now, so a
    // single-day plan would be empty six days out of seven and the test would
    // pass or fail by the calendar. Any eight consecutive days hold a Friday.
    int fridaysIn(int days) {
      final DateTime today = DateTime.now();
      return <int>[
        for (int i = 0; i < days; i++)
          DateTime(today.year, today.month, today.day + i).weekday,
      ].where((int weekday) => weekday == DateTime.friday).length;
    }

    Future<List<ScheduledAdhan>> planFor(AppSettings settings) async {
      final _FakeScheduler scheduler = _FakeScheduler();
      await planner(scheduler)(
        settings: settings,
        spec: _spec,
        adhanText: _adhanText,
        days: 8,
      );
      return scheduler.items;
    }

    test('adds nothing at all until the switch is on', () async {
      final List<ScheduledAdhan> off = await planFor(
        const AppSettings(notificationsEnabled: true),
      );
      expect(off.length, 40);
      expect(off.where((ScheduledAdhan i) => i.isReminder), isEmpty);
    });

    test('only Jumu\'ah gets a warning, 20 minutes early', () async {
      final List<ScheduledAdhan> on = await planFor(
        const AppSettings(
          notificationsEnabled: true,
          preAdhanEnabled: true,
          preAdhanMinutes: 20,
        ),
      );
      final List<ScheduledAdhan> reminders =
          on.where((ScheduledAdhan i) => i.isReminder).toList();
      expect(
        reminders.length,
        fridaysIn(8),
        reason: 'one warning a week, on Friday, and nowhere else',
      );

      for (final ScheduledAdhan reminder in reminders) {
        final ScheduledAdhan adhan = on.firstWhere((ScheduledAdhan i) =>
            !i.isReminder && i.id == reminder.id - 50000);
        expect(
          adhan.title,
          'adhan ${PrayerName.dhuhr.key}',
          reason: 'the warning is the Jumu\'ah khutbah, not any other prayer',
        );
        expect(
          adhan.at.difference(reminder.at).inMinutes,
          20,
          reason: 'every reminder leads its own prayer by exactly 20 minutes',
        );
        expect(reminder.title, contains('20'));
        expect(reminder.playsSound, isFalse,
            reason: 'gentle by default: silent unless asked');
      }
    });

    test('an install that never picked a lead time still gets 20 minutes',
        () async {
      final List<ScheduledAdhan> items = await planFor(
        const AppSettings(
          notificationsEnabled: true,
          preAdhanEnabled: true,
          preAdhanMinutes: 0,
        ),
      );
      final ScheduledAdhan reminder =
          items.firstWhere((ScheduledAdhan i) => i.isReminder);
      final ScheduledAdhan adhan = items.firstWhere((ScheduledAdhan i) =>
          !i.isReminder && i.id == reminder.id - 50000);
      expect(
        adhan.at.difference(reminder.at).inMinutes,
        AppConstants.defaultPreAdhanMinutes,
      );
    });

    test('carries the chime choice through to the platform', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      await planner(scheduler)(
        settings: const AppSettings(
          notificationsEnabled: true,
          preAdhanEnabled: true,
          preAdhanSound: AdhanSound.system,
        ),
        spec: _spec,
        adhanText: _adhanText,
        days: 1,
      );
      // The setting is the phone's tone and the item was planned with sound.
      expect(scheduler.preAdhanSound?.audible, isTrue);
      expect(
        scheduler.items
            .where((ScheduledAdhan i) => i.isReminder)
            .every((ScheduledAdhan i) => i.playsSound),
        isTrue,
      );
    });

    test('turning off all notifications also drops the hourglass', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final int armed = await planner(scheduler)(
        settings: const AppSettings(
          notificationsEnabled: false,
          preAdhanEnabled: true,
        ),
        spec: _spec,
        adhanText: _adhanText,
      );
      expect(armed, 0);
      expect(scheduler.items, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/schedule_monthly_prayers.dart';

/// Records what the use case asked "the OS" to do.
///
/// The whole point of this fake is that it is the *only* collaborator besides the
/// offline engine: if the use case needed anything else — an HTTP client, a
/// platform channel, a database — this test could not compile it. So a green run
/// here is the offline/zero-tracking guarantee, not just a happy path.
class _FakeScheduler implements AdhanSchedulerPort {
  List<ScheduledAdhan> items = <ScheduledAdhan>[];
  int cancelCalls = 0;
  AdhanSound? adhanSound;
  AdhanSound? preAdhanSound;
  bool? vibrate;
  String? channelName;

  @override
  Future<int> replaceAll(
    List<ScheduledAdhan> items, {
    required AdhanSound adhanSound,
    required AdhanSound preAdhanSound,
    required bool vibrate,
    required String channelName,
  }) async {
    this.items = items;
    this.adhanSound = adhanSound;
    this.preAdhanSound = preAdhanSound;
    this.vibrate = vibrate;
    this.channelName = channelName;
    return items.length;
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    items = <ScheduledAdhan>[];
  }
}

const PrayerCalcSpec _spec = PrayerCalcSpec(
  latitude: 30.0444,
  longitude: 31.2357,
  method: PrayerMethod.egyptian,
  madhab: AsrMadhab.shafi,
  highLatitude: HighLatitude.middleOfTheNight,
);

({String title, String body}) _text(PrayerName prayer, DateTime at) =>
    (title: prayer.key, body: '${prayer.key}@${at.toIso8601String()}');

String _day(DateTime at) => '${at.year}-${at.month}-${at.day}';

void main() {
  group('ScheduleMonthlyPrayers', () {
    test('arms exactly five prayers for each of the next 30 days', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      );

      final int armed = await planner(
        settings: const AppSettings(),
        spec: _spec,
        adhanText: _text,
      );

      expect(armed, 150, reason: '5 prayers × 30 days');
      expect(scheduler.items.length, 150);
      expect(scheduler.cancelCalls, 0, reason: 'a fresh plan replaces, not cancels');
      expect(scheduler.channelName, 'Adhan');
      // The default setting is the phone's own alarm tone, and it is audible.
      expect(scheduler.adhanSound?.audible, isTrue);
      expect(scheduler.vibrate, isTrue);

      // Deterministic ids: a later run can cancel exactly this set.
      expect(scheduler.items.map((ScheduledAdhan i) => i.id).toSet().length, 150);

      // Five per calendar day, for 30 distinct days.
      final Map<String, int> perDay = <String, int>{};
      for (final ScheduledAdhan item in scheduler.items) {
        perDay.update(_day(item.at), (int v) => v + 1, ifAbsent: () => 1);
      }
      expect(perDay.length, 30);
      expect(perDay.values.every((int v) => v == 5), isTrue);

      // Sunrise is an astronomical marker, never a notification.
      expect(
        scheduler.items.any((ScheduledAdhan i) => i.body.contains('sunrise')),
        isFalse,
      );

      // Nothing but the five prayers unless the user asked for reminders.
      expect(scheduler.items.where((ScheduledAdhan i) => i.isReminder), isEmpty);

      // Each day's instants are strictly increasing (fajr < dhuhr < … < isha).
      for (int offset = 0; offset < 30; offset++) {
        final List<DateTime> ofDay = scheduler.items
            .where((ScheduledAdhan i) => i.id <= NotificationIds.adhan(4, offset) &&
                i.id >= NotificationIds.adhan(0, offset))
            .map((ScheduledAdhan i) => i.at)
            .toList();
        final List<DateTime> sorted = List<DateTime>.from(ofDay)..sort();
        expect(ofDay, sorted, reason: 'day $offset must be in prayer order');
      }
    });

    test('adds one quieter reminder a week, on Jumu\'ah only', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      );

      final int armed = await planner(
        // The switch is the authority — a lead time alone must not schedule
        // anything, which is exactly what the hourglass tests pin down.
        settings: const AppSettings(preAdhanEnabled: true, preAdhanMinutes: 15),
        spec: _spec,
        adhanText: _text,
      );

      final DateTime today = DateTime.now();
      final int fridays = <int>[
        for (int i = 0; i < 30; i++)
          DateTime(today.year, today.month, today.day + i).weekday,
      ].where((int weekday) => weekday == DateTime.friday).length;

      expect(
        armed,
        150 + fridays,
        reason: '150 adhans + one Jumu\'ah warning a week',
      );
      final List<ScheduledAdhan> reminders = scheduler.items
          .where((ScheduledAdhan i) => i.isReminder)
          .toList();
      expect(reminders.length, fridays);
      // The warning is the khutbah: it leads Dhuhr, and it leads it by the
      // chosen 15 minutes.
      for (final ScheduledAdhan reminder in reminders) {
        final ScheduledAdhan adhan = scheduler.items.firstWhere(
          (ScheduledAdhan i) =>
              !i.isReminder && i.id == reminder.id - 50000,
        );
        expect(adhan.title, 'dhuhr');
        expect(
          adhan.at.difference(reminder.at),
          const Duration(minutes: 15),
        );
      }
    });

    test('off means no schedule at all, and anything pending is cleared', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      );

      final int armed = await planner(
        settings: const AppSettings(notificationsEnabled: false),
        spec: _spec,
        adhanText: _text,
      );

      expect(armed, 0);
      expect(scheduler.items, isEmpty);
      expect(scheduler.cancelCalls, 1);
    });

    test('a muted prayer is dropped from the plan', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      );

      final int armed = await planner(
        settings: const AppSettings(
          enabledPrayers: <String, bool>{'fajr': false},
        ),
        spec: _spec,
        adhanText: _text,
      );

      expect(armed, 120, reason: '4 prayers × 30 days');
      expect(
        scheduler.items.any((ScheduledAdhan i) => i.title == 'fajr'),
        isFalse,
      );
    });

    test('every computed day is offered to the caller for caching', () async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      );

      final List<DayPrayerTimes> seen = <DayPrayerTimes>[];
      await planner(
        settings: const AppSettings(),
        spec: _spec,
        adhanText: _text,
        onDay: seen.add,
      );

      expect(seen.length, 30);
      // The seam is per-day, and each day carries the five prayer instants the
      // plan was built from.
      expect(seen.first.timeOf(PrayerName.isha).isAfter(seen.first.timeOf(PrayerName.fajr)), isTrue);
    });
  });
}

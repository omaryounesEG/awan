import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/clock_shift.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/schedule_monthly_prayers.dart';

/// Records what the planner asked "the OS" to do.
class _FakeScheduler implements AdhanSchedulerPort {
  List<ScheduledAdhan> items = <ScheduledAdhan>[];

  @override
  Future<int> replaceAll(
    List<ScheduledAdhan> items, {
    required AdhanSound adhanSound,
    required AdhanSound preAdhanSound,
    required bool vibrate,
    required String channelName,
  }) async {
    this.items = items;
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

({String title, String body}) _text(PrayerName prayer, DateTime at) =>
    (title: prayer.key, body: prayer.key);

void main() {
  group('summer/winter time — resolving the stored mode', () {
    test('automatic trusts the device and shifts nothing', () {
      expect(resolveDstMinutes(kDstModeAuto), 0);
      expect(resolveDstMinutes(''), 0);
    });

    test('the forced modes move exactly one hour', () {
      expect(resolveDstMinutes(kDstModePlusOne), 60);
      expect(resolveDstMinutes(kDstModeMinusOne), -60);
    });

    test('an unrecognised value is treated as automatic', () {
      // A corrupt preference must never silently shift a prayer time.
      expect(resolveDstMinutes('plus2'), 0);
      expect(resolveDstMinutes('AUTO'), 0);
      expect(isKnownDstMode('plus2'), isFalse);
      expect(isKnownDstMode(kDstModePlusOne), isTrue);
    });

    test('the offset is written the way a person writes it', () {
      expect(formatUtcOffset(180), 'UTC+03:00');
      expect(formatUtcOffset(0), 'UTC+00:00');
      expect(formatUtcOffset(-120), 'UTC−02:00');
      expect(formatUtcOffset(-150), 'UTC−02:30');
      expect(formatUtcOffset(330), 'UTC+05:30');
    });
  });

  group('summer/winter time — what the device is doing', () {
    test('DST detection agrees with the raw zone offsets', () {
      final DateTime reference = DateTime(2026, 6, 15, 12);
      final int january = DateTime(2026, 1, 15, 12).timeZoneOffset.inMinutes;
      final int july = DateTime(2026, 7, 15, 12).timeZoneOffset.inMinutes;
      expect(deviceObservesDst(now: reference), january != july);
    });

    test('a device that never changes offset is never on summer time', () {
      final int january = DateTime(2026, 1, 15, 12).timeZoneOffset.inMinutes;
      final int july = DateTime(2026, 7, 15, 12).timeZoneOffset.inMinutes;
      if (january == july) {
        expect(deviceIsOnSummerTime(now: DateTime(2026, 6, 15, 12)), isFalse);
      } else {
        // Whichever half we are in, the flag matches the larger offset.
        final int now = DateTime(2026, 6, 15, 12).timeZoneOffset.inMinutes;
        expect(deviceIsOnSummerTime(now: DateTime(2026, 6, 15, 12)),
            now >= (january > july ? january : july));
      }
    });
  });

  group('DayPrayerTimes.shifted', () {
    DayPrayerTimes day() => DayPrayerTimes(
          date: DateTime(2026, 3, 21),
          spec: _spec,
          computedAt: DateTime(2026, 3, 21, 1),
          times: <PrayerName, DateTime>{
            for (final PrayerName prayer in PrayerName.values)
              prayer: DateTime(2026, 3, 21, 4 + prayer.index * 2),
          },
        );

    test('every instant moves by the correction', () {
      final DayPrayerTimes base = day();
      final DayPrayerTimes shifted = base.shifted(60);
      for (final PrayerName prayer in PrayerName.values) {
        expect(shifted.timeOf(prayer), base.timeOf(prayer).add(const Duration(hours: 1)));
      }
    });

    test('the calendar key and the specification are untouched', () {
      final DayPrayerTimes base = day();
      final DayPrayerTimes shifted = base.shifted(-60);
      expect(shifted.date, base.date);
      expect(shifted.spec, base.spec);
      expect(shifted.computedAt, base.computedAt);
    });

    test('zero is a no-op that returns the very same object', () {
      final DayPrayerTimes base = day();
      expect(identical(base.shifted(0), base), isTrue);
    });
  });

  group('the armed adhan follows the displayed clock', () {
    Future<(List<ScheduledAdhan>, List<DayPrayerTimes>)> plan(int shift) async {
      final _FakeScheduler scheduler = _FakeScheduler();
      final List<DayPrayerTimes> cached = <DayPrayerTimes>[];
      await ScheduleMonthlyPrayers(
        engine: const CalculatePrayerTimes(),
        scheduler: scheduler,
      )(
        settings: const AppSettings(),
        spec: _spec,
        adhanText: _text,
        days: 2,
        shiftMinutes: shift,
        onDay: cached.add,
      );
      return (scheduler.items, cached);
    }

    test('a forced summer hour moves the alarms, not the calculation', () async {
      final (List<ScheduledAdhan> plain, List<DayPrayerTimes> plainDays) = await plan(0);
      final (List<ScheduledAdhan> shifted, List<DayPrayerTimes> shiftedDays) = await plan(60);

      expect(shifted.length, plain.length);
      for (int i = 0; i < plain.length; i++) {
        expect(shifted[i].at, plain[i].at.add(const Duration(hours: 1)),
            reason: 'notification ${plain[i].id} should ring an hour later');
      }

      // The days handed to the cache are the pure astronomical ones in both runs:
      // flipping the setting must not rewrite a month of cached calculations.
      expect(shiftedDays.length, plainDays.length);
      for (int i = 0; i < plainDays.length; i++) {
        for (final PrayerName prayer in PrayerName.values) {
          expect(shiftedDays[i].timeOf(prayer), plainDays[i].timeOf(prayer));
        }
      }
    });

    test('winter time moves them the other way', () async {
      final (List<ScheduledAdhan> plain, _) = await plan(0);
      final (List<ScheduledAdhan> shifted, _) = await plan(-60);
      expect(shifted.first.at, plain.first.at.subtract(const Duration(hours: 1)));
    });
  });

  group('AppSettings persistence', () {
    test('the correction survives a save/load round trip', () {
      const AppSettings settings = AppSettings(dstMode: kDstModeMinusOne);
      final AppSettings restored = AppSettings.decode(settings.encode());
      expect(restored.dstMode, kDstModeMinusOne);
    });

    test('automatic is the default', () {
      expect(const AppSettings().dstMode, kDstModeAuto);
      expect(AppSettings.decode(const AppSettings().encode()).dstMode, kDstModeAuto);
    });

    test('copyWith reaches the field', () {
      expect(const AppSettings().copyWith(dstMode: kDstModePlusOne).dstMode,
          kDstModePlusOne);
    });
  });
}

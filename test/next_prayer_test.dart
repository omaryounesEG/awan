import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/next_prayer.dart';

/// Cairo, Egyptian method — the app's own default.
const PrayerCalcSpec _spec = PrayerCalcSpec(
  latitude: 30.0444,
  longitude: 31.2357,
  method: PrayerMethod.egyptian,
  madhab: AsrMadhab.shafi,
  highLatitude: HighLatitude.middleOfTheNight,
);

void main() {
  const CalculatePrayerTimes engine = CalculatePrayerTimes();
  final DayPrayerTimes day =
      engine.forDate(date: DateTime(2026, 6, 1), spec: _spec);
  final DayPrayerTimes tomorrow =
      engine.forDate(date: DateTime(2026, 6, 2), spec: _spec);

  group('nextPrayerAfter', () {
    test('picks the prayer whose instant is still ahead', () {
      final DateTime now =
          day.timeOf(PrayerName.dhuhr).subtract(const Duration(minutes: 1));

      final ({PrayerName prayer, DateTime at})? next =
          nextPrayerAfter(days: <DayPrayerTimes>[day], now: now);

      expect(next!.prayer, PrayerName.dhuhr);
      expect(next.at, day.timeOf(PrayerName.dhuhr));
    });

    test('passes to the next day when the window today is exhausted', () {
      final DateTime now =
          day.timeOf(PrayerName.isha).add(const Duration(minutes: 5));

      final ({PrayerName prayer, DateTime at})? next =
          nextPrayerAfter(days: <DayPrayerTimes>[day, tomorrow], now: now);

      expect(next!.prayer, PrayerName.fajr);
      expect(next.at, tomorrow.timeOf(PrayerName.fajr));
    });

    test('skips a prayer the reader muted', () {
      final DateTime now =
          day.timeOf(PrayerName.dhuhr).subtract(const Duration(minutes: 1));

      final ({PrayerName prayer, DateTime at})? next = nextPrayerAfter(
        days: <DayPrayerTimes>[day],
        now: now,
        enabled: (PrayerName prayer) => prayer != PrayerName.dhuhr,
      );

      expect(next!.prayer, PrayerName.asr);
    });

    test('the manual summer/winter shift moves the card with the adhan', () {
      final DateTime now = day.timeOf(PrayerName.dhuhr);

      final ({PrayerName prayer, DateTime at})? next = nextPrayerAfter(
        days: <DayPrayerTimes>[day],
        now: now,
        shiftMinutes: 60,
      );

      expect(next!.prayer, PrayerName.dhuhr);
      expect(
        next.at,
        day.timeOf(PrayerName.dhuhr).add(const Duration(minutes: 60)),
      );
    });

    test('a window with nothing ahead returns null instead of a guess', () {
      final DateTime now =
          day.timeOf(PrayerName.isha).add(const Duration(hours: 3));

      expect(nextPrayerAfter(days: <DayPrayerTimes>[day], now: now), isNull);
    });
  });
}

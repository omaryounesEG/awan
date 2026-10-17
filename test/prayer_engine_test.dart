import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Domain tests for the offline prayer engine.
///
/// These are the assertions that matter for correctness of the *worship data*:
/// the ordering of the times, the effect of an adjustment, and the qibla
/// bearing. They run with no plugins, no database and no network.
void main() {
  const CalculatePrayerTimes engine = CalculatePrayerTimes();

  // Cairo, Egyptian General Authority of Survey — the app's default.
  const PrayerCalcSpec spec = PrayerCalcSpec(
    latitude: 30.0444,
    longitude: 31.2357,
    method: PrayerMethod.egyptian,
    madhab: AsrMadhab.shafi,
    highLatitude: HighLatitude.middleOfTheNight,
  );

  group('CalculatePrayerTimes', () {
    test('orders fajr → sunrise → dhuhr → asr → maghrib → isha', () {
      final DayPrayerTimes day = engine.forDate(date: DateTime(2026, 10, 10), spec: spec);

      final List<DateTime> order = <DateTime>[
        day.timeOf(PrayerName.fajr),
        day.timeOf(PrayerName.sunrise),
        day.timeOf(PrayerName.dhuhr),
        day.timeOf(PrayerName.asr),
        day.timeOf(PrayerName.maghrib),
        day.timeOf(PrayerName.isha),
      ];

      for (int i = 1; i < order.length; i++) {
        expect(
          order[i].isAfter(order[i - 1]),
          isTrue,
          reason: '${PrayerName.values[i]} must come after '
              '${PrayerName.values[i - 1]}',
        );
      }
    });

    test('every time falls on the requested day', () {
      final DateTime date = DateTime(2026, 10, 10);
      final DayPrayerTimes day = engine.forDate(date: date, spec: spec);

      for (final PrayerName prayer in PrayerName.values) {
        final DateTime at = day.timeOf(prayer);
        expect(at.year, date.year);
        expect(at.month, date.month);
        expect(at.day, date.day);
      }
    });

    test('a +5 minute adjustment shifts exactly that prayer', () {
      const PrayerCalcSpec adjusted = PrayerCalcSpec(
        latitude: 30.0444,
        longitude: 31.2357,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.shafi,
        highLatitude: HighLatitude.middleOfTheNight,
        adjustments: <String, int>{'fajr': 5},
      );

      final DateTime date = DateTime(2026, 10, 10);
      final DayPrayerTimes plain = engine.forDate(date: date, spec: spec);
      final DayPrayerTimes shifted = engine.forDate(date: date, spec: adjusted);

      expect(
        shifted.timeOf(PrayerName.fajr)
            .difference(plain.timeOf(PrayerName.fajr))
            .inMinutes,
        5,
      );
      expect(
        shifted.timeOf(PrayerName.dhuhr),
        plain.timeOf(PrayerName.dhuhr),
      );
    });

    test('the hanafi madhab pushes asr later than the shafi madhab', () {
      const PrayerCalcSpec hanafi = PrayerCalcSpec(
        latitude: 30.0444,
        longitude: 31.2357,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.hanafi,
        highLatitude: HighLatitude.middleOfTheNight,
      );

      final DateTime date = DateTime(2026, 10, 10);
      expect(
        engine
            .forDate(date: date, spec: hanafi)
            .timeOf(PrayerName.asr)
            .isAfter(engine.forDate(date: date, spec: spec).timeOf(PrayerName.asr)),
        isTrue,
      );
    });

    test('a month yields one day per day of the month', () {
      final List<DayPrayerTimes> month =
          engine.forMonth(year: 2026, month: 2, spec: spec);
      expect(month.length, 28);
      expect(month.first.date.day, 1);
      expect(month.last.date.day, 28);
    });

    test('the qibla bearing from Cairo is south-east', () {
      final double bearing = engine.qiblaBearing(spec);
      // Cairo → Makkah is ~136° from true north.
      expect(bearing, greaterThan(130));
      expect(bearing, lessThan(142));
    });
  });

  group('DayPrayerTimes', () {
    test('next() returns the first prayer strictly after now', () {
      final DayPrayerTimes day = engine.forDate(date: DateTime(2026, 10, 10), spec: spec);
      final DateTime beforeDhuhr =
          day.timeOf(PrayerName.dhuhr).subtract(const Duration(minutes: 1));

      final NextPrayer? next = day.next(beforeDhuhr);
      expect(next?.name, PrayerName.dhuhr);
      // Sunrise is an astronomical marker, not a prayer, so the "previous"
      // slot is fajr.
      expect(next?.previous, PrayerName.fajr);
    });

    test('next() returns null after isha', () {
      final DayPrayerTimes day = engine.forDate(date: DateTime(2026, 10, 10), spec: spec);
      final DateTime afterIsha =
          day.timeOf(PrayerName.isha).add(const Duration(minutes: 1));
      expect(day.next(afterIsha), isNull);
    });
  });
}

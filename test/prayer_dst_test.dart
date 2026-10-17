import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Regression lock for the DST edge case that used to break the engine.
///
/// Passing a *local* midnight to `adhan_dart` on a day that is 25 hours long
/// (Egypt's DST ends on 2026-10-29) made its internal date arithmetic return
/// `09:38Z` for both fajr and isha — a "fajr" at 12:38 local, seven hours late,
/// and identical to isha. The engine now hands the library a UTC midnight; the
/// whole month is asserted here so any future library bump that reintroduces the
/// discontinuity fails loudly.
void main() {
  const PrayerCalcSpec cairo = PrayerCalcSpec(
    latitude: 30.0444,
    longitude: 31.2357,
    method: PrayerMethod.egyptian,
    madhab: AsrMadhab.shafi,
    highLatitude: HighLatitude.middleOfTheNight,
  );
  const CalculatePrayerTimes engine = CalculatePrayerTimes();

  /// The six instants must be strictly ordered and each must belong to the
  /// calendar day being asked about (midnight is allowed for fajr, `23:59` for
  /// isha — nothing may land on the neighbouring day).
  void expectCoherent(DayPrayerTimes day) {
    final List<DateTime> times = <DateTime>[
      for (final PrayerName name in PrayerName.values) day.timeOf(name),
    ];

    for (int i = 0; i < times.length - 1; i++) {
      expect(
        times[i].isBefore(times[i + 1]),
        isTrue,
        reason: '${PrayerName.values[i].key} must precede '
            '${PrayerName.values[i + 1].key} on ${day.date} '
            '(${times[i]} vs ${times[i + 1]})',
      );
    }

    for (final DateTime at in times) {
      expect(at.year, day.date.year, reason: 'year on ${day.date}');
      expect(at.month, day.date.month, reason: 'month on ${day.date}');
      expect(at.day, day.date.day, reason: 'day on ${day.date} — $at');
    }

    // A fajr in the afternoon is the exact symptom the DST bug produced.
    expect(
      times.first.hour,
      lessThan(12),
      reason: 'fajr on ${day.date} must be before noon, was ${times.first}',
    );
  }

  test('every day of October 2026 is coherent, including the DST transition', () {
    final List<DayPrayerTimes> month = engine.forMonth(
      year: 2026,
      month: 10,
      spec: cairo,
    );
    expect(month.length, 31);
    for (final DayPrayerTimes day in month) {
      expectCoherent(day);
    }
  });

  test('2026-10-29 (25-hour day) has its real times, not the wrapped ones', () {
    final DayPrayerTimes day =
        engine.forDate(date: DateTime(2026, 10, 29), spec: cairo);

    // 02:38Z was the value the buggy path produced as 09:38Z.
    expect(day.timeOf(PrayerName.fajr).toUtc().hour, 2,
        reason: 'fajr must be ~02:38Z (05:38 local)');
    expect(day.timeOf(PrayerName.isha).toUtc().hour, 16,
        reason: 'isha must be ~16:28Z (19:28 local)');
    expect(
      day.timeOf(PrayerName.fajr).isAtSameMomentAs(day.timeOf(PrayerName.isha)),
      isFalse,
      reason: 'fajr and isha collapsed onto one instant under the bug',
    );
  });

  test('the fall-back moves the wall clock by an hour while the sun stands still', () {
    final DayPrayerTimes before =
        engine.forDate(date: DateTime(2026, 10, 28), spec: cairo);
    final DayPrayerTimes middle =
        engine.forDate(date: DateTime(2026, 10, 29), spec: cairo);
    final DayPrayerTimes after =
        engine.forDate(date: DateTime(2026, 10, 30), spec: cairo);

    int wallMinutes(DateTime at) => at.hour * 60 + at.minute;

    // Wall clock: 1 hour of fall-back minus the ~1 min/day drift.
    expect(
      wallMinutes(after.timeOf(PrayerName.fajr)) -
          wallMinutes(before.timeOf(PrayerName.fajr)),
      closeTo(-59, 4),
      reason: 'fajr reads ~59 min earlier after the clocks go back',
    );

    // Physics: the two instants are two real days apart, unaffected by DST.
    expect(
      after.timeOf(PrayerName.fajr)
          .difference(before.timeOf(PrayerName.fajr))
          .inMinutes,
      closeTo(2 * 24 * 60, 6),
      reason: 'UTC instants two days apart',
    );

    // The 25-hour day itself keeps a normal-looking wall clock.
    expect(middle.timeOf(PrayerName.fajr).hour, 5);
    expect(middle.timeOf(PrayerName.isha).hour, 19);
  });

  test('a southern-hemisphere-free sanity check: the month never goes backwards', () {
    final List<DayPrayerTimes> month =
        engine.forMonth(year: 2026, month: 3, spec: cairo);
    for (int i = 1; i < month.length; i++) {
      expect(
        month[i].timeOf(PrayerName.dhuhr)
            .isAfter(month[i - 1].timeOf(PrayerName.dhuhr)),
        isTrue,
        reason: 'dhuhr must advance day by day',
      );
    }
  });
}

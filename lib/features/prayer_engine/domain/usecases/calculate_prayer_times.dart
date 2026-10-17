import 'package:adhan_dart/adhan_dart.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// Domain service: the offline prayer-time arithmetic.
///
/// This is the *only* source of the times shown in the app. `adhan_dart` runs
/// on the device with zero network and effectively zero cost, which is what
/// makes the hybrid engine battery-proof: the online call is a verification,
/// never a dependency.
class CalculatePrayerTimes {
  const CalculatePrayerTimes();

  DayPrayerTimes call({
    required DateTime date,
    required PrayerCalcSpec spec,
  }) =>
      forDate(date: date, spec: spec);

  DayPrayerTimes forDate({
    required DateTime date,
    required PrayerCalcSpec spec,
  }) {
    final CalculationParameters parameters = spec.method.toParameters()
      ..madhab = spec.madhab.madhab
      ..highLatitudeRule = spec.highLatitude.rule;

    if (spec.adjustments.isNotEmpty) {
      parameters.adjustments = <Prayer, int>{
        for (final PrayerName name in PrayerName.values)
          name.toAdhanPrayer(): spec.adjustments[name.key] ?? 0,
      };
    }

    // The calendar day our *entity* is keyed by (local midnight) …
    final DateTime day = DateTime(date.year, date.month, date.day);

    // … but `adhan_dart` is handed the same calendar day as **UTC midnight**.
    //
    // The library returns UTC instants and only reads year/month/day from this
    // argument — yet it does its own arithmetic on it (`date - 1 day`,
    // `TimeComponents.utcDate(y, m, d)`). A *local* midnight belonging to a
    // 25-hour DST day poisons that arithmetic: on 2026-10-29 (the day Egypt's DST
    // ends) fajr and isha both came back as `09:38Z`, i.e. a "fajr" at 12:38
    // local — 7 hours late, and identical to isha. With a UTC midnight there is no
    // discontinuity and the same day yields `02:38Z` (05:38 local) / `16:28Z`
    // (19:28 local). Regression-locked in `test/prayer_dst_test.dart`.
    final PrayerTimes result = PrayerTimes(
      date: DateTime.utc(date.year, date.month, date.day),
      coordinates: Coordinates(spec.latitude, spec.longitude),
      calculationParameters: parameters,
      precision: true,
    );

    return DayPrayerTimes(
      date: day,
      spec: spec,
      computedAt: DateTime.now(),
      times: <PrayerName, DateTime>{
        PrayerName.fajr: result.fajr.toLocal(),
        PrayerName.sunrise: result.sunrise.toLocal(),
        PrayerName.dhuhr: result.dhuhr.toLocal(),
        PrayerName.asr: result.asr.toLocal(),
        PrayerName.maghrib: result.maghrib.toLocal(),
        PrayerName.isha: result.isha.toLocal(),
      },
    );
  }

  /// A whole month, ~1ms per day; callers may still move it to an isolate.
  List<DayPrayerTimes> forMonth({
    required int year,
    required int month,
    required PrayerCalcSpec spec,
  }) {
    final int days = DateTime(year, month + 1, 0).day;
    return <DayPrayerTimes>[
      for (int day = 1; day <= days; day++)
        forDate(date: DateTime(year, month, day), spec: spec),
    ];
  }

  /// Qibla bearing in degrees from true north.
  double qiblaBearing(PrayerCalcSpec spec) =>
      Qibla.qibla(Coordinates(spec.latitude, spec.longitude));

  /// Middle of the night and the last third (night-prayer windows).
  ({DateTime middle, DateTime lastThird}) nightTimes(DayPrayerTimes day) {
    final PrayerTimes raw = PrayerTimes(
      // UTC midnight for the same DST reason as [forDate].
      date: DateTime.utc(day.date.year, day.date.month, day.date.day),
      coordinates: Coordinates(day.spec.latitude, day.spec.longitude),
      calculationParameters: day.spec.method.toParameters()
        ..madhab = day.spec.madhab.madhab
        ..highLatitudeRule = day.spec.highLatitude.rule,
      precision: true,
    );
    final SunnahTimes sunnah = SunnahTimes(raw, precision: true);
    return (
      middle: sunnah.middleOfTheNight.toLocal(),
      lastThird: sunnah.lastThirdOfTheNight.toLocal(),
    );
  }
}

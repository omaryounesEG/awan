import 'package:equatable/equatable.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// The Step-3 domain entity: one day of prayer times, as the *domain* sees it.
///
/// It is deliberately spelled out — six named instants instead of a map — because
/// the UI, the notification scheduler and the widget tests all want
/// `entity.fajr`, and a named field cannot be typo-ed into a silent null the way
/// `times['fajer']` can.
///
/// The engine's richer `DayPrayerTimes` (which also carries the calculation
/// parameters and the verification result) stays the *data-layer* shape; the two
/// convert through [fromDay] / [toDay] so there is exactly one arithmetic core.
class PrayerTimesEntity extends Equatable {
  const PrayerTimesEntity({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.currentPrayer,
    this.nextPrayer,
    this.spec,
  });

  /// Local midnight of the day these times belong to.
  final DateTime date;

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// The prayer whose window is currently open (null before today's fajr).
  final PrayerName? currentPrayer;

  /// The prayer being waited for (null after today's isha).
  final PrayerName? nextPrayer;

  /// Kept for the round trip back into the engine / cache; null when the entity
  /// was built from a bare list of times.
  final PrayerCalcSpec? spec;

  DateTime? timeOf(PrayerName prayer) => switch (prayer) {
        PrayerName.fajr => fajr,
        PrayerName.sunrise => sunrise,
        PrayerName.dhuhr => dhuhr,
        PrayerName.asr => asr,
        PrayerName.maghrib => maghrib,
        PrayerName.isha => isha,
      };

  /// The six times in prayer order — the shape a timetable wants.
  List<DateTime> get ordered => <DateTime>[
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  /// True once today's last prayer has passed (the caller then shows tomorrow's
  /// fajr).
  bool get isDayOver => nextPrayer == null;

  /// The remaining time until [nextPrayer]; null when the day is over.
  Duration? remaining(DateTime now) =>
      nextPrayer == null ? null : timeOf(nextPrayer!)!.difference(now);

  /// The same day, re-evaluated at [now].
  ///
  /// This is what the one-second ticker calls: it re-derives only
  /// current/next — no recalculation, no I/O, no allocation of new `DateTime`s.
  PrayerTimesEntity at(DateTime now) => PrayerTimesEntity(
        date: date,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        currentPrayer: _currentAt(now),
        nextPrayer: _nextAt(now),
        spec: spec,
      );

  PrayerName? _currentAt(DateTime now) {
    PrayerName? current;
    for (final PrayerName prayer in PrayerName.obligatory) {
      if (!timeOf(prayer)!.isAfter(now)) current = prayer;
    }
    return current;
  }

  PrayerName? _nextAt(DateTime now) {
    for (final PrayerName prayer in PrayerName.obligatory) {
      if (timeOf(prayer)!.isAfter(now)) return prayer;
    }
    return null;
  }

  /// Builds the entity from the engine's day, stamping current/next at [now]
  /// (defaults to the moment of construction).
  factory PrayerTimesEntity.fromDay(DayPrayerTimes day, {DateTime? now}) {
    final PrayerTimesEntity bare = PrayerTimesEntity(
      date: day.date,
      fajr: day.timeOf(PrayerName.fajr),
      sunrise: day.timeOf(PrayerName.sunrise),
      dhuhr: day.timeOf(PrayerName.dhuhr),
      asr: day.timeOf(PrayerName.asr),
      maghrib: day.timeOf(PrayerName.maghrib),
      isha: day.timeOf(PrayerName.isha),
      spec: day.spec,
    );
    return bare.at(now ?? DateTime.now());
  }

  /// Back to the engine/cache shape.
  DayPrayerTimes toDay() => DayPrayerTimes(
        date: date,
        times: <PrayerName, DateTime>{
          PrayerName.fajr: fajr,
          PrayerName.sunrise: sunrise,
          PrayerName.dhuhr: dhuhr,
          PrayerName.asr: asr,
          PrayerName.maghrib: maghrib,
          PrayerName.isha: isha,
        },
        spec: spec ?? PrayerCalcSpec.fallback(latitude: 0, longitude: 0),
        computedAt: DateTime.now(),
      );

  @override
  List<Object?> get props => <Object?>[
        date,
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        currentPrayer,
        nextPrayer,
      ];
}

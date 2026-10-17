import 'package:adhan_dart/adhan_dart.dart';
import 'package:equatable/equatable.dart';

/// Domain entities of the prayer engine.
///
/// Pure Dart: no Flutter, no Isar, no Dio. Every entity is `Equatable` so
/// Riverpod can compare states cheaply and the widgets only rebuild on real
/// change (60fps discipline).

/// The five daily prayers plus sunrise, in display order.
enum PrayerName {
  fajr('fajr'),
  sunrise('sunrise'),
  dhuhr('dhuhr'),
  asr('asr'),
  maghrib('maghrib'),
  isha('isha');

  const PrayerName(this.key);

  /// Stable key used in settings, the database and notification payloads.
  final String key;

  bool get isPrayer => this != PrayerName.sunrise;

  static const List<PrayerName> obligatory = <PrayerName>[
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  static PrayerName fromKey(String key) => PrayerName.values.firstWhere(
        (PrayerName p) => p.key == key,
        orElse: () => PrayerName.fajr,
      );

  Prayer toAdhanPrayer() => switch (this) {
        PrayerName.fajr => Prayer.fajr,
        PrayerName.sunrise => Prayer.sunrise,
        PrayerName.dhuhr => Prayer.dhuhr,
        PrayerName.asr => Prayer.asr,
        PrayerName.maghrib => Prayer.maghrib,
        PrayerName.isha => Prayer.isha,
      };

  /// 0..4 for the obligatory prayers (notification id arithmetic).
  int get notificationIndex => obligatory.indexOf(this);
}

/// Calculation authorities exposed in the settings screen.
enum PrayerMethod {
  muslimWorldLeague('muslimWorldLeague', 3),
  egyptian('egyptian', 5),
  ummAlQura('ummAlQura', 4),
  karachi('karachi', 1),
  northAmerica('northAmerica', 2),
  kuwait('kuwait', 9),
  qatar('qatar', 10),
  dubai('dubai', 16),
  turkiye('turkiye', 13),
  singapore('singapore', 11),
  tehran('tehran', 7),
  jordan('jordan', 23),
  tunisia('tunisia', 18),
  algerian('algerian', 19),
  morocco('morocco', 21),
  france('france', 12),
  indonesian('indonesian', 20),
  moonsightingCommittee('moonsightingCommittee', 15),
  gulfRegion('gulfRegion', 8),
  other('other', 3);

  const PrayerMethod(this.key, this.aladhanId);

  final String key;

  /// The same authority's numeric id at Aladhan — used *only* to verify the
  /// offline calculation, never to produce the displayed times.
  final int aladhanId;

  static PrayerMethod fromKey(String key) => PrayerMethod.values.firstWhere(
        (PrayerMethod m) => m.key == key,
        orElse: () => PrayerMethod.egyptian,
      );

  CalculationParameters toParameters() => switch (this) {
        PrayerMethod.muslimWorldLeague =>
          CalculationMethodParameters.muslimWorldLeague(),
        PrayerMethod.egyptian => CalculationMethodParameters.egyptian(),
        PrayerMethod.ummAlQura => CalculationMethodParameters.ummAlQura(),
        PrayerMethod.karachi => CalculationMethodParameters.karachi(),
        PrayerMethod.northAmerica => CalculationMethodParameters.northAmerica(),
        PrayerMethod.kuwait => CalculationMethodParameters.kuwait(),
        PrayerMethod.qatar => CalculationMethodParameters.qatar(),
        PrayerMethod.dubai => CalculationMethodParameters.dubai(),
        PrayerMethod.turkiye => CalculationMethodParameters.turkiye(),
        PrayerMethod.singapore => CalculationMethodParameters.singapore(),
        PrayerMethod.tehran => CalculationMethodParameters.tehran(),
        PrayerMethod.jordan => CalculationMethodParameters.jordan(),
        PrayerMethod.tunisia => CalculationMethodParameters.tunisia(),
        PrayerMethod.algerian => CalculationMethodParameters.algerian(),
        PrayerMethod.morocco => CalculationMethodParameters.morocco(),
        PrayerMethod.france => CalculationMethodParameters.france(),
        PrayerMethod.indonesian => CalculationMethodParameters.indonesian(),
        PrayerMethod.moonsightingCommittee =>
          CalculationMethodParameters.moonsightingCommittee(),
        PrayerMethod.gulfRegion => CalculationMethodParameters.gulfRegion(),
        PrayerMethod.other => CalculationMethodParameters.other(),
      };
}

enum AsrMadhab {
  shafi('shafi', Madhab.shafi),
  hanafi('hanafi', Madhab.hanafi);

  const AsrMadhab(this.key, this.madhab);

  final String key;
  final Madhab madhab;

  static AsrMadhab fromKey(String key) =>
      key == 'hanafi' ? AsrMadhab.hanafi : AsrMadhab.shafi;
}

enum HighLatitude {
  middleOfTheNight('middleOfTheNight', HighLatitudeRule.middleOfTheNight),
  seventhOfTheNight('seventhOfTheNight', HighLatitudeRule.seventhOfTheNight),
  twilightAngle('twilightAngle', HighLatitudeRule.twilightAngle);

  const HighLatitude(this.key, this.rule);

  final String key;
  final HighLatitudeRule rule;

  static HighLatitude fromKey(String key) => HighLatitude.values.firstWhere(
        (HighLatitude h) => h.key == key,
        orElse: () => HighLatitude.middleOfTheNight,
      );
}

/// Everything that changes the numbers — also the cache identity.
class PrayerCalcSpec extends Equatable {
  const PrayerCalcSpec({
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.madhab,
    required this.highLatitude,
    this.adjustments = const <String, int>{},
  });

  final double latitude;
  final double longitude;
  final PrayerMethod method;
  final AsrMadhab madhab;
  final HighLatitude highLatitude;
  final Map<String, int> adjustments;

  static PrayerCalcSpec fallback({
    required double latitude,
    required double longitude,
  }) =>
      PrayerCalcSpec(
        latitude: latitude,
        longitude: longitude,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.shafi,
        highLatitude: HighLatitude.middleOfTheNight,
      );

  String get cacheKeyPart =>
      '${latitude.toStringAsFixed(4)}|${longitude.toStringAsFixed(4)}'
      '|${method.key}|${madhab.key}'
      '|${adjustments.entries.map((MapEntry<String, int> e) => '${e.key}:${e.value}').join(',')}';

  @override
  List<Object?> get props => <Object?>[
        latitude,
        longitude,
        method,
        madhab,
        highLatitude,
        adjustments.entries.map((MapEntry<String, int> e) => '${e.key}=${e.value}').join(','),
      ];
}

/// One computed day of prayer times.
class DayPrayerTimes extends Equatable {
  const DayPrayerTimes({
    required this.date,
    required this.times,
    required this.spec,
    required this.computedAt,
    this.verifiedDiffMinutes,
  });

  /// Local midnight of the day these times belong to.
  final DateTime date;

  final Map<PrayerName, DateTime> times;
  final PrayerCalcSpec spec;
  final DateTime computedAt;

  /// Populated by the weekly online verification (null = never verified).
  final int? verifiedDiffMinutes;

  DateTime timeOf(PrayerName name) => times[name]!;

  /// The same day with every instant moved by [minutes] — the user's manual
  /// summer/winter-time correction.
  ///
  /// [date] (the calendar key the cache is built on) and the solar computation are
  /// untouched; only the wall-clock instants move. Zero is a no-op that returns
  /// `this`, so the common path allocates nothing.
  DayPrayerTimes shifted(int minutes) {
    if (minutes == 0) return this;
    final Duration delta = Duration(minutes: minutes);
    return DayPrayerTimes(
      date: date,
      times: <PrayerName, DateTime>{
        for (final MapEntry<PrayerName, DateTime> entry in times.entries)
          entry.key: entry.value.add(delta),
      },
      spec: spec,
      computedAt: computedAt,
      verifiedDiffMinutes: verifiedDiffMinutes,
    );
  }

  /// The next prayer after [now]; null when the day is over (the caller then
  /// rolls into tomorrow's fajr).
  NextPrayer? next(DateTime now) {
    for (final PrayerName name in PrayerName.obligatory) {
      final DateTime at = times[name]!;
      if (at.isAfter(now)) {
        return NextPrayer(name: name, at: at, previous: _previousBefore(now));
      }
    }
    return null;
  }

  PrayerName? _previousBefore(DateTime now) {
    PrayerName? previous;
    for (final PrayerName name in PrayerName.obligatory) {
      if (times[name]!.isBefore(now)) previous = name;
    }
    return previous;
  }

  String cacheKey() => '${dayKey(date)}|${spec.cacheKeyPart}';

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => <Object?>[
        date,
        times.values.map((DateTime t) => t.millisecondsSinceEpoch).join(','),
        spec,
        verifiedDiffMinutes,
      ];
}

class NextPrayer extends Equatable {
  const NextPrayer({required this.name, required this.at, this.previous});

  final PrayerName name;
  final DateTime at;
  final PrayerName? previous;

  Duration remainingFrom(DateTime now) => at.difference(now);

  /// True right after the adhan: the UI highlights this window differently.
  bool isJustStarted(DateTime now) =>
      now.difference(at) < const Duration(minutes: 20);

  @override
  List<Object?> get props => <Object?>[name, at, previous];
}

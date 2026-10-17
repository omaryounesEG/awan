import 'package:isar/isar.dart';

part 'cached_prayer_day.g.dart';

/// One day of offline-computed prayer times.
///
/// Data model of `prayer_engine`: it exists so the dashboard, the monthly
/// timetable and the 30-day notification schedule can be rebuilt without
/// recomputing anything while the user waits.
@collection
class CachedPrayerDay {
  Id id = Isar.autoIncrement;

  /// `yyyy-MM-dd|lat|lon|method|madhab|adjustments` — stable, inspectable key.
  @Index(unique: true, replace: true)
  late String key;

  @Index()
  late DateTime date;

  /// fajr, sunrise, dhuhr, asr, maghrib, isha — epoch milliseconds.
  late List<int> times;

  late double latitude;
  late double longitude;
  late String method;
  late String madhab;
  late DateTime computedAt;

  /// Difference (minutes) found by the weekly online verification, if any.
  int? verifiedDiffMinutes;
}

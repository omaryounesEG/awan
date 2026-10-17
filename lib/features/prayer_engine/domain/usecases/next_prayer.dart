import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// The next adhan the user will actually hear, given a computed window.
///
/// Pulled out of the repository because the interesting part — *which* prayer is
/// next once disabled prayers, the manual summer/winter shift and "already past"
/// instants are all accounted for — is pure arithmetic over data that is already
/// in memory. The lock-screen card and any future "next prayer" label share it,
/// so they can never disagree.
///
/// Returns null when nothing in [days] is still ahead (an exhausted window is not
/// a reason to invent a time).
({PrayerName prayer, DateTime at})? nextPrayerAfter({
  required List<DayPrayerTimes> days,
  required DateTime now,
  bool Function(PrayerName prayer)? enabled,
  int shiftMinutes = 0,
}) {
  ({PrayerName prayer, DateTime at})? best;
  for (final DayPrayerTimes day in days) {
    for (final PrayerName prayer in PrayerName.obligatory) {
      if (enabled != null && !enabled(prayer)) continue;
      final DateTime at =
          day.timeOf(prayer).add(Duration(minutes: shiftMinutes));
      if (!at.isAfter(now)) continue;
      if (best == null || at.isBefore(best.at)) {
        best = (prayer: prayer, at: at);
      }
    }
  }
  return best;
}

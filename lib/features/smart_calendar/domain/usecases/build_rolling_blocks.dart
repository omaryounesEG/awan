import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// Turns prayer times into the busy blocks the calendar should carry.
///
/// This is the **rolling window** half of the architecture, and it is pure: no
/// calendar, no network, no clock of its own. Give it days and a work window and
/// it hands back the instants; the data layer is what writes them out.
///
/// Why a window and not a repeating event: a prayer moves a minute or two every
/// day, so a "recurring" event drifts away from the adhan within a week. Fourteen
/// days are cheap to write once and cheap to refresh weekly.
class BuildRollingBlocks {
  const BuildRollingBlocks();

  /// [duration] is how long the block lasts after the adhan — twenty minutes by
  /// default, which covers the jama'ah in the mosque.
  List<PrayerBlock> call({
    required Iterable<DayPrayerTimes> days,
    required Set<PrayerName> prayers,
    ClockTime workStart = const ClockTime(9, 0),
    ClockTime workEnd = const ClockTime(17, 0),
    Duration duration = const Duration(minutes: 20),
    int shiftMinutes = 0,
    DateTime? now,
  }) {
    final List<PrayerBlock> out = <PrayerBlock>[];
    for (final DayPrayerTimes day in days) {
      for (final PrayerName prayer in PrayerName.obligatory) {
        if (!prayers.contains(prayer)) continue;
        final DateTime at =
            day.timeOf(prayer).add(Duration(minutes: shiftMinutes));
        // Only the prayers that fall inside working hours are worth blocking:
        // Fajr at 4am is not a meeting anyone would book.
        final ClockTime clock = ClockTime.fromDate(at);
        if (clock.compareTo(workStart) < 0) continue;
        if (clock.compareTo(workEnd) > 0) continue;
        if (now != null && at.isBefore(now)) continue;
        out.add(
          PrayerBlock(
            key: blockKey(prayer, at),
            prayer: prayer,
            start: at,
            end: at.add(duration),
          ),
        );
      }
    }
    out.sort((PrayerBlock a, PrayerBlock b) => a.start.compareTo(b.start));
    return out;
  }

  /// `awan:<prayer>:<yyyy-mm-dd>` — stable across a re-plan on the same day, so
  /// the writer updates its own event instead of creating a twin.
  static String blockKey(PrayerName prayer, DateTime at) =>
      'awan:${prayer.key}:${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';
}

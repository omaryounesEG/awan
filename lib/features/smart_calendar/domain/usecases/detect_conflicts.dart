import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// The intersection rule from the architecture, written once and tested:
///
///     conflict = event.start < prayer.end && event.end > prayer.start
///
/// Strict inequalities on purpose — a meeting that ends exactly when the adhan
/// starts is not a conflict, and neither is one that begins exactly when the
/// block ends. Half-open intervals are how calendars are read by humans.
class DetectConflicts {
  const DetectConflicts();

  List<Conflict> call({
    required List<CalendarEvent> events,
    required List<PrayerBlock> blocks,
  }) {
    final Set<String> ourEvents = <String>{
      for (final PrayerBlock block in blocks)
        if (block.eventId != null) block.eventId!,
    };
    final List<Conflict> out = <Conflict>[];
    for (final PrayerBlock block in blocks) {
      for (final CalendarEvent event in events) {
        if (event.allDay) continue;
        if (!event.busy) continue;
        if (event.ours || ourEvents.contains(event.id)) continue;
        if (!event.overlaps(block.start, block.end)) continue;
        out.add(
          Conflict(
            event: event,
            block: block,
            suggestedStart: _nextFiveMinutes(block.end),
          ),
        );
      }
    }
    out.sort((Conflict a, Conflict b) => a.event.start.compareTo(b.event.start));
    return out;
  }

  /// A suggested time a person would say: 3:41 becomes 3:45.
  static DateTime _nextFiveMinutes(DateTime at) {
    final int remainder = at.minute % 5;
    final DateTime base = DateTime(at.year, at.month, at.day, at.hour, at.minute);
    if (remainder == 0) return base;
    return base.add(Duration(minutes: 5 - remainder));
  }
}

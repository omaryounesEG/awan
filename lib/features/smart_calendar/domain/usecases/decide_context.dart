import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// The context matrix, as three questions in a fixed order:
///
/// | in a mosque | in a meeting | what the phone does            |
/// |-------------|--------------|--------------------------------|
/// | yes         | —            | silent + a pulse on the watch  |
/// | no          | yes          | silent for the meeting only    |
/// | no          | no           | the adhan plays as usual       |
///
/// The order is the architecture's: standing in a mosque outranks a meeting —
/// a meeting that happens to be in a mosque is still a mosque.
class DecideContext {
  const DecideContext();

  ContextDecision call({
    required List<Mosque> mosques,
    required List<CalendarEvent> events,
    required DateTime now,
    int radiusMeters = 60,
  }) {
    final Mosque? at = _nearestInside(mosques, radiusMeters);
    final CalendarEvent? meeting = _meetingAt(events, now);

    if (at != null) {
      return ContextDecision(
        action: SmartContextAction.hapticSilent,
        inMosque: true,
        inMeeting: meeting != null,
        reason: (at.distanceMeters ?? 0) <= radiusMeters ~/ 2
            ? ContextReason.inMosque
            : ContextReason.atMosqueGate,
        mosque: at,
        meeting: meeting,
      );
    }
    if (meeting != null) {
      return ContextDecision(
        action: SmartContextAction.smartSilent,
        inMosque: false,
        inMeeting: true,
        reason: ContextReason.inMeeting,
        meeting: meeting,
      );
    }
    return const ContextDecision(
      action: SmartContextAction.fullAdhan,
      inMosque: false,
      inMeeting: false,
      reason: ContextReason.normal,
    );
  }

  static Mosque? _nearestInside(List<Mosque> mosques, int radiusMeters) {
    Mosque? best;
    for (final Mosque mosque in mosques) {
      final int? distance = mosque.distanceMeters;
      if (distance == null || distance > radiusMeters) continue;
      if (best == null || distance < (best.distanceMeters ?? 1 << 30)) {
        best = mosque;
      }
    }
    return best;
  }

  /// A busy, timed event whose interval contains [now].
  static CalendarEvent? _meetingAt(List<CalendarEvent> events, DateTime now) {
    for (final CalendarEvent event in events) {
      if (event.allDay || !event.busy) continue;
      if (!event.start.isAfter(now) && event.end.isAfter(now)) return event;
    }
    return null;
  }
}

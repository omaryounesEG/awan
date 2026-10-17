import 'package:equatable/equatable.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// A wall-clock time of day, without Flutter.
///
/// The domain cannot import `material.dart` (that would drag the widget layer
/// into a use case), so the work-hours window is expressed as minutes since
/// midnight, which also makes "is 12:42 inside 09:00–17:00" a plain comparison.
class ClockTime extends Equatable implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  int get minutes => hour * 60 + minute;

  static ClockTime fromDate(DateTime at) => ClockTime(at.hour, at.minute);

  static ClockTime parse(String value) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) return const ClockTime(9, 0);
    return ClockTime(
      int.tryParse(parts[0])?.clamp(0, 23) ?? 9,
      int.tryParse(parts[1])?.clamp(0, 59) ?? 0,
    );
  }

  @override
  int compareTo(ClockTime other) => minutes.compareTo(other.minutes);

  @override
  List<Object?> get props => <Object?>[hour, minute];
}

/// One event as the phone's own calendar reports it.
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.isOrganizer = false,
    this.busy = true,
    this.calendarId,
    this.note,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;

  /// An all-day event is a birthday or a trip, not a meeting: it never conflicts
  /// with a twenty-minute block.
  final bool allDay;

  /// Only the organiser is offered the "postpone" action — moving someone
  /// else's meeting is not ours to do.
  final bool isOrganizer;
  final bool busy;
  final String? calendarId;

  /// The description as the calendar stores it. Our own blocks carry
  /// `awan:block:<key>`, which is how a re-plan finds the event it wrote last
  /// time (and how the conflict detector knows to skip it).
  final String? note;

  static const String _marker = 'awan:block:';

  bool get ours => note?.startsWith(_marker) == true;

  /// `dhuhr:2026-10-17` for one of our blocks, null for anything else.
  String? get blockKey =>
      ours ? note!.substring(_marker.length) : null;

  Duration get duration => end.difference(start);

  bool overlaps(DateTime from, DateTime to) =>
      start.isBefore(to) && end.isAfter(from);

  @override
  List<Object?> get props => <Object?>[id, title, start, end, allDay];
}

/// The busy block the app wants to exist in the calendar for one prayer.
class PrayerBlock extends Equatable {
  const PrayerBlock({
    required this.key,
    required this.prayer,
    required this.start,
    required this.end,
    this.eventId,
  });

  /// Stable identity of "this prayer, this day", so a re-plan updates the event
  /// it made last time instead of stacking a second one.
  final String key;
  final PrayerName prayer;
  final DateTime start;
  final DateTime end;

  /// The calendar's own id, once the block exists there.
  final String? eventId;

  Duration get length => end.difference(start);

  PrayerBlock withEvent(String id) => PrayerBlock(
        key: key,
        prayer: prayer,
        start: start,
        end: end,
        eventId: id,
      );

  @override
  List<Object?> get props => <Object?>[key, start, end, eventId];
}

/// A meeting that sits on top of a prayer block.
class Conflict extends Equatable {
  const Conflict({
    required this.event,
    required this.block,
    required this.suggestedStart,
  });

  final CalendarEvent event;
  final PrayerBlock block;

  /// Where the meeting could move to: the end of the block, rounded up to the
  /// next five minutes — a time a human would actually say out loud.
  final DateTime suggestedStart;

  Duration get shiftBy => suggestedStart.difference(event.start);

  @override
  List<Object?> get props => <Object?>[event, block, suggestedStart];
}

/// What the phone should do at the adhan, given where and who the reader is.
enum SmartContextAction {
  /// In a mosque: the phone itself goes quiet and a watch pulses instead.
  hapticSilent,

  /// In a meeting: silence for the length of the meeting, then hand it back.
  smartSilent,

  /// Nowhere special: the adhan plays as it always does.
  fullAdhan,
}

/// Why the engine decided what it decided — the screen turns this into a
/// sentence, and the tests assert on it instead of on translated prose.
enum ContextReason { inMosque, atMosqueGate, inMeeting, normal }

class ContextDecision extends Equatable {
  const ContextDecision({
    required this.action,
    required this.inMosque,
    required this.inMeeting,
    required this.reason,
    this.mosque,
    this.meeting,
  });

  final SmartContextAction action;
  final bool inMosque;
  final bool inMeeting;

  /// Why this decision was taken, in the reader's language — the screen shows it
  /// verbatim, so "silent" is never unexplained.
  final ContextReason reason;
  final Mosque? mosque;
  final CalendarEvent? meeting;

  @override
  List<Object?> get props => <Object?>[action, inMosque, inMeeting, reason];
}

/// A mosque near the reader, from OpenStreetMap.
class Mosque extends Equatable {
  const Mosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the last fix; null before one is known.
  final int? distanceMeters;

  Mosque withDistance(int meters) => Mosque(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: meters,
      );

  @override
  List<Object?> get props => <Object?>[id, name, latitude, longitude];
}

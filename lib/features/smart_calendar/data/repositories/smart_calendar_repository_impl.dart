import 'package:awan/features/smart_calendar/data/datasources/calendar_bridge.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';
import 'package:awan/features/smart_calendar/domain/repositories/smart_calendar_repository.dart';

/// What one write pass did. `reason` is set only when nothing could be written,
/// and it is a key the screen turns into a sentence — never a bare exception.
class SyncOutcome {
  const SyncOutcome({
    this.created = 0,
    this.updated = 0,
    this.unchanged = 0,
    this.failed = 0,
    this.reason,
  });

  final int created;
  final int updated;
  final int unchanged;
  final int failed;
  final String? reason;

  bool get ok => reason == null;

  int get total => created + updated + unchanged + failed;
}

class SmartCalendarRepositoryImpl implements SmartCalendarRepository {
  SmartCalendarRepositoryImpl({CalendarBridge? bridge})
      : _bridge = bridge ?? CalendarBridge();

  final CalendarBridge _bridge;

  @override
  Future<bool> hasPermission() => _bridge.hasPermission();

  @override
  Future<bool> requestPermission() => _bridge.requestPermission();

  @override
  Future<List<CalendarEvent>> eventsBetween(DateTime from, DateTime to) =>
      _bridge.query(from, to);

  @override
  Future<String?> writableCalendarId() => _bridge.writableCalendarId();

  @override
  Future<String?> insertBlock(PrayerBlock block, {String? calendarId}) =>
      _bridge.insert(
        title: block.key,
        start: block.start,
        end: block.end,
        marker: markerOf(block),
        calendarId: calendarId,
      );

  /// `dhuhr:2026-10-17` — what goes after `awan:block:` in the description.
  static String markerOf(PrayerBlock block) => block.key.startsWith('awan:')
      ? block.key.substring('awan:'.length)
      : block.key;

  @override
  Future<bool> moveEvent(String eventId, DateTime start, DateTime end) =>
      _bridge.move(eventId, start, end);

  @override
  Future<bool> deleteEvent(String eventId) => _bridge.delete(eventId);

  @override
  Stream<void> get changes => _bridge.changes;

  /// Writes [blocks] as busy events, updating the ones a previous pass already
  /// created instead of writing a second copy.
  ///
  /// Matching is by the marker in the description, not by time: a block that
  /// moved by two minutes is the same block, and deleting/recreating it would
  /// lose anything the reader added to it.
  Future<SyncOutcome> writeBlocks(
    List<PrayerBlock> blocks, {
    String? calendarId,
    required String Function(PrayerBlock) title,
  }) async {
    if (blocks.isEmpty) return const SyncOutcome();
    if (!await _bridge.hasPermission()) {
      return const SyncOutcome(reason: 'no-permission');
    }
    final String? target = calendarId ?? await _bridge.writableCalendarId();
    if (target == null) return const SyncOutcome(reason: 'no-calendar');

    final DateTime from =
        blocks.first.start.subtract(const Duration(hours: 6));
    final DateTime to = blocks.last.end.add(const Duration(hours: 6));
    final List<CalendarEvent> existing = await _bridge.query(from, to);
    final Map<String, CalendarEvent> byKey = <String, CalendarEvent>{
      for (final CalendarEvent event in existing)
        if (event.blockKey != null) event.blockKey!: event,
    };

    int created = 0;
    int updated = 0;
    int unchanged = 0;
    int failed = 0;

    for (final PrayerBlock block in blocks) {
      final String key = markerOf(block);
      final CalendarEvent? known = byKey[key];
      if (known == null) {
        final String? id = await _bridge.insert(
          title: title(block),
          start: block.start,
          end: block.end,
          marker: key,
          calendarId: target,
        );
        if (id == null) {
          failed++;
        } else {
          created++;
        }
        continue;
      }
      final bool sameTimes = known.start.isAtSameMomentAs(block.start) &&
          known.end.isAtSameMomentAs(block.end);
      if (sameTimes) {
        unchanged++;
        continue;
      }
      final bool moved = await _bridge.move(known.id, block.start, block.end);
      if (moved) {
        updated++;
      } else {
        failed++;
      }
    }

    return SyncOutcome(
      created: created,
      updated: updated,
      unchanged: unchanged,
      failed: failed,
    );
  }

  @override
  Future<void> dispose() async {}
}

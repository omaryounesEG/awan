import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/smart_calendar/data/datasources/calendar_bridge.dart';
import 'package:awan/features/smart_calendar/data/repositories/smart_calendar_repository_impl.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// A calendar in memory: the same contract the platform channel has, so the
/// create/update/skip decisions are proven without an emulator account.
class FakeCalendar extends CalendarBridge {
  FakeCalendar({this.permitted = true, this.calendarId = 'cal-1'});

  final bool permitted;
  final String? calendarId;
  final List<CalendarEvent> events = <CalendarEvent>[];
  final List<String> moves = <String>[];
  int _nextId = 1;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<String?> writableCalendarId() async => calendarId;

  @override
  Future<List<CalendarEvent>> query(DateTime from, DateTime to) async =>
      events
          .where((CalendarEvent e) => e.start.isBefore(to) && e.end.isAfter(from))
          .toList();

  @override
  Future<String?> insert({
    required String title,
    required DateTime start,
    required DateTime end,
    required String marker,
    String? calendarId,
  }) async {
    final String id = 'ev-${_nextId++}';
    events.add(CalendarEvent(
      id: id,
      title: title,
      start: start,
      end: end,
      note: 'awan:block:$marker',
      calendarId: calendarId,
    ));
    return id;
  }

  @override
  Future<bool> move(String id, DateTime start, DateTime end) async {
    final int index = events.indexWhere((CalendarEvent e) => e.id == id);
    if (index < 0) return false;
    moves.add(id);
    final CalendarEvent old = events[index];
    events[index] = CalendarEvent(
      id: old.id,
      title: old.title,
      start: start,
      end: end,
      note: old.note,
      calendarId: old.calendarId,
    );
    return true;
  }
}

void main() {
  PrayerBlock block(int hour, int minute, {int minutes = 20}) => PrayerBlock(
        key: 'awan:dhuhr:2026-10-17',
        prayer: PrayerName.dhuhr,
        start: DateTime(2026, 10, 17, hour, minute),
        end: DateTime(2026, 10, 17, hour, minute + minutes),
      );

  test('the first write creates one event per block', () async {
    final FakeCalendar calendar = FakeCalendar();
    final SmartCalendarRepositoryImpl repository =
        SmartCalendarRepositoryImpl(bridge: calendar);

    final SyncOutcome outcome = await repository.writeBlocks(
      <PrayerBlock>[block(12, 42), block(15, 59)],
      title: (PrayerBlock b) => 'أذان',
    );

    expect(outcome.ok, isTrue);
    expect(outcome.created, 2);
    expect(calendar.events.length, 2);
    expect(calendar.events.first.note, 'awan:block:dhuhr:2026-10-17');
  });

  test('a second run changes nothing when the times did not move', () async {
    final FakeCalendar calendar = FakeCalendar();
    final SmartCalendarRepositoryImpl repository =
        SmartCalendarRepositoryImpl(bridge: calendar);
    await repository.writeBlocks(
      <PrayerBlock>[block(12, 42)],
      title: (PrayerBlock b) => 'أذان',
    );

    final SyncOutcome again = await repository.writeBlocks(
      <PrayerBlock>[block(12, 42)],
      title: (PrayerBlock b) => 'أذان',
    );

    expect(again.created, 0);
    expect(again.updated, 0);
    expect(again.unchanged, 1);
    expect(calendar.events.length, 1);
  });

  test('a moved adhan updates the existing event instead of duplicating it',
      () async {
    final FakeCalendar calendar = FakeCalendar();
    final SmartCalendarRepositoryImpl repository =
        SmartCalendarRepositoryImpl(bridge: calendar);
    await repository.writeBlocks(
      <PrayerBlock>[block(12, 42)],
      title: (PrayerBlock b) => 'أذان',
    );

    final SyncOutcome moved = await repository.writeBlocks(
      <PrayerBlock>[block(12, 47)],
      title: (PrayerBlock b) => 'أذان',
    );

    expect(moved.updated, 1);
    expect(calendar.events.length, 1);
    expect(calendar.events.single.start, DateTime(2026, 10, 17, 12, 47));
  });

  test('without a permission or a writable calendar the write is refused, not faked',
      () async {
    final SmartCalendarRepositoryImpl denied =
        SmartCalendarRepositoryImpl(bridge: FakeCalendar(permitted: false));
    expect(
      (await denied.writeBlocks(<PrayerBlock>[block(12, 42)],
              title: (PrayerBlock b) => 'x'))
          .reason,
      'no-permission',
    );

    final SmartCalendarRepositoryImpl noCalendar =
        SmartCalendarRepositoryImpl(bridge: FakeCalendar(calendarId: null));
    expect(
      (await noCalendar.writeBlocks(<PrayerBlock>[block(12, 42)],
              title: (PrayerBlock b) => 'x'))
          .reason,
      'no-calendar',
    );
  });

  test('a conflict suggestion moves the meeting past the block', () async {
    final FakeCalendar calendar = FakeCalendar();
    calendar.events.add(CalendarEvent(
      id: 'ev-99',
      title: 'review',
      start: DateTime(2026, 10, 17, 12, 30),
      end: DateTime(2026, 10, 17, 13, 0),
    ));
    final SmartCalendarRepositoryImpl repository =
        SmartCalendarRepositoryImpl(bridge: calendar);

    final bool moved = await repository.moveEvent(
      'ev-99',
      DateTime(2026, 10, 17, 13, 5),
      DateTime(2026, 10, 17, 13, 35),
    );

    expect(moved, isTrue);
    expect(calendar.moves, <String>['ev-99']);
    expect(calendar.events.single.start, DateTime(2026, 10, 17, 13, 5));
  });
}

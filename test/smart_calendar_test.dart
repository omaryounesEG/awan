import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';
import 'package:awan/features/smart_calendar/domain/usecases/build_rolling_blocks.dart';
import 'package:awan/features/smart_calendar/domain/usecases/decide_context.dart';
import 'package:awan/features/smart_calendar/domain/usecases/detect_conflicts.dart';

const PrayerCalcSpec _spec = PrayerCalcSpec(
  latitude: 30.0444,
  longitude: 31.2357,
  method: PrayerMethod.egyptian,
  madhab: AsrMadhab.shafi,
  highLatitude: HighLatitude.middleOfTheNight,
);

DayPrayerTimes _day(DateTime date) {
  DateTime at(int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);
  return DayPrayerTimes(
    date: DateTime(date.year, date.month, date.day),
    times: <PrayerName, DateTime>{
      PrayerName.fajr: at(4, 40),
      PrayerName.sunrise: at(6, 5),
      PrayerName.dhuhr: at(12, 42),
      PrayerName.asr: at(15, 59),
      PrayerName.maghrib: at(18, 28),
      PrayerName.isha: at(19, 46),
    },
    spec: _spec,
    computedAt: date,
  );
}

void main() {
  group('the rolling window', () {
    const BuildRollingBlocks build = BuildRollingBlocks();
    final DateTime today = DateTime(2026, 10, 17);

    test('writes only the prayers inside working hours', () {
      final List<PrayerBlock> blocks = build(
        days: <DayPrayerTimes>[_day(today)],
        prayers: <PrayerName>{...PrayerName.obligatory},
        workStart: const ClockTime(9, 0),
        workEnd: const ClockTime(17, 0),
      );
      expect(
        blocks.map((PrayerBlock b) => b.prayer),
        <PrayerName>[PrayerName.dhuhr, PrayerName.asr],
        reason: 'Fajr and Isha are outside 09:00–17:00, and so is Maghrib',
      );
    });

    test('a block lasts exactly as long as the reader asked', () {
      final List<PrayerBlock> blocks = build(
        days: <DayPrayerTimes>[_day(today)],
        prayers: <PrayerName>{PrayerName.dhuhr},
        duration: const Duration(minutes: 25),
      );
      expect(blocks.single.length, const Duration(minutes: 25));
      expect(blocks.single.start, DateTime(2026, 10, 17, 12, 42));
    });

    test('the key survives a re-plan on the same day', () {
      final List<PrayerBlock> first = build(
        days: <DayPrayerTimes>[_day(today)],
        prayers: <PrayerName>{PrayerName.dhuhr},
      );
      final List<PrayerBlock> second = build(
        days: <DayPrayerTimes>[_day(today)],
        prayers: <PrayerName>{PrayerName.dhuhr},
        duration: const Duration(minutes: 30),
      );
      expect(first.single.key, second.single.key);
      expect(first.single.key, 'awan:dhuhr:2026-10-17');
    });

    test('never writes a block for an instant that has already passed', () {
      final List<PrayerBlock> blocks = build(
        days: <DayPrayerTimes>[_day(today)],
        prayers: <PrayerName>{...PrayerName.obligatory},
        workStart: const ClockTime(0, 0),
        workEnd: const ClockTime(23, 59),
        now: DateTime(2026, 10, 17, 15, 0),
      );
      expect(
        blocks.every((PrayerBlock b) => b.start.isAfter(DateTime(2026, 10, 17, 15, 0))),
        isTrue,
      );
    });
  });

  group('the intersection rule', () {
    const DetectConflicts detect = DetectConflicts();
    final PrayerBlock block = PrayerBlock(
      key: 'awan:dhuhr:2026-10-17',
      prayer: PrayerName.dhuhr,
      start: DateTime(2026, 10, 17, 12, 42),
      end: DateTime(2026, 10, 17, 13, 2),
    );

    CalendarEvent event(String id, int fromH, int fromM, int toH, int toM) =>
        CalendarEvent(
          id: id,
          title: 'review',
          start: DateTime(2026, 10, 17, fromH, fromM),
          end: DateTime(2026, 10, 17, toH, toM),
        );

    test('a meeting that runs through the adhan is a conflict', () {
      expect(detect(events: <CalendarEvent>[event('1', 12, 30, 13, 0)], blocks: <PrayerBlock>[block]).length, 1);
    });

    test('touching intervals are not a conflict', () {
      // Ends exactly at the adhan.
      expect(detect(events: <CalendarEvent>[event('1', 12, 0, 12, 42)], blocks: <PrayerBlock>[block]), isEmpty);
      // Starts exactly when the block ends.
      expect(detect(events: <CalendarEvent>[event('2', 13, 2, 14, 0)], blocks: <PrayerBlock>[block]), isEmpty);
    });

    test('all-day events and our own blocks are ignored', () {
      expect(
        detect(
          events: <CalendarEvent>[
            CalendarEvent(
              id: '3',
              title: 'birthday',
              start: DateTime(2026, 10, 17),
              end: DateTime(2026, 10, 18),
              allDay: true,
            ),
            CalendarEvent(
              id: '4',
              title: 'adhan',
              start: DateTime(2026, 10, 17, 12, 42),
              end: DateTime(2026, 10, 17, 13, 2),
              note: 'awan:block:dhuhr:2026-10-17',
            ),
          ],
          blocks: <PrayerBlock>[block],
        ),
        isEmpty,
      );
    });

    test('the suggestion is the end of the block, rounded up to five minutes', () {
      final List<Conflict> out = detect(
        events: <CalendarEvent>[event('1', 12, 30, 13, 0)],
        blocks: <PrayerBlock>[block],
      );
      expect(out.single.suggestedStart, DateTime(2026, 10, 17, 13, 5));
    });
  });

  group('the context matrix', () {
    const DecideContext decide = DecideContext();
    final DateTime now = DateTime(2026, 10, 17, 12, 42);

    Mosque mosque(int meters) => Mosque(
          id: 'node/1',
          name: 'مسجد النور',
          latitude: 30.0444,
          longitude: 31.2357,
          distanceMeters: meters,
        );

    test('standing in a mosque beats everything', () {
      final ContextDecision decision = decide(
        mosques: <Mosque>[mosque(20)],
        events: <CalendarEvent>[
          CalendarEvent(
            id: '1',
            title: 'meeting',
            start: DateTime(2026, 10, 17, 12, 0),
            end: DateTime(2026, 10, 17, 13, 0),
          ),
        ],
        now: now,
      );
      expect(decision.action, SmartContextAction.hapticSilent);
      expect(decision.inMosque, isTrue);
      expect(decision.reason, ContextReason.inMosque);
    });

    test('outside the radius the mosque does not count', () {
      final ContextDecision decision = decide(
        mosques: <Mosque>[mosque(61)],
        events: const <CalendarEvent>[],
        now: now,
        radiusMeters: 60,
      );
      expect(decision.action, SmartContextAction.fullAdhan);
    });

    test('a running meeting is silenced, and the end is not', () {
      final CalendarEvent meeting = CalendarEvent(
        id: '1',
        title: 'review',
        start: DateTime(2026, 10, 17, 12, 0),
        end: DateTime(2026, 10, 17, 13, 0),
      );
      expect(
        decide(mosques: const <Mosque>[], events: <CalendarEvent>[meeting], now: now).action,
        SmartContextAction.smartSilent,
      );
      expect(
        decide(
          mosques: const <Mosque>[],
          events: <CalendarEvent>[meeting],
          now: DateTime(2026, 10, 17, 13, 0),
        ).action,
        SmartContextAction.fullAdhan,
      );
    });
  });
}

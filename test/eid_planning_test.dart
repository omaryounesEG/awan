import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/usecases/eid_planning.dart';

/// The Eid takbir is the one alert that cannot be discovered from a month of
/// prayers, so its dates are pinned here: 1 Shawwal and 10 Dhu al-Hijjah, at
/// sunrise minus twenty-five minutes, never in the past.
void main() {
  ({String title, String body}) text(EidKind kind, DateTime at) =>
      (title: kind.name, body: at.toIso8601String());

  final DateTime sunrise = DateTime(2026, 3, 20, 6, 0);
  DateTime sunriseOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, 6, 0);

  test('al-Fitr 1447 lands on the morning of 20 March 2026', () {
    final List<EidMoment> moments = planEidMoments(
      now: DateTime(2026, 1, 5),
      hijriOffsetDays: 0,
      sunriseOf: sunriseOf,
      shiftMinutes: 0,
      build: text,
    );
    expect(moments, isNotEmpty);
    expect(moments.first.kind, EidKind.fitr);
    expect(moments.first.at, DateTime(2026, 3, 20, 5, 35));
    expect(moments[1].kind, EidKind.adha);
  });

  test('the takbir is twenty-five minutes before sunrise, not five', () {
    final List<EidMoment> moments = planEidMoments(
      now: DateTime(2026, 3, 19),
      hijriOffsetDays: 0,
      sunriseOf: sunriseOf,
      shiftMinutes: 0,
      build: text,
    );
    expect(moments.first.at, sunrise.subtract(const Duration(minutes: 25)));
  });

  test('a day already gone is skipped, so no alarm fires into the past', () {
    final List<EidMoment> moments = planEidMoments(
      now: DateTime(2026, 3, 20, 9, 0),
      hijriOffsetDays: 0,
      sunriseOf: sunriseOf,
      shiftMinutes: 0,
      build: text,
    );
    expect(moments.first.kind, EidKind.adha);
  });

  test('the reader’s Hijri offset moves the takbir with the printed date', () {
    final List<EidMoment> moments = planEidMoments(
      now: DateTime(2026, 1, 5),
      hijriOffsetDays: 1,
      sunriseOf: sunriseOf,
      shiftMinutes: 0,
      build: text,
    );
    // One day earlier in Gregorian terms, because the calendar was read a day
    // ahead — the same shift the home card shows.
    expect(moments.first.at, DateTime(2026, 3, 19, 5, 35));
  });
}

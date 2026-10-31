import 'package:hijri/hijri_calendar.dart';

import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';

/// When the takbir of an Eid should ring.
///
/// The two Eids are the only days the `takbirat` clip exists, and they are lunar:
/// a fixed monthly plan can never reach them, so they are planned a year ahead on
/// every schedule refresh. The date comes from the same Hijri conversion the home
/// card prints (offset included) — a takbir a day off the Eid the reader sees
/// would be worse than no takbir at all.
List<EidMoment> planEidMoments({
  required DateTime now,
  required int hijriOffsetDays,
  required DateTime Function(DateTime day) sunriseOf,
  required int shiftMinutes,
  required EidTextBuilder build,
  int horizonDays = 420,
  int limit = 4,
}) {
  final List<EidMoment> moments = <EidMoment>[];
  for (int offset = 0; offset < horizonDays && moments.length < limit; offset++) {
    final DateTime date = DateTime(now.year, now.month, now.day + offset);
    final HijriCalendar hijri = HijriCalendar.fromDate(
      DateTime(date.year, date.month, date.day + hijriOffsetDays),
    );
    final EidKind? kind = hijri.hMonth == 10 && hijri.hDay == 1
        ? EidKind.fitr
        : hijri.hMonth == 12 && hijri.hDay == 10
            ? EidKind.adha
            : null;
    if (kind == null) continue;

    final DateTime at = sunriseOf(date)
        .subtract(const Duration(minutes: 25))
        .add(Duration(minutes: shiftMinutes));
    if (!at.isAfter(now)) continue;

    final ({String title, String body}) text = build(kind, at);
    moments.add(EidMoment(kind: kind, at: at, title: text.title, body: text.body));
  }
  return moments;
}

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// A pre-prayer reminder that is due on screen **right now**.
class PrePrayerDue {
  const PrePrayerDue({
    required this.prayer,
    required this.at,
    required this.minutesLeft,
    required this.key,
  });

  final PrayerName prayer;

  /// The prayer instant itself — the reminder disappears when it arrives.
  final DateTime at;

  /// Whole minutes until [at]; never negative.
  final int minutesLeft;

  /// Stable identity of this occurrence (`asr:2026-10-10T15:45:00.000`).
  ///
  /// Dismissal is remembered per occurrence, so waving the hourglass away at
  /// 15:31 does not silence tomorrow's Asr reminder — and it does not come back
  /// two minutes later either.
  final String key;
}

/// Decides whether the hourglass belongs on screen, and for which prayer.
///
/// Pure on purpose: the whole rule — "inside the window, before the prayer, not
/// already dismissed" — is testable without a clock, a widget or Android. It
/// takes the same map the screens render, so the card and the timetable can
/// never disagree about what time Asr is.
///
/// Windows do not overlap in practice (prayers are hours apart), but the loop
/// still returns the *earliest* due prayer rather than assuming it.
PrePrayerDue? duePrePrayer({
  required Map<PrayerName, DateTime> times,
  required DateTime now,
  required int minutes,
  required bool enabled,
  Set<String> dismissed = const <String>{},
}) {
  if (!enabled || minutes <= 0) return null;

  PrePrayerDue? due;
  for (final PrayerName prayer in PrayerName.obligatory) {
    final DateTime? at = times[prayer];
    if (at == null) continue;

    final DateTime windowOpens = at.subtract(Duration(minutes: minutes));
    // Strictly inside the window. Closing at the prayer instant is what makes
    // the card leave on its own when the adhan arrives.
    if (now.isBefore(windowOpens) || !now.isBefore(at)) continue;

    final String key = '${prayer.key}:${at.toIso8601String()}';
    if (dismissed.contains(key)) continue;

    final int left = at.difference(now).inMinutes;
    final PrePrayerDue candidate = PrePrayerDue(
      prayer: prayer,
      at: at,
      minutesLeft: left < 0 ? 0 : left,
      key: key,
    );
    if (due == null || candidate.at.isBefore(due.at)) due = candidate;
  }
  return due;
}

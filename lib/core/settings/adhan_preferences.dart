import 'dart:convert';

import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';

/// What each adhan is allowed to do, and when the ringer goes quiet around it.
///
/// Per prayer, because one setting for all five is the wrong shape: Fajr at
/// 4am, Dhuhr at noon and Isha at 8pm are not the same event in a household.
/// One value object, one preference key, and a decoder that never throws — a
/// hand-edited or half-written string must not take the app down.
class AdhanPreferences {
  const AdhanPreferences({
    this.alertModes = const <String, int>{},
    this.silentStartMinutes = const <String, int>{},
    this.silentMinutes = const <String, int>{},
  });

  /// How the alert sounds, per prayer id ('fajr' … 'isha').
  final Map<String, int> alertModes;

  /// Minutes **after** the adhan when the ringer goes silent (0 = at the adhan).
  final Map<String, int> silentStartMinutes;

  /// How long the silence lasts, per prayer, in minutes.
  final Map<String, int> silentMinutes;

  static const int defaultSilentStartMinutes = 0;
  static const int defaultSilentMinutes = 15;

  /// The choices the settings screen offers; anything else in the map is ignored
  /// when it is read, so a stale value can never produce a strange window.
  static const List<int> silentStartChoices = <int>[0, 5, 10, 15, 20, 25];
  static const List<int> silentMinutesChoices = <int>[5, 10, 15, 20];

  AdhanAlertMode alertModeFor(String prayerId) =>
      AdhanAlertMode.fromWire(alertModes[prayerId]);

  int silentStartFor(String prayerId) =>
      silentStartMinutes[prayerId] ?? defaultSilentStartMinutes;

  int silentDurationFor(String prayerId) =>
      silentMinutes[prayerId] ?? defaultSilentMinutes;

  AdhanPreferences withAlertMode(String prayerId, AdhanAlertMode mode) =>
      AdhanPreferences(
        alertModes: <String, int>{...alertModes, prayerId: mode.wireValue},
        silentStartMinutes: silentStartMinutes,
        silentMinutes: silentMinutes,
      );

  AdhanPreferences withSilentWindow(
    String prayerId, {
    int? startMinutes,
    int? minutes,
  }) =>
      AdhanPreferences(
        alertModes: alertModes,
        silentStartMinutes: startMinutes == null
            ? silentStartMinutes
            : <String, int>{...silentStartMinutes, prayerId: startMinutes},
        silentMinutes: minutes == null
            ? silentMinutes
            : <String, int>{...silentMinutes, prayerId: minutes},
      );

  String encode() => jsonEncode(<String, Object?>{
        'alert': alertModes,
        'start': silentStartMinutes,
        'duration': silentMinutes,
      });

  factory AdhanPreferences.decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const AdhanPreferences();
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const AdhanPreferences();
      }
      return AdhanPreferences(
        alertModes: _intMap(decoded['alert']),
        silentStartMinutes: _intMap(decoded['start']),
        silentMinutes: _intMap(decoded['duration']),
      );
    } catch (_) {
      return const AdhanPreferences();
    }
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const <String, int>{};
    }
    final Map<String, int> out = <String, int>{};
    value.forEach((Object? key, Object? raw) {
      if (key is String && raw is num) {
        out[key] = raw.toInt();
      }
    });
    return out;
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';

/// One day's two sittings, as raw counters.
class AdhkarDayCounts {
  const AdhkarDayCounts({
    this.morning = const <int, int>{},
    this.evening = const <int, int>{},
  });

  final Map<int, int> morning;
  final Map<int, int> evening;

  Map<int, int> forSession(AdhkarSession session) =>
      session == AdhkarSession.morning ? morning : evening;

  Map<String, Object?> toJson() => <String, Object?>{
        'morning': morning.map((int k, int v) => MapEntry<String, Object?>('$k', v)),
        'evening': evening.map((int k, int v) => MapEntry<String, Object?>('$k', v)),
      };

  static AdhkarDayCounts fromJson(Object? raw) {
    if (raw is! Map) return const AdhkarDayCounts();
    Map<int, int> counts(Object? value) {
      if (value is! Map) return <int, int>{};
      final Map<int, int> out = <int, int>{};
      value.forEach((Object? k, Object? v) {
        final int? id = int.tryParse('$k');
        if (id != null && v is num) out[id] = v.toInt();
      });
      return out;
    }

    return AdhkarDayCounts(
      morning: counts(raw['morning']),
      evening: counts(raw['evening']),
    );
  }
}

/// The reader's progress, day by day.
///
/// Deliberately a plain JSON map in `SharedPreferences`: a year of two sittings
/// is a few kilobytes, it is read once per screen, and it survives an app update
/// without a schema migration. The month report is derived, never stored — one
/// source of truth.
class AdhkarProgressStore {
  AdhkarProgressStore({SharedPreferences? preferences}) : _given = preferences;

  static const String _key = 'adhkar_progress_v1';

  final SharedPreferences? _given;
  SharedPreferences? _cached;

  Future<SharedPreferences> get _prefs async =>
      _cached ??= _given ?? await SharedPreferences.getInstance();

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  Future<Map<String, AdhkarDayCounts>> readAll() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, AdhkarDayCounts>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, AdhkarDayCounts>{};
      return <String, AdhkarDayCounts>{
        for (final MapEntry<Object?, Object?> e in decoded.entries)
          '${e.key}': AdhkarDayCounts.fromJson(e.value),
      };
    } on FormatException {
      return <String, AdhkarDayCounts>{};
    }
  }

  Future<Map<int, int>> countsFor(DateTime day, AdhkarSession session) async {
    final Map<String, AdhkarDayCounts> all = await readAll();
    return all[dayKey(day)]?.forSession(session) ?? const <int, int>{};
  }

  /// Adds one to a dhikr's counter and returns the new value.
  Future<int> increment(
    DateTime day,
    AdhkarSession session,
    AdhkarItem item,
  ) async {
    final Map<String, AdhkarDayCounts> all = await readAll();
    final String key = dayKey(day);
    final AdhkarDayCounts today = all[key] ?? const AdhkarDayCounts();
    final Map<int, int> target = <int, int>{
      ...today.forSession(session),
    };
    final int next = ((target[item.id] ?? 0) + 1).clamp(0, item.repeat);
    target[item.id] = next;
    all[key] = AdhkarDayCounts(
      morning: session == AdhkarSession.morning ? target : today.morning,
      evening: session == AdhkarSession.evening ? target : today.evening,
    );
    await _write(all);
    return next;
  }

  /// Marks a dhikr finished in one tap (the repeat count reached).
  Future<void> complete(
    DateTime day,
    AdhkarSession session,
    AdhkarItem item,
  ) async {
    final Map<String, AdhkarDayCounts> all = await readAll();
    final String key = dayKey(day);
    final AdhkarDayCounts today = all[key] ?? const AdhkarDayCounts();
    final Map<int, int> target = <int, int>{
      ...today.forSession(session),
      item.id: item.repeat,
    };
    all[key] = AdhkarDayCounts(
      morning: session == AdhkarSession.morning ? target : today.morning,
      evening: session == AdhkarSession.evening ? target : today.evening,
    );
    await _write(all);
  }

  Future<void> resetItem(
    DateTime day,
    AdhkarSession session,
    int itemId,
  ) async {
    final Map<String, AdhkarDayCounts> all = await readAll();
    final String key = dayKey(day);
    final AdhkarDayCounts today = all[key] ?? const AdhkarDayCounts();
    final Map<int, int> target = <int, int>{...today.forSession(session)}
      ..remove(itemId);
    all[key] = AdhkarDayCounts(
      morning: session == AdhkarSession.morning ? target : today.morning,
      evening: session == AdhkarSession.evening ? target : today.evening,
    );
    await _write(all);
  }

  Future<void> resetSession(DateTime day, AdhkarSession session) async {
    final Map<String, AdhkarDayCounts> all = await readAll();
    final String key = dayKey(day);
    final AdhkarDayCounts today = all[key] ?? const AdhkarDayCounts();
    all[key] = AdhkarDayCounts(
      morning: session == AdhkarSession.morning
          ? const <int, int>{}
          : today.morning,
      evening: session == AdhkarSession.evening
          ? const <int, int>{}
          : today.evening,
    );
    await _write(all);
  }

  Future<void> _write(Map<String, AdhkarDayCounts> all) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _key,
      jsonEncode(<String, Object?>{
        for (final MapEntry<String, AdhkarDayCounts> e in all.entries)
          e.key: e.value.toJson(),
      }),
    );
  }
}

/// How far a sitting got: items done, total items, and the share.
class AdhkarSessionProgress {
  const AdhkarSessionProgress({
    required this.doneItems,
    required this.totalItems,
    required this.counts,
  });

  final int doneItems;
  final int totalItems;
  final Map<int, int> counts;

  double get ratio => totalItems == 0 ? 0 : doneItems / totalItems;
  bool get finished => totalItems > 0 && doneItems == totalItems;

  static AdhkarSessionProgress of(
    List<AdhkarItem> items,
    Map<int, int> counts,
  ) {
    int done = 0;
    for (final AdhkarItem item in items) {
      if ((counts[item.id] ?? 0) >= item.repeat) done++;
    }
    return AdhkarSessionProgress(
      doneItems: done,
      totalItems: items.length,
      counts: counts,
    );
  }
}

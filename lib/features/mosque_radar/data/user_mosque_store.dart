import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';

/// Where the reader's own mosques live.
///
/// Deliberately in `SharedPreferences` and not Isar: this is a handful of
/// records that are read on every radar open and never queried, so a JSON list
/// costs one string read and needs no schema, no codegen and no migration. The
/// religious *content* lives in Isar; a personal pin does not need a database.
class UserMosqueStore {
  UserMosqueStore({SharedPreferences? preferences}) : _given = preferences;

  static const String _key = 'user_mosques_v1';

  final SharedPreferences? _given;
  SharedPreferences? _cached;

  Future<SharedPreferences> get _prefs async =>
      _cached ??= _given ?? await SharedPreferences.getInstance();

  Future<List<UserMosque>> list() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <UserMosque>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <UserMosque>[];
      return decoded
          .map(UserMosque.fromJson)
          .whereType<UserMosque>()
          .toList(growable: false);
    } on FormatException {
      // A corrupt blob is a miss, not a crash: the next add overwrites it.
      return const <UserMosque>[];
    }
  }

  Future<void> save(List<UserMosque> mosques) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _key,
      jsonEncode(mosques.map((UserMosque m) => m.toJson()).toList()),
    );
  }

  Future<List<UserMosque>> add(UserMosque mosque) async {
    final List<UserMosque> all = await list();
    // One pin per place: standing in the same mosque twice must not grow the
    // list, and a renamed pin replaces the old one.
    final List<UserMosque> next = <UserMosque>[
      ...all.where((UserMosque m) {
        final bool sameLat = (m.latitude - mosque.latitude).abs() < 1e-5;
        final bool sameLng = (m.longitude - mosque.longitude).abs() < 1e-5;
        return !(sameLat && sameLng);
      }),
      mosque,
    ];
    await save(next);
    return next;
  }

  /// Returns the list after removal, and whether anything was removed.
  Future<(List<UserMosque>, bool)> remove(String id) async {
    final List<UserMosque> all = await list();
    final List<UserMosque> next =
        all.where((UserMosque m) => m.id != id).toList(growable: false);
    if (next.length == all.length) return (all, false);
    await save(next);
    return (next, true);
  }
}

import 'package:isar/isar.dart';

import 'package:awan/features/mosque_radar/data/models/mosque_cache_entry.dart';

/// The radar's storage, behind an interface.
///
/// Why an interface for one table: the cache *rule* (`MosqueCachePolicy`) and the
/// repository's decision order are the parts worth testing — they are pure logic
/// and run in milliseconds — while `Isar` needs a native library that a host test
/// does not have. With this seam the rule is covered by unit tests and the Isar
/// adapter is a thin, obvious translation.
abstract class MosqueCacheStore {
  /// Rows whose `cellKey` is one of [cellKeys] (the 3x3 neighbourhood).
  Future<List<MosqueCacheEntry>> candidates(List<String> cellKeys);

  Future<void> put(MosqueCacheEntry entry);

  /// Drops everything older than [cutoff] so the table cannot grow forever.
  Future<void> pruneBefore(DateTime cutoff);
}

/// The real one: one indexed read per cell key, written in a single transaction.
class IsarMosqueCacheStore implements MosqueCacheStore {
  const IsarMosqueCacheStore(this._isar);

  final Isar _isar;

  @override
  Future<List<MosqueCacheEntry>> candidates(List<String> cellKeys) async {
    final IsarCollection<MosqueCacheEntry> collection =
        _isar.collection<MosqueCacheEntry>();

    final List<MosqueCacheEntry> found = <MosqueCacheEntry>[];
    for (final String key in cellKeys) {
      final MosqueCacheEntry? hit =
          await collection.where().cellKeyEqualTo(key).findFirst();
      if (hit != null) found.add(hit);
    }
    return found;
  }

  @override
  Future<void> put(MosqueCacheEntry entry) async {
    final IsarCollection<MosqueCacheEntry> collection =
        _isar.collection<MosqueCacheEntry>();

    // Reuse the row id when this cell was cached before: `cellKey` is unique, so
    // inserting a second row for the same cell would be a constraint violation
    // rather than an update.
    final MosqueCacheEntry? existing =
        await collection.where().cellKeyEqualTo(entry.cellKey).findFirst();
    entry.id = existing?.id ?? Isar.autoIncrement;

    await collection.put(entry);
  }

  @override
  Future<void> pruneBefore(DateTime cutoff) async {
    await _isar
        .collection<MosqueCacheEntry>()
        .filter()
        .fetchedAtLessThan(cutoff)
        .deleteAll();
  }
}

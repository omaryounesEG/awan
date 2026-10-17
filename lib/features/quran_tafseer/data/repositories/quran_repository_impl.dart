import 'package:isar/isar.dart';

import 'package:awan/features/quran_tafseer/domain/usecases/search_quran.dart';
import 'package:awan/features/quran_tafseer/data/datasources/quran_asset_datasource.dart';
import 'package:awan/features/quran_tafseer/data/models/quran_mark.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/domain/repositories/quran_repository.dart';

/// The `kind` column of a [QuranMark] row.
///
/// One column, three meanings, because they all answer "which verse did the user
/// care about": a named bookmark, the single stop marker, and the newest resume
/// point. Keeping them in one collection means one schema and one write path.
class MarkKind {
  const MarkKind._();

  static const String bookmark = 'bookmark';
  static const String stop = 'stop';
  static const String lastRead = 'lastRead';
}

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    required QuranLocalDataSource local,
    required Isar isar,
  })  : _local = local,
        _isar = isar;

  final QuranLocalDataSource _local;
  final Isar _isar;

  /// The normalised corpus, built on the first search and then reused.
  ///
  /// Normalising 6,236 verses on every keystroke would be wasteful; the searchable
  /// form is derived once per process (~0.5 MB) and thrown away with the isolate.
  QuranHaystack? _haystack;

  @override
  Future<QuranText> text() => _local.load();

  @override
  Future<MushafIndex> index() => _local.loadIndex();

  @override
  Future<TafsirText> tafsir(int id) => _local.loadTafsir(id);

  // ------------------------------------------------------------------ search
  @override
  Future<List<QuranSearchHit>> search(String query, {int limit = 60}) async {
    final QuranHaystack haystack = _haystack ??= QuranHaystack(await text());
    return haystack.search(query, limit: limit);
  }

  // --------------------------------------------------------------- bookmarks
  @override
  Future<List<BookmarkedAyah>> bookmarks() async {
    final QuranText text = await this.text();
    final List<QuranMark> rows = await _isar
        .collection<QuranMark>()
        .filter()
        .kindEqualTo(MarkKind.bookmark)
        .sortByCreatedAtDesc()
        .findAll();

    return <BookmarkedAyah>[
      for (final QuranMark row in rows)
        BookmarkedAyah(
          id: row.id,
          surah: row.surah,
          surahName: text.surah(row.surah).nameAr,
          ayah: row.ayah,
          text: text.ayah(row.surah, row.ayah)?.text ?? '',
          createdAt: row.createdAt,
          note: row.note,
        ),
    ];
  }

  @override
  Future<void> addBookmark(AyahRef ref, {String? note}) async {
    final IsarCollection<QuranMark> collection = _isar.collection<QuranMark>();
    final QuranMark? existing = await collection
        .filter()
        .kindEqualTo(MarkKind.bookmark)
        .and()
        .surahEqualTo(ref.surah)
        .and()
        .ayahEqualTo(ref.ayah)
        .findFirst();

    final QuranMark mark = existing ?? (QuranMark()
      ..surah = ref.surah
      ..ayah = ref.ayah
      ..kind = MarkKind.bookmark
      ..createdAt = DateTime.now());
    // Saving the same verse again is how a note is edited — never a second row.
    mark.note = note;

    await _isar.writeTxn(() => collection.put(mark));
  }

  @override
  Future<void> removeBookmark(AyahRef ref) async {
    final IsarCollection<QuranMark> collection = _isar.collection<QuranMark>();
    await _isar.writeTxn(
      () => collection
          .filter()
          .kindEqualTo(MarkKind.bookmark)
          .and()
          .surahEqualTo(ref.surah)
          .and()
          .ayahEqualTo(ref.ayah)
          .deleteAll(),
    );
  }

  @override
  Future<bool> isBookmarked(AyahRef ref) async {
    final QuranMark? row = await _isar
        .collection<QuranMark>()
        .filter()
        .kindEqualTo(MarkKind.bookmark)
        .and()
        .surahEqualTo(ref.surah)
        .and()
        .ayahEqualTo(ref.ayah)
        .findFirst();
    return row != null;
  }

  // -------------------------------------------------------------- stop marker
  @override
  Future<AyahRef?> stopMark() => _single(MarkKind.stop);

  @override
  Future<void> setStopMark(AyahRef ref) => _replaceSingle(MarkKind.stop, ref);

  @override
  Future<void> clearStopMark() => _clear(MarkKind.stop);

  // ------------------------------------------------------------- resume point
  @override
  Future<AyahRef?> lastRead() async {
    final ReadingPosition? row = await _isar
        .collection<ReadingPosition>()
        .where()
        .sortByUpdatedAtDesc()
        .findFirst();
    return row == null ? null : AyahRef(row.surah, row.ayah);
  }

  @override
  Future<void> saveLastRead(AyahRef ref) async {
    final IsarCollection<ReadingPosition> collection =
        _isar.collection<ReadingPosition>();
    final ReadingPosition row = (await collection
            .filter()
            .surahEqualTo(ref.surah)
            .findFirst()) ??
        (ReadingPosition()..surah = ref.surah);
    row.ayah = ref.ayah;
    row.updatedAt = DateTime.now();
    await _isar.writeTxn(() => collection.put(row));
  }

  // ------------------------------------------------------------------ internals
  Future<AyahRef?> _single(String kind) async {
    final QuranMark? row = await _isar
        .collection<QuranMark>()
        .filter()
        .kindEqualTo(kind)
        .sortByCreatedAtDesc()
        .findFirst();
    return row == null ? null : AyahRef(row.surah, row.ayah);
  }

  /// Exactly one row of [kind] must exist, so the old one is deleted first.
  Future<void> _replaceSingle(String kind, AyahRef ref) async {
    final IsarCollection<QuranMark> collection = _isar.collection<QuranMark>();
    await _isar.writeTxn(() async {
      await collection.filter().kindEqualTo(kind).deleteAll();
      await collection.put(QuranMark()
        ..surah = ref.surah
        ..ayah = ref.ayah
        ..kind = kind
        ..createdAt = DateTime.now());
    });
  }

  Future<void> _clear(String kind) async {
    final IsarCollection<QuranMark> collection = _isar.collection<QuranMark>();
    await _isar.writeTxn(
      () => collection.filter().kindEqualTo(kind).deleteAll(),
    );
  }
}

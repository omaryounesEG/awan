import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';

/// Everything the Quran module needs from the outside world.
///
/// Local-first by design: the text, the page map and the bundled tafsir all come
/// from assets, so reading works with the radio off. The only network-touching
/// member is not here at all — add-on tafsir packages are downloaded by their own
/// datasource and then read through [tafsir].
abstract class QuranRepository {
  /// The whole text (memoised after the first isolate parse).
  Future<QuranText> text();

  /// Where every ayah sits in the printed Mushaf (page / juz / hizb / sajda).
  Future<MushafIndex> index();

  /// One tafsir edition — [id] 16 is the bundled Muyassar.
  Future<TafsirText> tafsir(int id);

  /// Diacritic- and hamza-insensitive full-text search.
  ///
  /// Searching the Uthmani text as written is useless: «الرحمن» never matches
  /// «ٱلرَّحْمَـٰنِ». Both sides are normalised first.
  Future<List<QuranSearchHit>> search(String query, {int limit});

  // ------------------------------------------------------------- bookmarks
  Future<List<BookmarkedAyah>> bookmarks();

  /// Adds a bookmark; adding the same verse twice replaces its note instead of
  /// duplicating the row.
  Future<void> addBookmark(AyahRef ref, {String? note});

  Future<void> removeBookmark(AyahRef ref);

  Future<bool> isBookmarked(AyahRef ref);

  // ------------------------------------------------- «علامة الوقوف» (one only)
  /// The single verse/page marker — where the reader stopped. Null when unset.
  Future<AyahRef?> stopMark();

  /// Moves the marker. Setting it twice keeps exactly one row.
  Future<void> setStopMark(AyahRef ref);

  Future<void> clearStopMark();

  // ------------------------------------------------------------ resume point
  /// The last verse the reader was on (per surah, newest wins).
  Future<AyahRef?> lastRead();

  Future<void> saveLastRead(AyahRef ref);
}

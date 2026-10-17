import 'package:isar/isar.dart';

part 'library_book.g.dart';

/// A book known to the library: catalogue metadata + local download state.
///
/// Data model of `shamila_library`. The file itself lives in the app documents
/// directory; this row is what the UI lists, honours "offline" for, and uses to
/// resume reading.
@collection
class LibraryBook {
  Id id = Isar.autoIncrement;

  /// Published identity from the CDN index, e.g. `0238.IbnHabibQurtubi.MukhtasarFiTibb`.
  @Index(unique: true, replace: true)
  late String bookId;

  @Index()
  late String title;

  late String author;
  late String source; // 'shamela' | 'openiti' | 'local'
  String? category;
  int sizeKb = 0;

  @Index()
  bool downloaded = false;

  String? filePath;
  int chapters = 0;

  /// First primary key of this book's chunk block (0 = never installed). See
  /// [IsarLibraryLocalDataSource] for why the text is keyed by id.
  int chunkBase = 0;
  int lastChapter = 0;
  double progress = 0;

  DateTime? downloadedAt;

  /// Indexed: the shelf is sorted by it (Isar sorts only on indexed fields).
  @Index()
  DateTime? lastOpenedAt;

  // ------------------------------------------------------------ from the index

  /// Hijri death year of the author, for the "ت ٢٣٨هـ" style subtitle and for
  /// chronological ordering inside a category. Null when the source is silent.
  int? authorDied;

  /// Where the archive is fetched from. Stored per row so a catalogue entry can
  /// point at a mirror without the app needing to know the layout.
  late String url;

  /// Corpus edition marker (`Shamela0000587`), shown for provenance: two
  /// printings of the same book are not the same text.
  String? version;

  /// Size of the *text*, not the archive.
  int chars = 0;

  /// Folded `title + author + category`, computed once at sync time so search
  /// over a large catalogue is a scan of one already-normalised column instead
  /// of a normalisation per keystroke.
  @Index()
  late String searchKey;

  @override
  String toString() => 'LibraryBook($bookId, $title)';
}

/// One successful index sync — a single row that also serves as the freshness
/// stamp. Kept in Isar rather than shared preferences so the catalogue and its
/// own bookkeeping can never disagree.
@collection
class LibrarySyncStamp {
  Id id = Isar.autoIncrement;

  late DateTime at;
  int books = 0;
  int added = 0;
  int updated = 0;
}

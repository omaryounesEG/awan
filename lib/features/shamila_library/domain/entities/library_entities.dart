/// Entities of the library feature.
///
/// The library is a *static CDN*: a master JSON index plus one archive per book.
/// Nothing here talks to a server object — the app downloads files that already
/// exist and stores what it needs locally, so a plain static host is the whole
/// backend.
library;

/// One row of `library_index.json`, plus whatever the device knows about it.
class BookEntry {
  const BookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.url,
    this.authorDied,
    this.source = 'openiti',
    this.version = '',
    this.chapters = 0,
    this.chars = 0,
    this.sizeBytes = 0,
    this.downloaded = false,
    this.lastChapter = 0,
    this.progress = 0,
  });

  /// Stable, URL-safe identity — also the archive's file stem.
  final String id;
  final String title;
  final String author;
  final String category;

  /// Absolute URL of the `.sqlite.zip` archive (already resolved by the host).
  final String url;

  /// Hijri death year of the author, when the corpus records one.
  final int? authorDied;
  final String source;

  /// Corpus version tag (`Shamela0009771`, `JK010412`, …).
  final String version;

  /// How many reading chunks the archive holds, and how much text.
  final int chapters;
  final int chars;
  final int sizeBytes;

  /// Local state.
  final bool downloaded;
  final int lastChapter;
  final double progress;

  BookEntry copyWith({
    String? title,
    String? author,
    String? category,
    String? url,
    int? chapters,
    int? chars,
    int? sizeBytes,
    bool? downloaded,
    int? lastChapter,
    double? progress,
  }) =>
      BookEntry(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        category: category ?? this.category,
        url: url ?? this.url,
        authorDied: authorDied,
        source: source,
        version: version,
        chapters: chapters ?? this.chapters,
        chars: chars ?? this.chars,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        downloaded: downloaded ?? this.downloaded,
        lastChapter: lastChapter ?? this.lastChapter,
        progress: progress ?? this.progress,
      );

  /// "ت ٢٣٨هـ" — the shelf label that tells two books by the same author apart.
  String get deathLabel => authorDied == null ? '' : 'ت $authorDiedهـ';
}

/// A readable slice of a book.
///
/// Chunks exist so the reader is a plain `ListView.builder`: 5,000 rows of ~3 KB
/// lay out fine, one 15 MB string would not.
class BookChunk {
  const BookChunk({
    required this.index,
    required this.text,
    this.title,
    this.page,
  });

  final int index;

  /// Section heading the chunk starts under, when the corpus has one.
  final String? title;

  /// Printed page number the chunk starts on, when the corpus has one.
  final String? page;
  final String text;
}


/// One heading inside an installed book: what the reader jumps to.
class BookChapter {
  const BookChapter({
    required this.chapter,
    required this.title,
    this.page,
    this.isPageMarker = false,
  });

  /// Chunk index of the heading, which is also the jump target.
  final int chapter;
  final String title;
  final String? page;

  /// True when [title] is not a heading but a printed-page marker the corpus
  /// stored in the title field («-102»). Such a book has no chapters, and calling
  /// a page number a chapter would be a quiet lie — the sheet says «صفحات» then.
  final bool isPageMarker;
}

/// One match of an in-book search.
class BookHit {
  const BookHit({
    required this.chapter,
    required this.snippet,
    required this.matchText,
    this.title,
    this.page,
  });

  final int chapter;

  /// The text around the match, already trimmed for display.
  final String snippet;

  /// The exact substring that matched, so the list can mark it inside [snippet].
  final String matchText;
  final String? title;
  final String? page;
}

/// A book's own text, queried by the reader.
///
/// Everything here is a pure function on strings so the tricky part of search —
/// which needle to hand the database, and how to cut a snippet around the match —
/// is testable without a device.
class BookSearch {
  const BookSearch._();

  /// Arabic marks that carry no meaning for a substring search: the harakat,
  /// the tatweel, and the Quranic annotation range.
  static final RegExp _marks = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

  /// A needle for the database.
  ///
  /// Diacritics are stripped because the corpus spells the same word both ways
  /// (a hadith is vocalised, the prose around it is not), and whitespace is
  /// collapsed so a phrase typed with a double space still matches. Letters are
  /// *not* substituted: the stored text keeps its hamzas and taa marbutas, and
  /// rewriting the query would silently stop matching them.
  static String needle(String query) =>
      query.replaceAll(_marks, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// The words to look for, longest first, capped so a pasted paragraph cannot
  /// ask the database for twenty conditions.
  ///
  /// Particles shorter than three letters («في»، «من»، «ما») are dropped: they sit
  /// in almost every chunk, so including them turns an intersection into noise.
  /// They still count inside the phrase the search tries first.
  static List<String> words(String query, {int max = 4}) {
    final List<String> parts = needle(query)
        .split(' ')
        .where((String w) => w.length > 2)
        .toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));
    return parts.take(max).toList();
  }

  /// The needle with the alef forms folded, tried only when the typed spelling
  /// finds nothing — "الإخلاص" and "الاخلاص" are the same search to a reader.
  static String foldedNeedle(String query) => needle(query)
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '');

  /// A title that is only a page marker, not a heading.
  ///
  /// The OpenITI conversions put the printed page in the title field as «-102» or
  /// «102-»; a Shamela book puts a real chapter there. Telling them apart is what
  /// decides whether a book has a table of contents at all.
  static final RegExp _pageMarker = RegExp(r'^[-–—\s]*\d{1,4}[-–—\s]*$');

  static bool isPageMarker(String title) => _pageMarker.hasMatch(title.trim());

  /// Cuts the passage around a match: [before] and [after] characters, snapped to
  /// word boundaries so the snippet starts on a word.
  static String snippet(String text, String needle, {int before = 40, int after = 90}) {
    final String flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (needle.isEmpty) {
      return flat.length <= before + after ? flat : '${flat.substring(0, before + after)}…';
    }
    final int at = flat.indexOf(needle);
    if (at < 0) {
      return flat.length <= before + after ? flat : '${flat.substring(0, before + after)}…';
    }
    int start = at - before;
    if (start < 0) start = 0;
    if (start > 0) {
      final int space = flat.indexOf(' ', start);
      if (space >= 0 && space < at) start = space + 1;
    }
    int end = at + needle.length + after;
    if (end > flat.length) end = flat.length;
    if (end < flat.length) {
      final int space = flat.lastIndexOf(' ', end);
      if (space > at + needle.length) end = space;
    }
    final String head = start > 0 ? '…' : '';
    final String tail = end < flat.length ? '…' : '';
    return '$head${flat.substring(start, end).trim()}$tail';
  }
}

/// What a sync did, for one calm sentence in the UI.
class LibrarySyncReport {
  const LibrarySyncReport({
    required this.total,
    required this.added,
    required this.updated,
    required this.bytes,
    required this.at,
  });

  final int total;
  final int added;
  final int updated;
  final int bytes;
  final DateTime at;
}

/// Which half of an install is running: the bytes, or the text going into Isar.
enum BookInstallPhase { downloading, installing, done, failed }

/// Progress of one book's install.
class BookInstallProgress {
  const BookInstallProgress({
    required this.phase,
    required this.ratio,
    this.received = 0,
    this.total = 0,
    this.chunksInstalled = 0,
    this.error,
  });

  final BookInstallPhase phase;

  /// 0…1 over the whole operation (download and install are one bar to the user).
  final double ratio;
  final int received;
  final int total;
  final int chunksInstalled;
  final Object? error;

  static const BookInstallProgress idle = BookInstallProgress(
    phase: BookInstallPhase.done,
    ratio: 1,
  );
}

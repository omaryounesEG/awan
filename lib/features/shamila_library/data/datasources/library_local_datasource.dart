import 'package:isar/isar.dart';

import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/shamila_library/data/datasources/library_index_parser.dart';
import 'package:awan/features/shamila_library/data/models/book_chunk.dart';
import 'package:awan/features/shamila_library/data/models/library_book.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// Everything the library keeps on the device.
abstract class LibraryLocalDataSource {
  /// Upserts the catalogue, preserving each book's local state. Returns how many
  /// rows were new.
  /// Replaces the catalogue.
  ///
  /// [retired] ids are dropped **even if they were installed**: a book the app
  /// deliberately no longer ships must not survive an update on the device that
  /// downloaded it earlier. Ordinary upstream disappearances still respect the
  /// local copy — see the implementation.
  Future<int> replaceIndex(
    List<BookEntry> entries, {
    Set<String> retired,
  });

  Future<List<BookEntry>> search({
    String query,
    String? category,
    int limit,
  });

  Future<List<({String name, int count})>> categories();

  Future<List<BookEntry>> bookshelf();

  Future<BookEntry?> byId(String bookId);

  Future<int> count();

  /// Reserves the id block this book's chunks will live in, clearing anything left
  /// there by an earlier install of the same book. See
  /// [IsarLibraryLocalDataSource] for why the text is keyed the way it is.
  Future<int> allocateChunkBase(String bookId);

  /// Appends one batch of a book's text. Called repeatedly during an install:
  /// batching is what keeps the database work off the frame budget.
  Future<void> writeChunks(
    String bookId,
    List<BookChunk> batch, {
    required int base,
  });

  Future<void> deleteChunks(String bookId);

  Future<List<BookChunk>> chunks(String bookId, {int from, int count});

  /// The book's own headings, in reading order — the table of contents.
  Future<List<BookChapter>> chapters(String bookId, {int limit});

  /// Matches inside the book's own text.
  Future<List<BookHit>> searchInside(String bookId, String query, {int limit});

  Future<int> chunkCount(String bookId);

  Future<void> markDownloaded(
    String bookId, {
    required bool downloaded,
    int? chapters,
  });

  Future<void> savePosition(String bookId, int chapter, double progress);

  Future<DateTime?> lastSyncAt();

  Future<void> stampSync({
    required int books,
    required int added,
    required int updated,
  });

  Future<void> clearIndex();
}

/// ## Why a book's chunks are keyed by id, not only by book
///
/// The reader's hot path is "one book, chapters `from`..`from + count`, in order".
/// The obvious model — a composite index on `(bookId, chapter)` — cannot be
/// expressed with Isar 3's generated API here: it emits no where-clause for the
/// leading field of a composite index, and it offers no `and()` for a second
/// indexed field (both were compile errors, not guesses).
///
/// So every book is given a block of primary keys, `base .. base + 999 999`, and a
/// chunk's id *is* `base + chapter`. The window becomes `idBetween(...)`: a
/// primary-key range scan, the cheapest read Isar has, which cannot spill into
/// another book because the blocks do not overlap. `bookId` stays a plain index
/// for the two whole-book operations (count and delete).
class IsarLibraryLocalDataSource implements LibraryLocalDataSource {
  IsarLibraryLocalDataSource(this._isar);

  final Isar _isar;

  /// Id space reserved per book. A million chunks is orders of magnitude more text
  /// than any book in the corpus, and still leaves room for thousands of books
  /// inside a 64-bit id.
  static const int chunkBlock = 1000000;

  IsarCollection<LibraryBook> get _books => _isar.collection<LibraryBook>();
  IsarCollection<BookChunkRow> get _chunks => _isar.collection<BookChunkRow>();
  IsarCollection<LibrarySyncStamp> get _stamps =>
      _isar.collection<LibrarySyncStamp>();

  // ------------------------------------------------------------------ index
  @override
  Future<int> replaceIndex(
    List<BookEntry> entries, {
    Set<String> retired = const <String>{},
  }) async {
    final List<LibraryBook> existing = await _books.where().findAll();
    final Map<String, LibraryBook> byId = <String, LibraryBook>{
      for (final LibraryBook row in existing) row.bookId: row,
    };
    final Set<String> incoming = <String>{for (final BookEntry e in entries) e.id};

    int added = 0;
    final List<LibraryBook> rows = <LibraryBook>[];
    for (final BookEntry entry in entries) {
      LibraryBook? row = byId[entry.id];
      if (row == null) {
        added++;
        row = LibraryBook()..bookId = entry.id;
      }
      rows.add(
        row
          ..title = entry.title
          ..author = entry.author
          ..category = entry.category
          ..source = entry.source
          ..version = entry.version
          ..authorDied = entry.authorDied
          ..url = entry.url
          ..chapters = entry.chapters
          ..chars = entry.chars
          ..sizeKb = (entry.sizeBytes / 1024).round()
          ..searchKey = LibraryIndexParser.searchKey(entry),
      );
    }

    // A book that vanished upstream is dropped from the catalogue unless the
    // reader installed it — losing an offline copy to someone else's edit would
    // be the wrong kind of tidy. A *retired* book is the opposite case: the app
    // stopped carrying it on purpose, so the copy on the device goes too — text
    // included, or the reader keeps a book the catalogue no longer knows about.
    final List<LibraryBook> orphans = existing
        .where(
          (LibraryBook r) =>
              (!incoming.contains(r.bookId) && !r.downloaded) ||
              retired.contains(r.bookId),
        )
        .toList();

    for (final LibraryBook row in orphans) {
      if (!retired.contains(row.bookId) || row.chunkBase <= 0) continue;
      await _isar.writeTxn(() async {
        await _chunks.where().idBetween(
              row.chunkBase,
              row.chunkBase + chunkBlock - 1,
              includeUpper: true,
            ).deleteAll();
      });
    }

    await _isar.writeTxn(() async {
      await _books.putAll(rows);
      if (orphans.isNotEmpty) {
        await _books.deleteAll(orphans.map((LibraryBook r) => r.id).toList());
      }
    });
    return added;
  }

  @override
  Future<void> clearIndex() => _isar.writeTxn(() => _books.clear());

  @override
  Future<List<BookEntry>> search({
    String query = '',
    String? category,
    int limit = 200,
  }) async {
    final String needle = normalizeArabic(query, foldSuperscriptAlef: true)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final bool byCategory = category != null && category.isNotEmpty;

    // Written out rather than composed: Isar's query stage types are not
    // reassignable, and four readable branches beat a builder variable that only
    // compiles with `dynamic`.
    //
    // `searchKeyContains` is a scan — it has to be, a LIKE over folded Arabic
    // cannot use a B-tree — but it scans *one already-normalised column*, and
    // that is what keeps typing feel instant on a 20 000 book catalogue.
    final List<LibraryBook> rows;
    if (needle.isNotEmpty && byCategory) {
      rows = await _books
          .filter()
          .searchKeyContains(needle)
          .and()
          .categoryEqualTo(category)
          .sortByDownloadedDesc()
          .thenByTitle()
          .limit(limit)
          .findAll();
    } else if (needle.isNotEmpty) {
      rows = await _books
          .filter()
          .searchKeyContains(needle)
          .sortByDownloadedDesc()
          .thenByTitle()
          .limit(limit)
          .findAll();
    } else if (byCategory) {
      rows = await _books
          .filter()
          .categoryEqualTo(category)
          .sortByDownloadedDesc()
          .thenByTitle()
          .limit(limit)
          .findAll();
    } else {
      // Downloaded books first: the shelf the reader actually uses stays on top.
      rows = await _books
          .where()
          .sortByDownloadedDesc()
          .thenByTitle()
          .limit(limit)
          .findAll();
    }
    return rows.map(_toEntry).toList();
  }

  @override
  Future<List<({String name, int count})>> categories() async {
    final List<LibraryBook> rows = await _books.where().findAll();
    final Map<String, int> counts = <String, int>{};
    for (final LibraryBook row in rows) {
      final String name = (row.category ?? '').trim().isEmpty
          ? 'عام'
          : row.category!.trim();
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final List<({String name, int count})> result = <({String name, int count})>[
      for (final MapEntry<String, int> entry in counts.entries)
        (name: entry.key, count: entry.value),
    ];
    result.sort((({String name, int count}) a, ({String name, int count}) b) =>
        b.count.compareTo(a.count));
    return result;
  }

  @override
  Future<List<BookEntry>> bookshelf() async {
    final List<LibraryBook> rows = await _books
        .filter()
        .downloadedEqualTo(true)
        .sortByLastOpenedAtDesc()
        .findAll();
    return rows.map(_toEntry).toList();
  }

  @override
  Future<BookEntry?> byId(String bookId) async {
    final LibraryBook? row =
        await _books.where().bookIdEqualTo(bookId).findFirst();
    return row == null ? null : _toEntry(row);
  }

  @override
  Future<int> count() => _books.count();

  // ------------------------------------------------------------------- text
  @override
  Future<int> allocateChunkBase(String bookId) async {
    final LibraryBook? row =
        await _books.where().bookIdEqualTo(bookId).findFirst();


    // Re-installing the same book reuses its own block: those ids already belong
    // to this book, so there is no reason to leak a block per attempt.
    if (row != null && row.chunkBase > 0) {
      await _isar.writeTxn(() async {
        await _chunks.where().idBetween(
              row.chunkBase,
              row.chunkBase + chunkBlock - 1,
              includeUpper: true,
            ).deleteAll();
      });
      return row.chunkBase;
    }

    final int? maxId = await _chunks.where().idProperty().max();
    final int base = (((maxId ?? 0) ~/ chunkBlock) + 1) * chunkBlock;

    if (row != null) {
      await _isar.writeTxn(() async {
        row.chunkBase = base;
        await _books.put(row);
      });
    }
    return base;
  }

  @override
  Future<void> writeChunks(
    String bookId,
    List<BookChunk> batch, {
    required int base,
  }) async {
    if (batch.isEmpty) return;

    final List<BookChunkRow> rows = <BookChunkRow>[
      for (final BookChunk chunk in batch)
        BookChunkRow()
          ..id = base + chunk.index
          ..bookId = bookId
          ..chapter = chunk.index
          ..title = chunk.title
          ..page = chunk.page
          ..text = chunk.text,
    ];
    await _isar.writeTxn(() => _chunks.putAll(rows));
  }

  @override
  Future<void> deleteChunks(String bookId) async {
    final LibraryBook? row =
        await _books.where().bookIdEqualTo(bookId).findFirst();
    if (row == null || row.chunkBase <= 0) return;
    await _isar.writeTxn(() async {
      await _chunks.where().idBetween(
            row.chunkBase,
            row.chunkBase + chunkBlock - 1,
            includeUpper: true,
          ).deleteAll();
    });
  }

  @override
  Future<List<BookChunk>> chunks(
    String bookId, {
    int from = 0,
    int count = 40,
  }) async {
    final LibraryBook? row =
        await _books.where().bookIdEqualTo(bookId).findFirst();
    if (row == null) return const <BookChunk>[];

    List<BookChunkRow> rows;
    if (row.chunkBase > 0) {
      final int first = row.chunkBase + from;
      rows = await _chunks
          .where()
          .idBetween(first, first + count - 1, includeUpper: true)
          .findAll();
    } else {
      // A book installed before the base was recorded still has its text, keyed
      // by book — the range read simply refuses to look at it, which used to leave
      // the reader blank under a footer that correctly said how many chunks there
      // were. Read it by book instead, then *repair* the row so the next open takes
      // the fast path again.
      rows = await _chunks
          .where()
          .bookIdEqualTo(bookId)
          .offset(from)
          .limit(count)
          .findAll();
      await _healChunkBase(row, rows, from);
    }

    // Same base for every chunk of a book, so id order is reading order; sorting
    // by the stored index makes that independent of how the ids were assigned.
    rows.sort((BookChunkRow a, BookChunkRow b) => a.chapter.compareTo(b.chapter));
    // A primary-key range, so scrolling a 6 000 chunk book never walks another
    // book's rows and never sorts: id order *is* reading order.
    return <BookChunk>[
      for (final BookChunkRow row in rows)
        BookChunk(
          index: row.chapter,
          title: row.title,
          page: row.page,
          text: row.text,
        ),
    ];
  }


  /// Repairs a book whose chunk base was never recorded.
  ///
  /// Called on the slow read path, once per book: [rows] starts at [from], so the
  /// base is simply the first row's id minus that offset.
  Future<void> _healChunkBase(LibraryBook row, List<BookChunkRow> rows, int from) async {
    if (rows.isEmpty) return;
    final int base = rows.first.id - from;
    if (base <= 0 || base == row.chunkBase) return;
    await _isar.writeTxn(() async {
      row.chunkBase = base;
      await _books.put(row);
    });
  }

  /// The headings inside one book, in reading order.
  ///
  /// Only chunks the corpus gave a title stand for a section, which is what makes
  /// this a table of contents rather than a list of every paragraph.
  @override
  Future<List<BookChapter>> chapters(String bookId, {int limit = 600}) async {
    final List<BookChunkRow> rows = await _chunks
        .where()
        .bookIdEqualTo(bookId)
        .filter()
        .titleIsNotNull()
        .and()
        .not()
        .titleEqualTo('')
        .limit(limit)
        .findAll();
    rows.sort((BookChunkRow a, BookChunkRow b) => a.chapter.compareTo(b.chapter));
    final List<BookChapter> all = <BookChapter>[
      for (final BookChunkRow row in rows)
        BookChapter(
          chapter: row.chapter,
          title: row.title!.trim(),
          page: row.page,
          isPageMarker: BookSearch.isPageMarker(row.title!),
        ),
    ];
    // A real heading beats a page number: a book that has both gets a proper index
    // of its chapters. Only a book that has *none* falls back to its page markers,
    // which is still a way to move through it — and the sheet says so.
    final List<BookChapter> headings =
        all.where((BookChapter c) => !c.isPageMarker).toList();
    return headings.isNotEmpty ? headings : all;
  }

  /// Searches one book's own text.
  ///
  /// Three passes, cheapest first: the phrase as typed, then all its words
  /// together (so word order and the matn's own line breaks cannot hide a match),
  /// then the same with the alef forms folded. Nothing here walks the whole book
  /// in Dart — every pass is a filtered Isar query limited to this book.
  @override
  Future<List<BookHit>> searchInside(
    String bookId,
    String query, {
    int limit = 60,
  }) async {
    final String phrase = BookSearch.needle(query);
    if (phrase.isEmpty) return const <BookHit>[];

    List<BookChunkRow> rows = await _chunks
        .where()
        .bookIdEqualTo(bookId)
        .filter()
        .textContains(phrase)
        .limit(limit)
        .findAll();

    final List<String> words = BookSearch.words(query);
    if (rows.isEmpty && words.length > 1) {
      // One query per word, intersected on the primary key: a matn's words can sit
      // across a line break, so an exact phrase is not enough — and Isar's filter
      // chain cannot be built word by word.
      List<BookChunkRow>? common;
      for (final String word in words) {
        final List<BookChunkRow> found = await _chunks
            .where()
            .bookIdEqualTo(bookId)
            .filter()
            .textContains(word)
            .limit(limit * 2)
            .findAll();
        if (found.isEmpty) {
          common = const <BookChunkRow>[];
          break;
        }
        final Set<int> ids = <int>{for (final BookChunkRow row in found) row.id};
        common = common == null
            ? found
            : common.where((BookChunkRow row) => ids.contains(row.id)).toList();
      }
      rows = common ?? const <BookChunkRow>[];
    }

    if (rows.isEmpty) {
      final String folded = BookSearch.foldedNeedle(query);
      if (folded != phrase && folded.isNotEmpty) {
        rows = await _chunks
            .where()
            .bookIdEqualTo(bookId)
            .filter()
            .textContains(folded)
            .limit(limit)
            .findAll();
      }
    }

    rows.sort((BookChunkRow a, BookChunkRow b) => a.chapter.compareTo(b.chapter));
    final List<BookHit> hits = <BookHit>[];
    for (final BookChunkRow row in rows) {
      final String text = row.text;
      String found = phrase;
      if (!text.contains(found)) {
        found = words.firstWhere(
          (String word) => text.contains(word),
          orElse: () => BookSearch.foldedNeedle(query),
        );
      }
      hits.add(
        BookHit(
          chapter: row.chapter,
          title: row.title,
          page: row.page,
          snippet: BookSearch.snippet(text, found),
          matchText: found,
        ),
      );
    }
    return hits;
  }

  @override
  Future<int> chunkCount(String bookId) => _chunks
      .where()
      .bookIdEqualTo(bookId)
      .count();

  // ------------------------------------------------------------ local state
  @override
  Future<void> markDownloaded(
    String bookId, {
    required bool downloaded,
    int? chapters,
  }) async {
    await _isar.writeTxn(() async {
      final LibraryBook? row =
          await _books.where().bookIdEqualTo(bookId).findFirst();
      if (row == null) return;
      row.downloaded = downloaded;
      row.downloadedAt = downloaded ? DateTime.now() : null;
      if (chapters != null) row.chapters = chapters;
      await _books.put(row);
    });
  }

  @override
  Future<void> savePosition(String bookId, int chapter, double progress) async {
    await _isar.writeTxn(() async {
      final LibraryBook? row =
          await _books.where().bookIdEqualTo(bookId).findFirst();
      if (row == null) return;
      row.lastChapter = chapter;
      row.progress = progress.clamp(0, 1);
      row.lastOpenedAt = DateTime.now();
      await _books.put(row);
    });
  }

  @override
  Future<DateTime?> lastSyncAt() async {
    final LibrarySyncStamp? stamp =
        await _stamps.where().sortByAtDesc().findFirst();
    return stamp?.at;
  }

  @override
  Future<void> stampSync({
    required int books,
    required int added,
    required int updated,
  }) async {
    final LibrarySyncStamp stamp = LibrarySyncStamp()
      ..at = DateTime.now()
      ..books = books
      ..added = added
      ..updated = updated;
    // One row is plenty; keeping the previous ones only helps if the UI ever
    // wants a history, and it does not.
    await _isar.writeTxn(() async {
      await _stamps.clear();
      await _stamps.put(stamp);
    });
  }

  BookEntry _toEntry(LibraryBook row) => BookEntry(
        id: row.bookId,
        title: row.title,
        author: row.author,
        category: row.category ?? 'عام',
        url: row.url,
        authorDied: row.authorDied,
        source: row.source,
        version: row.version ?? '',
        chapters: row.chapters,
        chars: row.chars,
        sizeBytes: row.sizeKb * 1024,
        // `chapters` is the catalogue's section count until an install
        // overwrites it, so it can never stand in for "is it on the device".
        downloaded: row.downloaded,
        lastChapter: row.lastChapter,
        progress: row.progress,
      );
}

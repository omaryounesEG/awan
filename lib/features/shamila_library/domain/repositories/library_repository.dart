import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// The library's port.
///
/// Two sources, one face: a static file host (the index, then one archive per
/// book) and Isar (the cached index and the installed text). Everything the
/// presentation layer can do to a book is here.
abstract class LibraryRepository {
  /// Downloads (or re-reads the cache of) the master index.
  Future<Either<Failure, LibrarySyncReport>> syncIndex({bool force = false});

  /// Local search over the cached index — never a network call.
  Future<List<BookEntry>> search({
    String query = '',
    String? category,
    int limit = 200,
  });

  /// Distinct categories with their book counts, for the Discover tab.
  Future<List<({String name, int count})>> categories();

  /// Books fully installed on the device.
  Future<List<BookEntry>> bookshelf();

  /// One catalogue row, for the reader's header and for resume.
  Future<BookEntry?> book(String bookId);

  /// Downloads, unpacks and installs one book. Emits progress as it goes.
  Stream<BookInstallProgress> install(String bookId);

  /// Stops an install in flight — a 3 MB download on a phone tariff should be
  /// interruptible.
  Future<void> cancelInstall(String bookId);

  /// Chunks of an installed book, for the reader.
  Future<List<BookChunk>> chunks(
    String bookId, {
    int from = 0,
    int count = 40,
  });

  /// The book's own headings, in reading order — the table of contents.
  Future<List<BookChapter>> chapters(String bookId, {int limit = 600});

  /// Matches inside the book's own text.
  Future<List<BookHit>> searchInside(
    String bookId,
    String query, {
    int limit = 60,
  });

  /// Number of chunks stored for a book (drives the reader's scroll extent).
  Future<int> chunkCount(String bookId);

  /// Drops the text and the download flag, keeping the catalogue row.
  Future<void> remove(String bookId);

  /// Where the reader stopped.
  Future<void> savePosition(String bookId, int chapter, double progress);
}

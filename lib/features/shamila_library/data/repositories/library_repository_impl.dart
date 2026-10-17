import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/shamila_library/data/datasources/bundled_library_index.dart';
import 'package:awan/features/shamila_library/data/datasources/library_index_parser.dart';
import 'package:awan/features/shamila_library/data/datasources/library_local_datasource.dart';
import 'package:awan/features/shamila_library/data/datasources/library_remote_datasource.dart';
import 'package:awan/features/shamila_library/data/services/book_archive_installer.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required LibraryRemoteDataSource remote,
    required LibraryLocalDataSource local,
    required String Function() baseUrl,
    required Directory cacheDir,
    Duration indexTtl = const Duration(hours: 12),
    BundledLibraryIndex bundled = const AssetLibraryIndex(),
  })  : _remote = remote,
        _local = local,
        _baseUrl = baseUrl,
        _cacheDir = cacheDir,
        _indexTtl = indexTtl,
        _bundled = bundled;

  final LibraryRemoteDataSource _remote;
  final LibraryLocalDataSource _local;
  final String Function() _baseUrl;
  final Directory _cacheDir;
  final Duration _indexTtl;

  /// The catalogue the app carries, used when no source is configured and when a
  /// fresh install cannot reach one.
  final BundledLibraryIndex _bundled;

  /// How much of the single bar belongs to the download.
  ///
  /// One bar, two phases, because "fetching 0.7 then unpacking 0.3" is a detail
  /// of the implementation — but the split is honest: the bytes really are the
  /// larger share on any real connection.
  static const double _downloadShare = 0.7;

  final Map<String, CancelToken> _cancels = <String, CancelToken>{};

  /// Bumped whenever the bundled catalogue changes (new books added, old books pruned).
  static const int bundledCatalogueVersion = 3;

  /// Books the app used to carry and has stopped carrying.
  ///
  /// Kept as an explicit list rather than implied by "missing from the bundle":
  /// an unavailable source must never be able to empty a reader's shelf, so only
  /// a deliberate retirement removes an already-installed copy — text and all.
  static const Set<String> retiredBookIds = <String>{
    '0001AwsIbnHajar.Diwan',
  };
  static const String _catalogueVersionKey = 'bundledCatalogueVersion';

  // ------------------------------------------------------------------- index
  @override
  Future<Either<Failure, LibrarySyncReport>> syncIndex({bool force = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? seededVersion = prefs.getInt(_catalogueVersionKey);
    final bool needsBundleSync = seededVersion != bundledCatalogueVersion;
    final String base = _baseUrl().trim();
    final Uri? parsed = Uri.tryParse(base.isEmpty ? '' : base);
    final bool configured =
        parsed != null && parsed.hasScheme && parsed.host.isNotEmpty;

    try {
      if (needsBundleSync) {
        final LibrarySyncReport? bundled = await _syncFromBundle(base);
        if (bundled != null) {
          await prefs.setInt(_catalogueVersionKey, bundledCatalogueVersion);
          return Right(bundled);
        }
      }

      final DateTime? last = await _local.lastSyncAt();
      final bool fresh =
          last != null && DateTime.now().difference(last) < _indexTtl;
      final int cached = await _local.count();
      if (!force && fresh && cached > 0) {
        return Right(
          LibrarySyncReport(
            total: cached,
            added: 0,
            updated: 0,
            bytes: 0,
            at: last,
          ),
        );
      }

      // Nothing configured to ask, but the app still carries a catalogue:
      // browsing the library is not a network feature.
      if (!configured) {
        final LibrarySyncReport? bundled = await _syncFromBundle(base);
        if (bundled != null) {
          return Right(bundled);
        }
        return const Left(
          ServerFailure(message: 'library source is not configured'),
        );
      }

      final Map<String, dynamic> json;
      try {
        json = await _remote.fetchIndex(base);
      } on DioException catch (error) {
        // A fresh install that cannot reach its source is exactly where the
        // bundled index earns its kilobytes; with a catalogue already in hand the
        // cached one wins and the failure is reported as it is.
        if (cached == 0) {
          final LibrarySyncReport? bundled = await _syncFromBundle(base);
          if (bundled != null) {
            await prefs.setInt(_catalogueVersionKey, bundledCatalogueVersion);
            return Right(bundled);
          }
        }
        return Left(_networkFailure(error));
      }

      final List<BookEntry> entries =
          LibraryIndexParser.parse(json, baseUrl: base);
      if (entries.isEmpty) {
        final LibrarySyncReport? bundled = await _syncFromBundle(base);
        if (bundled != null) {
          return Right(bundled);
        }
        return const Left(
          ParseFailure(message: 'the catalogue is empty'),
        );
      }

      return Right(await _store(entries));
    } on DioException catch (error) {
      return Left(_networkFailure(error));
    } on FormatException catch (error) {
      return Left(ParseFailure(cause: error));
    } on FileSystemException catch (error) {
      return Left(CacheFailure(cause: error));
    } on IsarError catch (error) {
      return Left(CacheFailure(cause: error));
    }
  }

  /// Writes [entries] into the local catalogue and reports what changed.
  Future<LibrarySyncReport> _store(List<BookEntry> entries) async {
    final int added = await _local.replaceIndex(
      entries,
      retired: retiredBookIds,
    );
    await _local.stampSync(
      books: entries.length,
      added: added,
      updated: entries.length - added,
    );
    return LibrarySyncReport(
      total: entries.length,
      added: added,
      updated: entries.length - added,
      bytes: entries.fold<int>(0, (int sum, BookEntry e) => sum + e.sizeBytes),
      at: DateTime.now(),
    );
  }

  /// The catalogue that ships inside the app, or `null` when it cannot be read.
  Future<LibrarySyncReport?> _syncFromBundle(String base) async {
    final Map<String, dynamic>? json = await _bundled.load();
    if (json == null) {
      return null;
    }
    final List<BookEntry> entries =
        LibraryIndexParser.parse(json, baseUrl: base);
    if (entries.isEmpty) {
      return null;
    }
    return _store(entries);
  }

  /// The app's own copy of [bookId], written where the installer expects an
  /// archive so the shipped and downloaded paths read the same kind of file.
  Future<File?> _shippedArchive(String bookId) async {
    final Uint8List? bytes = await _bundled.archiveBytes(bookId);
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final File file = File('${_cacheDir.path}/$bookId.sqlite.zip');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Failure _networkFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkFailure(cause: error);
      case DioExceptionType.badResponse:
        return ServerFailure(
          statusCode: error.response?.statusCode,
          cause: error,
        );
      default:
        return NetworkFailure(cause: error);
    }
  }

  // ------------------------------------------------------------------ search
  @override
  Future<List<BookEntry>> search({
    String query = '',
    String? category,
    int limit = 200,
  }) =>
      _local.search(query: query, category: category, limit: limit);

  @override
  Future<List<({String name, int count})>> categories() => _local.categories();

  @override
  Future<List<BookEntry>> bookshelf() => _local.bookshelf();

  @override
  Future<BookEntry?> book(String bookId) => _local.byId(bookId);

  // ----------------------------------------------------------------- install
  @override
  Stream<BookInstallProgress> install(String bookId) {
    final StreamController<BookInstallProgress> out =
        StreamController<BookInstallProgress>();
    unawaited(_runInstall(bookId, out));
    return out.stream;
  }

  Future<void> _runInstall(
    String bookId,
    StreamController<BookInstallProgress> out,
  ) async {
    File? archive;
    try {
      final BookEntry? entry = await _local.byId(bookId);
      if (entry == null) {
        out.add(
          const BookInstallProgress(
            phase: BookInstallPhase.failed,
            ratio: 0,
            error: 'unknown-book',
          ),
        );
        return;
      }

      // Re-installing replaces the text rather than mixing two editions.
      await _local.deleteChunks(bookId);
      out.add(
        const BookInstallProgress(
          phase: BookInstallPhase.downloading,
          ratio: 0,
        ),
      );

      // A book the app already carries installs from the bundle: no request, no
      // source to be reachable, no waiting for a file that is on the device.
      final File? shipped = await _shippedArchive(bookId);
      if (shipped != null) {
        archive = shipped;
      } else {
        final CancelToken cancel = CancelToken();
        _cancels[bookId] = cancel;
        archive = await _remote.downloadArchive(
          url: entry.url,
          fileName: '$bookId.sqlite.zip',
          directory: _cacheDir,
          cancelToken: cancel,
          onProgress: (int received, int total) {
            if (out.isClosed) return;
            final double ratio = total > 0 ? received / total : 0;
            out.add(
              BookInstallProgress(
                phase: BookInstallPhase.downloading,
                ratio: (ratio * _downloadShare).clamp(0.0, _downloadShare),
                received: received,
                total: total,
              ),
            );
          },
        );
      }

      out.add(
        const BookInstallProgress(
          phase: BookInstallPhase.installing,
          ratio: _downloadShare,
        ),
      );

      final int base = await _local.allocateChunkBase(bookId);
      final int chunks = await BookArchiveInstaller.install(
        archivePath: archive.path,
        bookId: bookId,
        onBatch: (List<BookChunk> batch) =>
            _local.writeChunks(bookId, batch, base: base),
        onProgress: (double ratio, int chunksInstalled) {
          if (out.isClosed) return;
          out.add(
            BookInstallProgress(
              phase: BookInstallPhase.installing,
              ratio: (_downloadShare + ratio * (1 - _downloadShare))
                  .clamp(_downloadShare, 1.0),
              chunksInstalled: chunksInstalled,
            ),
          );
        },
      );

      await _local.markDownloaded(bookId, downloaded: true, chapters: chunks);
      out.add(
        BookInstallProgress(
          phase: BookInstallPhase.done,
          ratio: 1,
          chunksInstalled: chunks,
        ),
      );
    } catch (error) {
      out.add(
        BookInstallProgress(
          phase: BookInstallPhase.failed,
          ratio: 0,
          error: error,
        ),
      );
    } finally {
      _cancels.remove(bookId);
      // The archive is a transport, not a collection: the text is in Isar now, and
      // keeping both doubles the space a book costs. Deleting can lose a race with
      // the unpacking isolate releasing its handle, so it retries briefly — a
      // multi-megabyte leftover per book is worth three attempts.
      if (archive != null) await _deleteArchive(archive);
      if (!out.isClosed) await out.close();
    }
  }

  Future<void> _deleteArchive(File archive) async {
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        if (!await archive.exists()) return;
        await archive.delete();
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  @override
  Future<void> cancelInstall(String bookId) async {
    _cancels[bookId]?.cancel('cancelled by the reader');
  }

  // -------------------------------------------------------------------- text
  @override
  Future<List<BookChunk>> chunks(
    String bookId, {
    int from = 0,
    int count = 40,
  }) =>
      _local.chunks(bookId, from: from, count: count);

  @override
  Future<int> chunkCount(String bookId) => _local.chunkCount(bookId);

  @override
  Future<List<BookChapter>> chapters(String bookId, {int limit = 600}) =>
      _local.chapters(bookId, limit: limit);

  @override
  Future<List<BookHit>> searchInside(
    String bookId,
    String query, {
    int limit = 60,
  }) =>
      _local.searchInside(bookId, query, limit: limit);

  @override
  Future<void> remove(String bookId) async {
    await _local.deleteChunks(bookId);
    await _local.markDownloaded(bookId, downloaded: false, chapters: 0);
    await _local.savePosition(bookId, 0, 0);
  }

  @override
  Future<void> savePosition(String bookId, int chapter, double progress) =>
      _local.savePosition(bookId, chapter, progress);
}

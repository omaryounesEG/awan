import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/shamila_library/data/datasources/library_local_datasource.dart';
import 'package:awan/features/shamila_library/data/datasources/library_remote_datasource.dart';
import 'package:awan/features/shamila_library/data/repositories/library_repository_impl.dart';
import 'package:awan/features/shamila_library/data/datasources/bundled_library_index.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

class _FakeBundled implements BundledLibraryIndex {
  const _FakeBundled();

  @override
  Future<Uint8List?> archiveBytes(String bookId) async => null;

  @override
  Future<Map<String, dynamic>?> load() async => <String, dynamic>{
        'schema': 1,
        'books': <Object?>[
          <String, Object?>{
            'id': '0238.IbnHabibQurtubi.MukhtasarFiTibb',
            'title': '(مختصر في الطب)',
            'author': 'عبد بن حبيب',
            'author_died': 238,
            'category': 'علوم أخرى',
            'chapters': 2,
            'file_size': 900,
          },
        ],
      };
}

/// In-memory stand-in for Isar. The repository is what is under test here — its
/// sync policy, its install pipeline and its failure mapping — and all three are
/// testable without a native database.
class _FakeLocal implements LibraryLocalDataSource {
  final Map<String, BookEntry> catalogue = <String, BookEntry>{};
  final Map<String, List<BookChunk>> text = <String, List<BookChunk>>{};
  final Set<String> downloaded = <String>{};
  DateTime? syncAt;
  int? lastBase;

  /// Mirrors the real allocation rule: each book gets its own id block.
  final Map<String, int> bases = <String, int>{};

  @override
  @override
  Future<int> replaceIndex(
    List<BookEntry> entries, {
    Set<String> retired = const <String>{},
  }) async {
    int added = 0;
    for (final String id in retired) {
      if (catalogue.containsKey(id)) {
        catalogue.remove(id);
        text.remove(id);
      }
    }
    for (final BookEntry entry in entries) {
      if (!catalogue.containsKey(entry.id)) added++;
      catalogue[entry.id] = entry;
    }
    return added;
  }

  @override
  Future<List<BookEntry>> search({
    String query = '',
    String? category,
    int limit = 200,
  }) async =>
      catalogue.values
          .where((BookEntry b) => category == null || b.category == category)
          .take(limit)
          .toList();

  @override
  Future<List<({String name, int count})>> categories() async =>
      <({String name, int count})>[
        for (final BookEntry book in catalogue.values)
          (name: book.category, count: 1),
      ];

  @override
  Future<List<BookEntry>> bookshelf() async =>
      catalogue.values.where((BookEntry b) => downloaded.contains(b.id)).toList();

  @override
  Future<BookEntry?> byId(String bookId) async => catalogue[bookId];

  @override
  Future<int> count() async => catalogue.length;

  @override
  Future<int> allocateChunkBase(String bookId) async {
    lastBase = bases[bookId] ??= (bases.length + 1) * 1000000;
    text.remove(bookId);
    return lastBase!;
  }

  @override
  Future<void> writeChunks(
    String bookId,
    List<BookChunk> batch, {
    required int base,
  }) async =>
      text.putIfAbsent(bookId, () => <BookChunk>[]).addAll(batch);

  @override
  Future<void> deleteChunks(String bookId) async => text.remove(bookId);

  @override
  Future<List<BookChunk>> chunks(
    String bookId, {
    int from = 0,
    int count = 40,
  }) async =>
      (text[bookId] ?? const <BookChunk>[]).where((BookChunk c) => c.index >= from).take(count).toList();

  @override
  Future<int> chunkCount(String bookId) async => text[bookId]?.length ?? 0;

  @override
  Future<List<BookChapter>> chapters(String bookId, {int limit = 600}) async {
    // Headings only, in order — the same shape the real store returns.
    return <BookChapter>[
      for (final BookChunk chunk in text[bookId] ?? const <BookChunk>[])
        if ((chunk.title ?? '').trim().isNotEmpty)
          BookChapter(
            chapter: chunk.index,
            title: chunk.title!.trim(),
            page: chunk.page,
          ),
    ];
  }

  @override
  Future<List<BookHit>> searchInside(
    String bookId,
    String query, {
    int limit = 60,
  }) async {
    final List<BookHit> hits = <BookHit>[];
    for (final BookChunk chunk in text[bookId] ?? const <BookChunk>[]) {
      if (!chunk.text.contains(query)) continue;
      hits.add(
        BookHit(
          chapter: chunk.index,
          title: chunk.title,
          page: chunk.page,
          snippet: BookSearch.snippet(chunk.text, query),
          matchText: query,
        ),
      );
    }
    return hits;
  }

  @override
  Future<void> markDownloaded(
    String bookId, {
    required bool downloaded,
    int? chapters,
  }) async {
    if (downloaded) {
      this.downloaded.add(bookId);
    } else {
      this.downloaded.remove(bookId);
    }
  }

  @override
  Future<void> savePosition(String bookId, int chapter, double progress) async {}

  @override
  Future<DateTime?> lastSyncAt() async => syncAt;

  @override
  Future<void> stampSync({
    required int books,
    required int added,
    required int updated,
  }) async =>
      syncAt = DateTime.now();

  @override
  Future<void> clearIndex() async => catalogue.clear();
}

/// Serves one index and one archive, and counts the fetches.
class _FakeRemote implements LibraryRemoteDataSource {
  _FakeRemote({this.failIndex = false});

  final bool failIndex;
  int indexCalls = 0;
  int downloadCalls = 0;

  @override
  Future<Map<String, dynamic>> fetchIndex(String baseUrl) async {
    indexCalls++;
    if (failIndex) {
      throw DioException(
        requestOptions: RequestOptions(path: baseUrl),
        type: DioExceptionType.connectionError,
      );
    }
    return <String, dynamic>{
      'schema': 1,
      'books': <Object?>[
        <String, Object?>{
          'id': '0238.IbnHabibQurtubi.MukhtasarFiTibb',
          'title': '(مختصر في الطب)',
          'author': 'عبد بن حبيب',
          'author_died': 238,
          'category': 'علوم أخرى',
          'chapters': 2,
          'file_size': 900,
        },
      ],
    };
  }

  @override
  Future<File> downloadArchive({
    required String url,
    required String fileName,
    required Directory directory,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    downloadCalls++;
    final Directory dir = await directory.create(recursive: true);
    final File file = File('${dir.path}/$fileName');

    final List<int> payload = utf8.encode(
      <Map<String, Object?>>[
        <String, Object?>{
          'i': 0,
          't': 'باب',
          'p': '1',
          'x': 'نص الكتاب الأول',
        },
        <String, Object?>{'i': 1, 't': null, 'p': '2', 'x': 'نص الكتاب الثاني'},
      ].map(jsonEncode).join('\n'),
    );
    final Archive archive = Archive()
      ..addFile(ArchiveFile('book.sqlite', 4, <int>[0, 0, 0, 0]))
      ..addFile(ArchiveFile('book.jsonl', payload.length, payload));
    final List<int> bytes = ZipEncoder().encode(archive);
    await file.writeAsBytes(bytes);

    // A static host reports content-length; the bar depends on it.
    onProgress?.call(bytes.length ~/ 2, bytes.length);
    onProgress?.call(bytes.length, bytes.length);
    return file;
  }
}

void main() {
  late _FakeLocal local;
  late _FakeRemote remote;
  late Directory cache;
  late LibraryRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bundledCatalogueVersion': LibraryRepositoryImpl.bundledCatalogueVersion,
    });
    local = _FakeLocal();
    remote = _FakeRemote();
    cache = await Directory.systemTemp.createTemp('awan_repo_test');
    repository = LibraryRepositoryImpl(
      remote: remote,
      local: local,
      baseUrl: () => 'https://cdn.example.com/awan/library',
      cacheDir: cache,
      bundled: const _FakeBundled(),
    );
  });

  tearDown(() async {
    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        if (cache.existsSync()) await cache.delete(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  });

  test('sync writes the catalogue and stamps the time', () async {
    final Either<Failure, LibrarySyncReport> result =
        await repository.syncIndex();

    expect(result.isRight(), isTrue);
    final LibrarySyncReport report = result.getOrElse(
      () => throw StateError('expected a report'),
    );
    expect(report.total, 1);
    expect(report.added, 1);
    expect(report.bytes, 900);
    expect(local.catalogue, hasLength(1));
    expect(local.syncAt, isNotNull);
  });

  test('a fresh index is not fetched twice', () async {
    await repository.syncIndex();
    await repository.syncIndex();

    expect(remote.indexCalls, 1);
  });

  test('force ignores the freshness window', () async {
    await repository.syncIndex();
    await repository.syncIndex(force: true);

    expect(remote.indexCalls, 2);
  });

  test('a server that is down is a Failure, and the catalogue survives',
      () async {
    await repository.syncIndex();
    final LibraryRepositoryImpl offline = LibraryRepositoryImpl(
      remote: _FakeRemote(failIndex: true),
      local: local,
      baseUrl: () => 'https://cdn.example.com/awan/library',
      cacheDir: cache,
    );

    final Either<Failure, LibrarySyncReport> result =
        await offline.syncIndex(force: true);

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => throw StateError('x')),
        isA<NetworkFailure>());
    // The whole point of a local catalogue: the books stay listed.
    expect(local.catalogue, hasLength(1));
  });

  test('an older bundled catalogue version triggers bundle sync even when cached', () async {
    // Seed with an older version
    SharedPreferences.setMockInitialValues(<String, Object>{
      'bundledCatalogueVersion': LibraryRepositoryImpl.bundledCatalogueVersion - 1,
    });
    local.catalogue['old_book'] = const BookEntry(
      id: 'old_book',
      title: 'كتاب قديم',
      author: 'مؤلف',
      category: 'عام',
      url: 'https://example.com/old_book.sqlite.zip',
      sizeBytes: 100,
    );
    local.syncAt = DateTime.now();

    final Either<Failure, LibrarySyncReport> result =
        await repository.syncIndex();

    expect(result.isRight(), isTrue);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('bundledCatalogueVersion'),
        LibraryRepositoryImpl.bundledCatalogueVersion);
  });

  test('a retired book leaves the shelf even if it was installed', () async {
    // The Diwan case: the app stops carrying it, so the copy the reader already
    // downloaded has to go with it — a catalogue row without a bundle is a book
    // that can never be re-installed.
    local.catalogue['0001AwsIbnHajar.Diwan'] = const BookEntry(
      id: '0001AwsIbnHajar.Diwan',
      title: 'ديوان أوس بن حجر',
      author: 'أوس بن حجر',
      category: 'الشعر والأدب',
      url: 'https://example.com/diwan.sqlite.zip',
      downloaded: true,
    );
    local.text['0001AwsIbnHajar.Diwan'] = <BookChunk>[
      const BookChunk(index: 0, text: 'شعر', page: '1'),
      const BookChunk(index: 1, text: 'شعر', page: '2'),
    ];

    await repository.syncIndex(force: true);

    expect(local.catalogue.containsKey('0001AwsIbnHajar.Diwan'), isFalse);
    expect(local.text.containsKey('0001AwsIbnHajar.Diwan'), isFalse);
  });

  test('an unconfigured source is refused before any request', () async {
    final LibraryRepositoryImpl unconfigured = LibraryRepositoryImpl(
      remote: remote,
      local: local,
      baseUrl: () => '   ',
      cacheDir: cache,
    );

    final Either<Failure, LibrarySyncReport> result =
        await unconfigured.syncIndex();

    expect(result.isLeft(), isTrue);
    expect(remote.indexCalls, 0);
  });

  test('install runs the whole pipeline and leaves no archive behind',
      () async {
    await repository.syncIndex();
    const String bookId = '0238.IbnHabibQurtubi.MukhtasarFiTibb';

    final List<BookInstallPhase> phases = <BookInstallPhase>[];
    final List<BookInstallProgress> progress =
        await repository.install(bookId).toList();
    phases.addAll(progress.map((BookInstallProgress p) => p.phase));

    expect(phases.first, BookInstallPhase.downloading);
    expect(phases.contains(BookInstallPhase.installing), isTrue);
    expect(phases.last, BookInstallPhase.done);
    expect(remote.downloadCalls, 1);

    // The text is in the store, in order, and the book is marked installed.
    expect(local.text[bookId], hasLength(2));
    expect(local.text[bookId]!.first.text, 'نص الكتاب الأول');
    expect(local.downloaded, contains(bookId));
    expect(await repository.chunkCount(bookId), 2);

    // The archive is a transport: gone once its text is stored.
    expect(cache.listSync(), isEmpty);

    // Progress only ever moves forward, and ends at 1.
    double last = -1;
    for (final BookInstallProgress step in progress) {
      expect(step.ratio, greaterThanOrEqualTo(last));
      last = step.ratio;
    }
    expect(progress.last.ratio, 1);
  });

  test('removing a book drops its text but keeps the catalogue row', () async {
    await repository.syncIndex();
    const String bookId = '0238.IbnHabibQurtubi.MukhtasarFiTibb';
    await repository.install(bookId).drain<void>();

    await repository.remove(bookId);

    expect(local.text[bookId], isNull);
    expect(local.downloaded, isNot(contains(bookId)));
    expect(local.catalogue.containsKey(bookId), isTrue);
  });

  test('installing an unknown book fails instead of inventing one', () async {
    final List<BookInstallProgress> progress =
        await repository.install('nope').toList();

    expect(progress.single.phase, BookInstallPhase.failed);
    expect(progress.single.error, 'unknown-book');
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/shamila_library/data/services/book_archive_installer.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// The installer is the one piece that runs on another isolate, so it is tested
/// against a *real* zip built here rather than a mock: the archive format, the
/// JSONL payload and the port protocol all have to agree for a book to open.
void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('awan_installer_test');
  });

  tearDown(() async {
    // Windows keeps the archive's handle for a moment after the isolate is killed,
    // so the cleanup retries instead of failing a test that already passed on its
    // assertions.
    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        if (temp.existsSync()) await temp.delete(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
  });

  /// Writes a `.sqlite.zip` exactly as `tools/build_library_cdn.py` does: the
  /// canonical SQLite file, plus the JSONL twin the app reads.
  File buildArchive({
    required List<Map<String, Object?>> rows,
    bool withPayload = true,
  }) {
    final Archive archive = Archive();
    archive.addFile(
      ArchiveFile('book.sqlite', 4, <int>[1, 2, 3, 4]),
    );
    if (withPayload) {
      final List<int> payload = utf8.encode(
        rows.map(jsonEncode).join('\n'),
      );
      archive.addFile(
        ArchiveFile('book.jsonl', payload.length, payload),
      );
    }
    final File file = File('${temp.path}/book.sqlite.zip');
    file.writeAsBytesSync(ZipEncoder().encode(archive));
    return file;
  }

  test('unpacks a book and hands back its chunks in order', () async {
    final File archive = buildArchive(
      rows: <Map<String, Object?>>[
        <String, Object?>{
          'i': 0,
          't': 'باب العلم',
          'p': '9',
          'x': 'قال رسول الله ﷺ: من يرد الله به خيرا يفقهه في الدين',
        },
        <String, Object?>{'i': 1, 't': null, 'p': '10', 'x': 'ومما روي في ذلك'},
        <String, Object?>{'i': 2, 't': null, 'p': null, 'x': 'فصل'},
      ],
    );

    final List<BookChunk> received = <BookChunk>[];
    final List<double> ratios = <double>[];

    final int chunks = await BookArchiveInstaller.install(
      archivePath: archive.path,
      bookId: 'test.book',
      // One row per batch: proves the port protocol, not just the happy path.
      batchSize: 1,
      onBatch: (List<BookChunk> batch) async => received.addAll(batch),
      onProgress: (double ratio, int count) => ratios.add(ratio),
    );

    expect(chunks, 3);
    expect(received.map((BookChunk c) => c.index), <int>[0, 1, 2]);
    expect(received.first.title, 'باب العلم');
    expect(received.first.page, '9');
    expect(received.first.text, contains('يفقهه في الدين'));
    expect(received[1].page, '10');
    expect(received[2].page, isNull);
    // Arabic survives the port and the UTF-8 decode.
    expect(received.first.text, contains('ﷺ'));
    expect(ratios, isNotEmpty);
    expect(ratios.last, greaterThan(0));
  });

  test('a big payload arrives in batches without losing a row', () async {
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[
      for (int i = 0; i < 500; i++)
        <String, Object?>{
          'i': i,
          't': null,
          'p': '${i ~/ 20 + 1}',
          'x': 'سطر رقم $i من نص طويل بما يكفي ليعبر الحدود',
        },
    ];
    final File archive = buildArchive(rows: rows);

    final List<BookChunk> received = <BookChunk>[];
    final int chunks = await BookArchiveInstaller.install(
      archivePath: archive.path,
      bookId: 'big.book',
      onBatch: (List<BookChunk> batch) async => received.addAll(batch),
    );

    expect(chunks, 500);
    expect(received, hasLength(500));
    expect(received.first.index, 0);
    expect(received.last.index, 499);
    expect(received.last.text, contains('رقم 499'));
  });

  test('an archive with no readable payload fails loudly', () async {
    final File archive = buildArchive(
      rows: const <Map<String, Object?>>[],
      withPayload: false,
    );

    await expectLater(
      BookArchiveInstaller.install(
        archivePath: archive.path,
        bookId: 'broken',
        onBatch: (List<BookChunk> batch) async {},
      ),
      throwsA(isA<BookInstallException>()),
    );
  });

  test('a missing archive fails instead of reporting an empty book', () async {
    await expectLater(
      BookArchiveInstaller.install(
        archivePath: '${temp.path}/does-not-exist.zip',
        bookId: 'ghost',
        onBatch: (List<BookChunk> batch) async {},
      ),
      throwsA(isA<BookInstallException>()),
    );
  });
}

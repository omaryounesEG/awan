import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// Unpacks a downloaded book archive and streams its text back as chunks.
///
/// **Everything heavy happens off the UI isolate.** Inflating a multi-megabyte
/// deflate stream and JSON-parsing thousands of lines is the one long CPU stretch
/// in this feature; on the main isolate it is a visible stutter on the phone the
/// app is aimed at (an elderly-mode reader on a mid-range device).
///
/// Two deliberate choices:
///
/// * **`Isolate.spawn` and not `Isolate.run`/`compute`.** Those return one value
///   when the job is over; this job has a middle the UI must show. A `SendPort`
///   gives progress every batch.
/// * **The isolate never touches Isar.** Isar serialises writers per database and
///   opening a second instance on the same file is a documented foot-gun, so the
///   worker only *produces* records and the caller writes them — one transaction
///   per batch, each batch small enough to stay off the frame budget.
///
/// The archive carries a `<id>.jsonl` twin next to the canonical `<id>.sqlite`
/// (see `tools/build_library_cdn.py`). Reading SQLite would mean linking a native
/// engine into the app just to move text from one database to another; the JSONL
/// is the same text, decodable with `dart:convert`, in the isolate, with no
/// plugin and no platform channel.
class BookArchiveInstaller {
  const BookArchiveInstaller();

  /// Rows handed over per message: big enough to amortise the port, small enough
  /// that the main isolate never blocks on one write for long.
  static const int defaultBatchSize = 200;

  /// Returns the number of chunks installed.
  static Future<int> install({
    required String archivePath,
    required String bookId,
    required Future<void> Function(List<BookChunk>) onBatch,
    void Function(double ratio, int chapters)? onProgress,
    int batchSize = defaultBatchSize,
  }) async {
    final ReceivePort port = ReceivePort();
    Isolate? isolate;
    String? failure;
    int chapters = 0;

    try {
      isolate = await Isolate.spawn<_InstallJob>(
        _worker,
        _InstallJob(archivePath, bookId, port.sendPort, batchSize),
        onError: port.sendPort,
        onExit: port.sendPort,
        errorsAreFatal: true,
        debugName: 'awan-book-install',
      );

      await for (final Object? message in port) {
        // `onError` delivers [error, stackTrace]; anything else is a Map.
        if (message is List && message.length >= 2) {
          failure = 'isolate-error: ${message.first}';
          break;
        }
        if (message is! Map) continue;

        switch (message['t']) {
          case 'batch':
            final List<Object?> rows = (message['rows'] as List).cast<Object?>();
            await onBatch(<BookChunk>[
              for (final Object? row in rows) _toChunk(row as List<Object?>),
            ]);
          case 'progress':
            final int bytes = (message['bytes'] as num?)?.toInt() ?? 0;
            final int total = (message['total'] as num?)?.toInt() ?? 0;
            onProgress?.call(
              total <= 0 ? 0 : (bytes / total).clamp(0.0, 1.0),
              (message['chapters'] as num?)?.toInt() ?? 0,
            );
          case 'done':
            chapters = (message['chapters'] as num?)?.toInt() ?? 0;
            break;
          case 'error':
            failure = '${message['m']}';
        }
        if (message['t'] == 'done' || message['t'] == 'error') break;
      }
    } finally {
      port.close();
      isolate?.kill(priority: Isolate.immediate);
    }

    if (failure != null) throw BookInstallException(failure);
    return chapters;
  }

  static BookChunk _toChunk(List<Object?> row) => BookChunk(
        index: (row[0] as num).toInt(),
        title: row[1] as String?,
        page: row[2] as String?,
        text: '${row[3]}',
      );

  // ---------------------------------------------------------------- the worker
  static void _worker(_InstallJob job) {
    final SendPort port = job.port;
    // The handle is closed explicitly before this isolate ends. Without it,
    // Windows keeps a *killed* isolate's file handles until the whole process
    // exits, which makes the archive undeletable — a multi-megabyte temporary file
    // left behind after every book, and the kind of leak nobody notices until a
    // phone is full.
    InputFileStream? input;
    try {
      if (!File(job.archivePath).existsSync()) {
        port.send(<String, Object?>{'t': 'error', 'm': 'archive-missing'});
        return;
      }

      input = InputFileStream(job.archivePath);
      final Archive archive = ZipDecoder().decodeStream(input);

      ArchiveFile? payload;
      for (final ArchiveFile entry in archive.files) {
        if (entry.name.toLowerCase().endsWith('.jsonl')) {
          payload = entry;
          break;
        }
      }
      if (payload == null) {
        port.send(<String, Object?>{'t': 'error', 'm': 'no-readable-payload'});
        return;
      }

      final Uint8List? bytes = payload.readBytes();
      if (bytes == null || bytes.isEmpty) {
        port.send(<String, Object?>{'t': 'error', 'm': 'empty-payload'});
        return;
      }

      final List<int> line = <int>[];
      final List<List<Object?>> batch = <List<Object?>>[];
      int chapters = 0;

      void flushBatch(int consumed) {
        if (batch.isEmpty) return;
        port.send(<String, Object?>{'t': 'batch', 'rows': batch.toList()});
        batch.clear();
        // Reported after the batch so the bar never runs ahead of the rows the
        // main isolate has actually been handed.
        port.send(<String, Object?>{
          't': 'progress',
          'bytes': consumed,
          'chapters': chapters,
          'total': bytes.length,
        });
      }

      void consumeLine(int consumed) {
        final String text = utf8.decode(line, allowMalformed: true);
        line.clear();
        if (text.trim().isEmpty) return;
        final Object? decoded = jsonDecode(text);
        if (decoded is! Map) return;
        batch.add(<Object?>[
          (decoded['i'] as num?)?.toInt() ?? chapters,
          decoded['t'],
          decoded['p'],
          decoded['x'] ?? '',
        ]);
        chapters++;
        if (batch.length >= job.batchSize) flushBatch(consumed);
      }

      // `bytes` is the JSONL payload, so this ratio is the *unpacking* share of
      // the bar; the caller blends it with the download's own ratio.
      for (int i = 0; i < bytes.length; i++) {
        final int byte = bytes[i];
        if (byte == 10) {
          consumeLine(i + 1);
        } else if (byte != 13) {
          line.add(byte);
        }
      }
      consumeLine(bytes.length);
      flushBatch(bytes.length);

      // Closed before the caller is told the job is over, so the archive is
      // deletable the moment it is no longer needed.
      input.close();
      input = null;
      port.send(<String, Object?>{'t': 'done', 'chapters': chapters});
    } catch (error) {
      port.send(<String, Object?>{'t': 'error', 'm': error.toString()});
    } finally {
      input?.close();
    }
  }
}

class _InstallJob {
  const _InstallJob(this.archivePath, this.bookId, this.port, this.batchSize);

  final String archivePath;
  final String bookId;
  final SendPort port;
  final int batchSize;
}

/// A book archive the app could not read, with a code the UI can localise.
class BookInstallException implements Exception {
  const BookInstallException(this.code);

  final String code;

  @override
  String toString() => 'BookInstallException($code)';
}

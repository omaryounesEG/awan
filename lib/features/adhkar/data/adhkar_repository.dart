import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';

/// The bundled chapter: 24 adhkar with their text in two languages and the
/// recitation URL of each.
///
/// The text ships with the app (it is small and must work offline); the audio
/// does not — 24 files at ~1.3 MB each is a download the reader asks for, not
/// one they discover on their bill.
class AdhkarRepository {
  AdhkarRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const String assetPath = 'assets/adhkar/morning_evening.json';

  final Dio _dio;
  AdhkarChapter? _cached;

  Future<AdhkarChapter> load() async {
    if (_cached != null) return _cached!;
    final String raw = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(raw);
    final Map<Object?, Object?> doc =
        decoded is Map ? decoded : const <Object?, Object?>{};
    final List<Object?> rawItems =
        (doc['items'] as List<Object?>?) ?? const <Object?>[];
    final List<AdhkarItem> items = rawItems
        .map(AdhkarItem.fromJson)
        .whereType<AdhkarItem>()
        .toList(growable: false);
    return _cached = AdhkarChapter(
      titleAr: '${doc['title_ar'] ?? 'أذكار الصباح والمساء'}',
      titleEn: '${doc['title_en'] ?? 'Morning and evening remembrance'}',
      items: items,
    );
  }

  Future<Directory> _audioDir() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/adhkar_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Where a downloaded dhikr lives, or null when it has not been fetched.
  Future<String?> localAudio(int id) async {
    final Directory dir = await _audioDir();
    final File file = File('${dir.path}/$id.mp3');
    return await file.exists() && await file.length() > 1024 ? file.path : null;
  }

  /// Downloads one recitation with progress in 0..1, replacing a partial file.
  Future<String> downloadAudio(
    AdhkarItem item, {
    void Function(double progress)? onProgress,
  }) async {
    final Directory dir = await _audioDir();
    final File file = File('${dir.path}/${item.id}.mp3');
    final File part = File('${file.path}.part');
    if (await part.exists()) await part.delete();
    await _dio.download(
      item.audioUrl,
      part.path,
      onReceiveProgress: (int received, int total) {
        if (total > 0) onProgress?.call(received / total);
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    if (await part.length() < 1024) {
      await part.delete();
      throw const FileSystemException('الصوت لم ينزل كاملًا');
    }
    return (await part.rename(file.path)).path;
  }

  Future<void> deleteAudio(int id) async {
    final Directory dir = await _audioDir();
    for (final String suffix in <String>['', '.part']) {
      final File file = File('${dir.path}/$id.mp3$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  /// True when every item has a file on disk.
  Future<int> downloadedCount(List<AdhkarItem> items) async {
    int count = 0;
    for (final AdhkarItem item in items) {
      if (await localAudio(item.id) != null) count++;
    }
    return count;
  }
}

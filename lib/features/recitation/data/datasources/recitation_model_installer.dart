import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// One place the three Whisper files can be fetched from.
///
/// A build used to carry a single base URL, which is fine until the machine
/// that serves it changes address — then the button looks broken and says
/// nothing. Sources are therefore a *list*: the private mirror first (fast,
/// local), Hugging Face second (public, works anywhere). The first one that
/// answers wins, and if none does the caller gets a reason instead of silence.
class ModelSource {
  const ModelSource({
    required this.label,
    required this.base,
    this.nested = true,
  });

  /// Shown in the UI when a download falls back, so the user knows where the
  /// bytes came from.
  final String label;
  final String base;

  /// `true` for mirrors serving `/<base>/recitation/<file>`, `false` for a
  /// Hugging Face style `resolve/main/<file>` path.
  final bool nested;

  String urlFor(String name) =>
      nested ? '$base/recitation/$name' : '$base/$name';

  /// The upstream the app can always reach, no account and no key.
  static const ModelSource huggingFace = ModelSource(
    label: 'huggingface.co',
    base:
        'https://huggingface.co/Synthesium/quran-whisper-sherpa-onnx/resolve/main',
    nested: false,
  );
}

/// The three files Whisper needs, fetched once and then resident.
///
/// 160 MB of weights is not something to put inside an APK that people install
/// over a phone network: the app downloads them on first use, into the same
/// per-app folder the semantic encoder uses, and never asks again.
///
/// **Downloads resume.** A phone that loses signal at 60 % used to throw the
/// partial file away and start from zero, which on a 100 MB file over a mobile
/// connection means it never finished at all. The `.part` file is now kept
/// between attempts and between app launches, and each attempt asks the server
/// for the remainder with a `Range` header.
class RecitationModelInstaller {
  RecitationModelInstaller({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(minutes: 10),
                // Hugging Face answers with a redirect to the CDN that actually
                // holds the bytes; without this the download stalls on a 302.
                followRedirects: true,
                maxRedirects: 6,
              ),
            );

  final Dio _dio;

  static const List<String> files = <String>[
    'base-ar-quran-encoder.int8.onnx',
    'base-ar-quran-decoder.int8.onnx',
    'base-ar-quran-tokens.txt',
  ];

  /// Attempts per source, each one resuming where the last stopped.
  static const int attemptsPerSource = 4;

  Future<Directory> folder() async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory(p.join(support.path, 'recitation'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Map<String, String>> paths() async {
    final Directory dir = await folder();
    return <String, String>{
      for (final String name in files) name: p.join(dir.path, name),
    };
  }

  Future<bool> isInstalled() async {
    final Map<String, String> all = await paths();
    for (final String path in all.values) {
      final File file = File(path);
      if (!await file.exists()) return false;
      if (await file.length() < 1024) return false;
    }
    return true;
  }

  Future<int> installedBytes() async {
    int total = 0;
    for (final String path in (await paths()).values) {
      final File file = File(path);
      if (await file.exists()) total += await file.length();
    }
    return total;
  }

  /// Bytes already on disk for a file that is still incomplete — what the UI
  /// shows as "resuming from" rather than pretending nothing arrived.
  Future<int> partialBytes() async {
    final Directory dir = await folder();
    final Directory temp = Directory(p.join(dir.path, 'partial'));
    if (!await temp.exists()) return 0;
    int total = 0;
    await for (final FileSystemEntity entity in temp.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Downloads whatever is missing, trying each source in order per file.
  ///
  /// [onProgress] sees 0..1 across all files; [onSource] reports the mirror
  /// that actually served the bytes. Throws [ModelDownloadException] carrying
  /// the last real reason when every source fails.
  Future<void> install({
    required List<ModelSource> sources,
    void Function(double progress)? onProgress,
    void Function(ModelSource source)? onSource,
  }) async {
    final Map<String, String> targets = await paths();
    final List<String> missing = <String>[
      for (final String name in files)
        if (!await File(targets[name]!).exists()) name,
    ];
    if (missing.isEmpty) {
      onProgress?.call(1);
      return;
    }

    final Directory temp = Directory(p.join((await folder()).path, 'partial'));
    if (!await temp.exists()) await temp.create(recursive: true);

    for (int i = 0; i < missing.length; i++) {
      final String name = missing[i];
      final String partialPath = p.join(temp.path, '$name.part');
      Object? lastError;
      ModelSource? servedBy;

      for (final ModelSource source in sources) {
        for (int attempt = 0; attempt < attemptsPerSource; attempt++) {
          try {
            await _fetchInto(
              url: source.urlFor(name),
              path: partialPath,
              onProgress: (int received, int total) {
                final int overallTotal = total > 0 ? total : received;
                final double within =
                    overallTotal > 0 ? received / overallTotal : 0;
                onProgress?.call((i + within) / missing.length);
              },
            );
            final File part = File(partialPath);
            // A redirect to an HTML error page also "completes"; a model is
            // never a kilobyte, so this catches the difference before install.
            if (!await part.exists() || await part.length() < 1024) {
              throw const FormatException('empty_or_html_response');
            }
            await part.rename(targets[name]!);
            servedBy = source;
            break;
          } catch (error) {
            lastError = error;
            // The partial file is deliberately kept: the next attempt resumes
            // from it. Only a server that ignores `Range` forces a restart,
            // and `_fetchInto` is the one that decides that.
            if (attempt < attemptsPerSource - 1) {
              await Future<void>.delayed(Duration(seconds: 1 << attempt));
            }
          }
        }
        if (servedBy != null) break;
      }

      if (servedBy == null) throw ModelDownloadException(name, lastError);
      onSource?.call(servedBy);
    }

    // Nothing left to resume: a stale `.part` would only confuse `partialBytes`.
    if (temp.existsSync()) {
      for (final FileSystemEntity entity in temp.listSync()) {
        if (entity is File && entity.path.endsWith('.part')) {
          final String base = p.basename(entity.path).replaceAll('.part', '');
          if (File(targets[base] ?? '').existsSync()) await entity.delete();
        }
      }
    }
    onProgress?.call(1);
  }

  /// One HTTP attempt, resuming from whatever the `.part` file already holds.
  Future<void> _fetchInto({
    required String url,
    required String path,
    required void Function(int received, int total) onProgress,
  }) async {
    final File part = File(path);
    int have = await part.exists() ? await part.length() : 0;

    final Response<ResponseBody> response = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        maxRedirects: 6,
        // 206 is the success this method actually wants; 416 means the file is
        // already complete; everything else is handled below.
        validateStatus: (int? code) => code != null && code < 500,
        headers: <String, String>{
          'Accept': 'application/octet-stream',
          if (have > 0) 'Range': 'bytes=$have-',
        },
      ),
    );

    final int? status = response.statusCode;
    if (status == 416 && have > 0) return; // nothing left to fetch
    if (status != null && status >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response<dynamic>(
          requestOptions: response.requestOptions,
          statusCode: status,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    // A server that ignores `Range` answers 200 from byte zero; appending would
    // corrupt the file, so start over instead.
    if (have > 0 && status == 200) {
      await part.writeAsBytes(const <int>[]);
      have = 0;
    }

    final int total = _contentLength(response) ?? 0;
    final Stream<List<int>> stream = response.data!.stream;

    final IOSink sink =
        part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
    int received = have;
    try {
      await for (final List<int> chunk in stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total > 0 ? total : 0);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  int? _contentLength(Response<ResponseBody> response) {
    final String? rangeTotal = response.headers.value('content-range');
    if (rangeTotal != null && rangeTotal.contains('/')) {
      final String tail = rangeTotal.split('/').last.trim();
      return int.tryParse(tail);
    }
    final String? length = response.headers.value(Headers.contentLengthHeader);
    return length == null ? null : int.tryParse(length);
  }

  Future<void> remove() async {
    final Directory dir = await folder();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

class ModelDownloadException implements Exception {
  const ModelDownloadException(this.file, this.cause);

  final String file;
  final Object? cause;

  /// A short, localisable reason code — the UI maps it; it is never shown raw.
  String get reason {
    final Object? e = cause;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.badResponse:
          final int? code = e.response?.statusCode;
          return code == 404 ? 'not_found' : 'server_${code ?? 0}';
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.transformTimeout:
          return 'timeout';
        case DioExceptionType.connectionError:
          return 'offline';
        case DioExceptionType.badCertificate:
          return 'certificate';
        case DioExceptionType.cancel:
          return 'cancelled';
        case DioExceptionType.unknown:
          return 'offline';
      }
    }
    if (e is FormatException) return 'bad_payload';
    return 'unknown';
  }

  @override
  String toString() => 'ModelDownloadException($file, $cause)';
}

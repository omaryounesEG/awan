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
      final String partial = p.join(temp.path, '$name.part');
      Object? lastError;
      bool done = false;

      for (final ModelSource source in sources) {
        try {
          await _dio.download(
            source.urlFor(name),
            partial,
            onReceiveProgress: (int received, int total) {
              if (total <= 0) return;
              onProgress?.call((i + received / total) / missing.length);
            },
            options: Options(
              receiveTimeout: const Duration(minutes: 10),
              headers: const <String, String>{
                'Accept': 'application/octet-stream',
              },
            ),
          );
          final File part = File(partial);
          // A redirect to an HTML error page also "succeeds"; a model is never
          // a kilobyte, so this catches the difference before it is installed.
          if (!await part.exists() || await part.length() < 1024) {
            throw const FormatException('empty_or_html_response');
          }
          await part.rename(targets[name]!);
          onSource?.call(source);
          done = true;
          break;
        } catch (error) {
          lastError = error;
          final File part = File(partial);
          if (await part.exists()) await part.delete();
        }
      }

      if (!done) throw ModelDownloadException(name, lastError);
    }
    onProgress?.call(1);
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

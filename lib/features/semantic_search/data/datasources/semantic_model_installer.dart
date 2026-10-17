import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Fetches the 118 MB query encoder **once**, then never again.
///
/// The model is the only part of the semantic search that cannot be an asset:
/// bundled, it would double the APK. It lands in the app's private files
/// directory, the same path the native encoder looks at, so after this download
/// the whole feature runs with the radio off.
class SemanticModelInstaller {
  SemanticModelInstaller({Dio? dio}) : _dio = dio ?? Dio();

  static const String fileName = 'model_int8.onnx';

  final Dio _dio;

  Future<Directory> _directory() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory directory = Directory('${base.path}/semantic');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> modelFile() async =>
      File('${(await _directory()).path}/$fileName');

  /// Bytes already on disk, 0 when the model is missing.
  Future<int> installedBytes() async {
    final File file = await modelFile();
    return await file.exists() ? file.length() : 0;
  }

  /// Downloads from [baseUrl]/semantic/<file>, atomically.
  ///
  /// The `.part` suffix matters: a cancelled download must not leave a
  /// half-written file that the encoder would happily open.
  Future<int> download({
    required String baseUrl,
    void Function(double progress)? onProgress,
  }) async {
    final Directory directory = await _directory();
    final File target = File('${directory.path}/$fileName');
    final File partial = File('${directory.path}/$fileName.part');
    if (await partial.exists()) await partial.delete();

    final String url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/semantic/$fileName';
    await _dio.download(
      url,
      partial.path,
      deleteOnError: true,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
      onReceiveProgress: (int received, int total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    final int size = await partial.length();
    if (size < 1000000) {
      await partial.delete();
      throw StateError('the downloaded model is only $size bytes');
    }
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
    return size;
  }

  Future<void> remove() async {
    final File file = await modelFile();
    if (await file.exists()) await file.delete();
  }
}

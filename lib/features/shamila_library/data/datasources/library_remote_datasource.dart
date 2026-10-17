import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// The static host, seen as two operations: read the index, fetch one archive.
abstract class LibraryRemoteDataSource {
  Future<Map<String, dynamic>> fetchIndex(String baseUrl);

  /// Downloads [url] into [directory] and reports byte progress.
  Future<File> downloadArchive({
    required String url,
    required String fileName,
    required Directory directory,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  });
}

class DioLibraryRemoteDataSource implements LibraryRemoteDataSource {
  DioLibraryRemoteDataSource(this._dio);

  final Dio _dio;

  static const String indexPath = 'library_index.json';

  @override
  Future<Map<String, dynamic>> fetchIndex(String baseUrl) async {
    final String root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final Response<String> response = await _dio.get<String>(
      '$root/$indexPath',
      options: Options(
        responseType: ResponseType.plain,
        headers: <String, String>{'Accept': 'application/json'},
      ),
    );
    final Object? decoded = jsonDecodeUtf8(response.data ?? '');
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('library_index.json is not an object');
    }
    return decoded;
  }

  @override
  Future<File> downloadArchive({
    required String url,
    required String fileName,
    required Directory directory,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final Directory dir = await directory.create(recursive: true);
    final File target = File('${dir.path}/$fileName');
    if (await target.exists()) await target.delete();
    await _dio.download(
      url,
      target.path,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(followRedirects: true),
    );
    return target;
  }
}

/// `jsonDecode` with the encoding pitfalls of a static host handled once: UTF-8
/// is assumed (Arabic titles are the whole point), and an empty or truncated body
/// is an error rather than a silently empty catalogue.
Object? jsonDecodeUtf8(String body) {
  final String trimmed = body.trim();
  if (trimmed.isEmpty) throw const FormatException('empty body');
  return jsonDecode(utf8.decode(utf8.encode(trimmed), allowMalformed: true));
}

/// Convenience for the repositories: is this URL a real one to fetch?
bool isFetchable(String url) {
  final Uri? uri = Uri.tryParse(url);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

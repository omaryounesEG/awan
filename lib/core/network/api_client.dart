import 'package:dio/dio.dart';

/// One configured Dio for the whole app.
///
/// * a descriptive `User-Agent` (Overpass and Nominatim reject anonymous ones),
/// * two silent retries on connection hiccups,
/// * no request ever hangs the UI for more than 30s.
class ApiClient {
  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 20),
                headers: const <String, String>{
                  'User-Agent': 'AwanApp/1.0 (Flutter; offline-first prayer app)',
                  'Accept': 'application/json',
                },
                responseType: ResponseType.json,
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onError: (DioException error, ErrorInterceptorHandler handler) async {
              final RequestOptions options = error.requestOptions;
              final int attempt = (options.extra['attempt'] as int?) ?? 0;
              final bool retryable = error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.connectionError;
              if (retryable && attempt < 2) {
                options.extra['attempt'] = attempt + 1;
                try {
                  final Response<dynamic> response = await this.dio.fetch(options);
                  return handler.resolve(response);
                } catch (_) {
                  // fall through to the original error
                }
              }
              return handler.next(error);
            },
          ),
        );
  }

  final Dio dio;

  /// Overpass answers with 400/429/504 when it is busy; callers rotate mirrors.
  Future<Response<dynamic>> postOverpass(String endpoint, String query) {
    return dio.post<dynamic>(
      endpoint,
      data: <String, String>{'data': query},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 40),
      ),
    );
  }
}

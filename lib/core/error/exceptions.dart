import 'package:dio/dio.dart';

/// Data-layer exceptions. They never cross into the domain: a repository
/// catches them and converts them into a [Failure].
///
/// See `core/error/failures.dart` for the translation table.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause == null ? '' : ' ($cause)'}';
}

class ServerException extends AppException {
  const ServerException({String? message, Object? cause, this.statusCode})
      : super(message ?? 'Server error', cause: cause);

  final int? statusCode;

  /// Maps Dio's error taxonomy onto our own, once, in one place.
  static ServerException fromDio(DioException error) {
    return ServerException(
      message: error.message ?? 'Server error',
      cause: error,
      statusCode: error.response?.statusCode,
    );
  }
}

class NetworkException extends AppException {
  const NetworkException({String? message, Object? cause})
      : super(message ?? 'No internet connection', cause: cause);
}

class CacheException extends AppException {
  const CacheException({String? message, Object? cause})
      : super(message ?? 'Local storage error', cause: cause);
}

class PermissionException extends AppException {
  const PermissionException({String? message, Object? cause})
      : super(message ?? 'Permission denied', cause: cause);
}

class ParseException extends AppException {
  const ParseException({String? message, Object? cause})
      : super(message ?? 'Could not parse the payload', cause: cause);
}

/// Thrown by data sources that are not implemented on the current platform
/// (e.g. the auto-silent automation on iOS).
class UnsupportedPlatformException extends AppException {
  const UnsupportedPlatformException({String? message})
      : super(message ?? 'Not supported on this platform');
}

/// The Google Places data source was asked for results without a key baked into
/// the build. The repository catches this and answers from OpenStreetMap instead.
class PlacesKeyMissingException extends AppException {
  const PlacesKeyMissingException({String? message})
      : super(message ?? 'No Google Places key configured');
}

import 'package:equatable/equatable.dart';

/// Domain failures.
///
/// Every operation that can fail for a *reason the user can act on* returns
/// `Either<Failure, T>` (see `core/utils/extensions.dart`). Pure offline
/// computations (prayer arithmetic, Quran lookups) deliberately return plain
/// values instead: if they fail it is a bug, not a domain outcome.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  /// Already-localised-enough English message; the presentation layer maps the
  /// type to an ARB string, never the other way round.
  final String message;

  /// Technical detail kept for logs, never shown to the user.
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[message, cause];
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message, Object? cause})
      : super(message ?? 'Network unavailable', cause: cause);
}

class ServerFailure extends Failure {
  const ServerFailure({String? message, Object? cause, this.statusCode})
      : super(message ?? 'Server error', cause: cause);

  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[message, statusCode, cause];
}

class CacheFailure extends Failure {
  const CacheFailure({String? message, Object? cause})
      : super(message ?? 'Local storage error', cause: cause);
}

class LocationFailureReason extends Failure {
  const LocationFailureReason({String? message, Object? cause})
      : super(message ?? 'Location unavailable', cause: cause);
}

class PermissionFailure extends Failure {
  const PermissionFailure({String? message, Object? cause})
      : super(message ?? 'Permission denied', cause: cause);
}

class ParseFailure extends Failure {
  const ParseFailure({String? message, Object? cause})
      : super(message ?? 'Could not read this file', cause: cause);
}

class UnsupportedFailure extends Failure {
  const UnsupportedFailure({String? message, Object? cause})
      : super(message ?? 'Not supported on this device', cause: cause);
}

/// The radar wanted Google Places but no API key was baked into the build.
///
/// It is a *configuration* state, not an error: the UI says so in one calm line
/// and the repository quietly switches to OpenStreetMap results.
class PlacesKeyMissingFailure extends Failure {
  const PlacesKeyMissingFailure({String? message, Object? cause})
      : super(message ?? 'No Google Places key configured', cause: cause);
}

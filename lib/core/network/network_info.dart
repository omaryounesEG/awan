import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/error/failures.dart';

/// "Am I online?" in one place, so no data source invents its own check and the
/// app never blocks an offline-first read behind a network probe.
class NetworkInfo {
  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  bool? _lastKnown;

  Future<bool> get isConnected async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final bool online =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      _lastKnown = online;
      return online;
    } catch (_) {
      // If we cannot tell, assume online: an unnecessary request is cheaper
      // than hiding data the user explicitly asked for.
      return _lastKnown ?? true;
    }
  }

  /// Runs [action] only when online and converts every data-layer exception
  /// into the matching domain [Failure] — the single translation point.
  Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
    if (!await isConnected) {
      return left<Failure, T>(const NetworkFailure());
    }
    try {
      return right<Failure, T>(await action());
    } on DioException catch (error) {
      final int? status = error.response?.statusCode;
      if (status == null) {
        return left<Failure, T>(NetworkFailure(cause: error));
      }
      return left<Failure, T>(ServerFailure(cause: error, statusCode: status));
    } on ServerException catch (error) {
      return left<Failure, T>(
        ServerFailure(message: error.message, cause: error, statusCode: error.statusCode),
      );
    } on NetworkException catch (error) {
      return left<Failure, T>(NetworkFailure(message: error.message, cause: error));
    } on PermissionException catch (error) {
      return left<Failure, T>(PermissionFailure(message: error.message, cause: error));
    } on CacheException catch (error) {
      return left<Failure, T>(CacheFailure(message: error.message, cause: error));
    } on ParseException catch (error) {
      return left<Failure, T>(ParseFailure(message: error.message, cause: error));
    } on UnsupportedPlatformException catch (error) {
      return left<Failure, T>(UnsupportedFailure(message: error.message, cause: error));
    } on PlacesKeyMissingException catch (error) {
      return left<Failure, T>(PlacesKeyMissingFailure(message: error.message, cause: error));
    } on AppException catch (error) {
      // The base `Failure` is abstract: an unclassified app exception is
      // reported as a server failure so it still carries a typed `Failure`.
      return left<Failure, T>(
        ServerFailure(message: error.message, cause: error),
      );
    }
  }
}

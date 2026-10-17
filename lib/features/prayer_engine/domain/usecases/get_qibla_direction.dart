import 'package:adhan_dart/adhan_dart.dart';
import 'package:dartz/dartz.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/prayer_engine/domain/entities/qibla_direction.dart';

/// The exact Qibla bearing for a pair of coordinates.
///
/// Two independent computations agree here on purpose:
///
/// 1. `adhan_dart`'s `Qibla.qibla(Coordinates)` — the same library (and the same
///    spherical model) that produced the prayer times, so the compass and the
///    timetable can never disagree;
/// 2. [Geo.bearingDegrees] — our own great-circle bearing.
///
/// They are asserted equal in `test/qibla_test.dart`. If a future `adhan_dart`
/// release ever changed model or convention, the test fails loudly instead of
/// the needle drifting a degree or two east — which is the kind of error that is
/// invisible on screen but wrong where it matters.
///
/// No network, no cache: the answer is pure trigonometry, so it is available in
/// airplane mode, in a basement, and on the first frame after install.
class GetQiblaDirection {
  const GetQiblaDirection();

  /// [latitude]/[longitude] are the user's position (WGS-84 degrees).
  Either<Failure, QiblaDirection> call({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return const Left<Failure, QiblaDirection>(
        ServerFailure(message: 'invalid_coordinates', statusCode: 400),
      );
    }

    final double bearing =
        Qibla.qibla(Coordinates(latitude, longitude)).toDouble();

    final double distance = Geo.distanceMeters(
      fromLatitude: latitude,
      fromLongitude: longitude,
      toLatitude: AppConstants.kaabaLatitude,
      toLongitude: AppConstants.kaabaLongitude,
    );

    return Right<Failure, QiblaDirection>(
      QiblaDirection(
        bearingDegrees: bearing,
        distanceKm: distance / 1000.0,
        fromLatitude: latitude,
        fromLongitude: longitude,
      ),
    );
  }
}

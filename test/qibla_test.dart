import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/prayer_engine/domain/entities/qibla_direction.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_qibla_direction.dart';

/// The qibla is a religious obligation, not a UI detail: a few degrees of error
/// is a real error. Two independent computations are compared, and the +/-2
/// degrees alignment window is pinned at its edges.
void main() {
  const GetQiblaDirection qibla = GetQiblaDirection();

  group('GetQiblaDirection', () {
    test('Cairo points at the qibla within a fraction of a degree', () {
      final QiblaDirection? direction = qibla(
        latitude: 30.0444,
        longitude: 31.2357,
      ).valueOrNull;

      expect(direction, isNotNull);
      // Published value for Cairo is ~136.2 degrees from true north, and the
      // great-circle distance to the Kaaba is ~1,287 km (cross-checked with an
      // independent haversine).
      expect(direction!.bearingDegrees, closeTo(136.2, 0.3));
      expect(direction.distanceKm, closeTo(1287, 25));
    });

    test('agrees with adhan_dart for five very different cities', () {
      const List<List<double>> cities = <List<double>>[
        <double>[30.0444, 31.2357], // Cairo
        <double>[24.7136, 46.6753], // Riyadh
        <double>[15.5007, 32.5599], // Khartoum
        <double>[-6.2088, 106.8456], // Jakarta
        <double>[40.7128, -74.0060], // New York (the western hemisphere)
      ];

      for (final List<double> city in cities) {
        final double fromLibrary =
            Qibla.qibla(Coordinates(city[0], city[1])).toDouble();
        final double fromOurs = Geo.bearingDegrees(
          fromLatitude: city[0],
          fromLongitude: city[1],
          toLatitude: AppConstants.kaabaLatitude,
          toLongitude: AppConstants.kaabaLongitude,
        );

        expect(
          Geo.shortestAngleDelta(fromOurs, fromLibrary).abs(),
          lessThan(0.05),
          reason: 'mismatch at ${city[0]}, ${city[1]}',
        );
      }
    });

    test('rejects coordinates that are not on Earth', () {
      expect(
        qibla(latitude: 91, longitude: 31).isLeft(),
        isTrue,
      );
      expect(
        qibla(latitude: double.nan, longitude: 31).failureOrNull,
        isA<ServerFailure>(),
      );
    });
  });

  group('alignment window', () {
    test('accepts the two-degree band and nothing wider', () {
      expect(Geo.isAligned(136.0, 136.2), isTrue);
      expect(Geo.isAligned(138.3, 136.2), isFalse); // 2.1 degrees off
      expect(Geo.isAligned(134.0, 136.2), isFalse); // 2.2 degrees off
      expect(Geo.isAligned(134.3, 136.2), isTrue); // 1.9 degrees: inside
    });

    test('works across the 0/360 seam', () {
      // Facing 359 when the qibla is 1: two degrees apart, not 358.
      expect(Geo.isAligned(359.0, 1.0), isTrue);
      expect(Geo.shortestAngleDelta(1.0, 359.0), closeTo(2.0, 1e-9));
      expect(Geo.shortestAngleDelta(359.0, 1.0), closeTo(-2.0, 1e-9));
    });

    test('the smoothing step never takes the long way round', () {
      // A naive lerp here would send the needle from 359 to 1 through 180.
      expect(Geo.smoothAngle(359.0, 1.0, 1.0), closeTo(1.0, 1e-9));
      expect(Geo.smoothAngle(10.0, 350.0, 1.0), closeTo(350.0, 1e-9));
      // Halfway towards a target two degrees away: one degree, not 179.
      expect(Geo.smoothAngle(0.0, 2.0, 0.5), closeTo(1.0, 1e-9));
    });
  });

  group('distance helpers', () {
    test('haversine matches a known city pair', () {
      // Cairo -> Alexandria is ~180 km great-circle.
      final double meters = Geo.distanceMeters(
        fromLatitude: 30.0444,
        fromLongitude: 31.2357,
        toLatitude: 31.2001,
        toLongitude: 29.9187,
      );
      expect(meters / 1000, closeTo(180, 6));
    });

    test('walking time never rounds down to zero', () {
      expect(Geo.walkingMinutes(400), 5);
      expect(Geo.walkingMinutes(30), 1);
      expect(Geo.walkingMinutes(0), 1);
    });

    test('cell keys are stable and rounded', () {
      expect(Geo.cellKey(30.04441, 31.23571), '30.04:31.24');
    });
  });
}

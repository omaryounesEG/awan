import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';

/// The fence is only as good as the two numbers it rests on: the radius the
/// reader chose, and the distance the app computes against it.
void main() {
  test('the fence radius survives a store round-trip', () {
    final UserMosque mosque = UserMosque(
      id: 'user:1',
      latitude: 30.0444,
      longitude: 31.2357,
      createdAt: DateTime(2026, 10, 19),
      name: 'مسجد الاختبار',
      accuracyMeters: 5,
      radiusMeters: 30,
    );
    final UserMosque? back = UserMosque.fromJson(mosque.toJson());
    expect(back, isNotNull);
    expect(back!.radiusMeters, 30);
    expect(back.accuracyMeters, 5);
    expect(back.name, 'مسجد الاختبار');
  });

  test('an old record without a radius falls back to ten metres', () {
    final UserMosque? back = UserMosque.fromJson(<String, Object?>{
      'id': 'user:2',
      'lat': 30.0,
      'lng': 31.0,
      'createdAt': '2026-01-01T00:00:00.000',
    });
    expect(back!.radiusMeters, UserMosque.defaultRadiusMeters);
  });

  test('distance matches the native check that gates the silence', () {
    // ~318 m east of the recorded point, the figure the device reported.
    final double away = Geo.distanceMeters(
      fromLatitude: 30.0444,
      fromLongitude: 31.2357,
      toLatitude: 30.0444,
      toLongitude: 31.2390,
    );
    expect(away, closeTo(318, 6));
    expect(away > UserMosque.defaultRadiusMeters, isTrue);

    final double here = Geo.distanceMeters(
      fromLatitude: 30.0444,
      fromLongitude: 31.2357,
      toLatitude: 30.0444,
      toLongitude: 31.2357,
    );
    expect(here, 0);
  });
}

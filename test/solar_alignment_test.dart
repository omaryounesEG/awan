import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/usecases/solar_position.dart';

/// The sun is the only qibla reference that cannot drift: no magnetometer, no
/// metal, no car dashboard. These numbers are not asserted against the
/// implementation's own output — they come from `astral`, an independent
/// ephemeris, for Cairo:
///
///   az 164.556°, elev 49.474°  at 2026-10-17 09:00 UTC
///   az 225.964°, elev 38.267°  at 2026-10-17 12:00 UTC
///   az 190.446°, elev 35.812°  at 2026-12-21 10:30 UTC
void main() {
  const SolarPositionCalculator sun = SolarPositionCalculator();
  const double lat = 30.0444;
  const double lon = 31.2357;

  SolarPosition at(String iso) => sun(
        instant: DateTime.parse(iso),
        latitude: lat,
        longitude: lon,
      );

  test('matches an independent ephemeris to a fraction of a degree', () {
    final SolarPosition morning = at('2026-10-17T09:00:00Z');
    expect(morning.azimuth, closeTo(164.556, 0.4));
    expect(morning.elevation, closeTo(49.474, 0.4));

    final SolarPosition noon = at('2026-10-17T12:00:00Z');
    expect(noon.azimuth, closeTo(225.964, 0.4));
    expect(noon.elevation, closeTo(38.267, 0.4));

    final SolarPosition solstice = at('2026-12-21T10:30:00Z');
    expect(solstice.azimuth, closeTo(190.446, 0.4));
    expect(solstice.elevation, closeTo(35.812, 0.4));
  });

  test('knows the sun is not up at midnight', () {
    expect(at('2026-10-17T00:00:00Z').isUp, isFalse);
    expect(at('2026-10-17T09:00:00Z').isUp, isTrue);
  });

  test('the offset to the qibla wraps at 180°, not at 360°', () {
    // Cairo's qibla bearing is ~136°; the noon sun (~226°) is 90° away.
    expect(at('2026-10-17T12:00:00Z').offsetFrom(136.0), closeTo(90.0, 0.6));
    // A bearing just west of north must not look 350° away.
    const SolarPosition sunAt330 = SolarPosition(
      azimuth: 330,
      elevation: 10,
      declination: 0,
    );
    expect(sunAt330.offsetFrom(20), closeTo(50, 1e-9));
  });

  test('the same moment gives the same sun in every time zone', () {
    final SolarPosition utc = at('2026-10-17T12:00:00Z');
    final SolarPosition cairo = sun(
      instant: DateTime.parse('2026-10-17T15:00:00+03:00'),
      latitude: lat,
      longitude: lon,
    );
    expect(cairo.azimuth, closeTo(utc.azimuth, 1e-9));
  });
}

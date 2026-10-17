import 'dart:math' as math;

/// Where the sun stands, as seen from a point on the ground.
class SolarPosition {
  const SolarPosition({
    required this.azimuth,
    required this.elevation,
    required this.declination,
  });

  /// Degrees clockwise from **true** north.
  final double azimuth;

  /// Degrees above the horizon (negative when the sun has set).
  final double elevation;

  /// The sun's declination, in degrees — reused by the prayer engine.
  final double declination;

  bool get isUp => elevation > 0;

  /// How far the sun is from the direction of the qibla, in degrees (0–180).
  ///
  /// This is the offline answer to "which way is the qibla?" on a phone whose
  /// magnetometer is unreliable — a case the PDF singles out: metal, a car, a
  /// desk. The sun's position is astronomy, not a sensor reading, so it cannot
  /// drift; when this angle is small, looking at your own shadow tells you the
  /// qibla to within a couple of degrees.
  double offsetFrom(double trueBearing) {
    final double delta = (azimuth - trueBearing).abs() % 360.0;
    return delta > 180.0 ? 360.0 - delta : delta;
  }
}

/// The sun's position from first principles — no network, no sensor.
///
/// NOAA's low-precision solar position algorithm (the one behind
/// [solar_position] in most almanacs): good to ~0.01° for dates within a century
/// of 2000, which is far below the 1–6° error the compass itself carries.
/// `test/solar_alignment_test.dart` pins it against an independent ephemeris
/// (`astral`) so the numbers are not taken on trust.
class SolarPositionCalculator {
  const SolarPositionCalculator();

  static const double _rad = math.pi / 180.0;
  static const double _deg = 180.0 / math.pi;

  SolarPosition call({
    required DateTime instant,
    required double latitude,
    required double longitude,
  }) {
    final DateTime utc = instant.toUtc();

    // Days since J2000.0 (2000-01-01 12:00 UTC).
    final double jd = _julianDay(utc);
    final double n = jd - 2451545.0;

    // Mean longitude and anomaly of the sun.
    final double l = (280.460 + 0.9856474 * n) % 360.0;
    final double g = ((357.528 + 0.9856003 * n) % 360.0) * _rad;

    // Ecliptic longitude.
    final double lambda =
        (l + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) * _rad;

    // Obliquity of the ecliptic.
    final double epsilon = (23.439 - 0.0000004 * n) * _rad;

    // Equatorial coordinates.
    final double rightAscension =
        math.atan2(math.cos(epsilon) * math.sin(lambda), math.cos(lambda));
    final double declination = math.asin(math.sin(epsilon) * math.sin(lambda));

    // Greenwich mean sidereal time, in degrees. The two small terms take
    // *centuries* since J2000 — passing days here tilts the sun by an hour.
    final double t = n / 36525.0;
    final double gmst = (280.46061837 +
            360.98564736629 * n +
            0.000387933 * t * t -
            t * t * t / 38710000.0) %
        360.0;

    // Local hour angle.
    final double hourAngle =
        (gmst + longitude - rightAscension * _deg) * _rad;

    final double phi = latitude * _rad;
    final double sinAlt = math.sin(phi) * math.sin(declination) +
        math.cos(phi) * math.cos(declination) * math.cos(hourAngle);
    final double altitude = math.asin(sinAlt);

    // Azimuth measured from true north, clockwise.
    final double cosAz = (math.sin(declination) - math.sin(phi) * sinAlt) /
        (math.cos(phi) * math.cos(altitude));
    double azimuth = math.acos(cosAz.clamp(-1.0, 1.0)) * _deg;
    if (math.sin(hourAngle) > 0) azimuth = 360.0 - azimuth;

    return SolarPosition(
      azimuth: azimuth % 360.0,
      elevation: altitude * _deg,
      declination: declination * _deg,
    );
  }

  double _julianDay(DateTime utc) {
    final int year = utc.year;
    final int month = utc.month;
    final double day =
        utc.day + (utc.hour + utc.minute / 60.0 + utc.second / 3600.0) / 24.0;

    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = (y / 100).floor();
    final int b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }
}

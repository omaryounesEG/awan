import 'dart:math' as math;

/// Spherical geometry helpers shared by the qibla and the mosque radar.
///
/// They are deliberately dependency-free and pure so every number the user sees
/// (a bearing, a distance, a walking time) is unit-testable without a device,
/// a network or a database.
class Geo {
  Geo._();

  /// Mean Earth radius (IUGG), metres.
  static const double earthRadiusMeters = 6371008.8;

  /// Walking speed used for every "x min walk" label: 4.86 km/h, the figure the
  /// WHO uses for an unhurried adult pace. It is intentionally conservative —
  /// an elderly user is the person this app is built for.
  static const double walkingMetersPerSecond = 1.35;

  static double _rad(double degrees) => degrees * math.pi / 180.0;

  /// Great-circle bearing from `(lat1,lng1)` to `(lat2,lng2)`, degrees in
  /// `[0, 360)` clockwise from **true north** — the same convention as
  /// `adhan_dart`'s qibla, so the two can be compared directly.
  static double bearingDegrees({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final double phi1 = _rad(fromLatitude);
    final double phi2 = _rad(toLatitude);
    final double dLambda = _rad(toLongitude - fromLongitude);

    final double y = math.sin(dLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);

    final double degrees = math.atan2(y, x) * 180.0 / math.pi;
    return (degrees + 360.0) % 360.0;
  }

  /// Great-circle (haversine) distance in metres.
  static double distanceMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final double phi1 = _rad(fromLatitude);
    final double phi2 = _rad(toLatitude);
    final double dPhi = _rad(toLatitude - fromLatitude);
    final double dLambda = _rad(toLongitude - fromLongitude);

    final double a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return 2 * earthRadiusMeters * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Minutes on foot for [meters], never less than one.
  static int walkingMinutes(double meters) =>
      math.max(1, (meters / walkingMetersPerSecond / 60).round());

  /// Signed difference `a - b` folded into `(-180, 180]`, i.e. the shortest way
  /// round the circle. Used for the compass needle and for the +/-2 degrees
  /// "aligned" test, both of which must not care that 359 is next to 1.
  static double shortestAngleDelta(double a, double b) {
    double delta = (a - b) % 360.0;
    if (delta > 180.0) delta -= 360.0;
    if (delta <= -180.0) delta += 360.0;
    return delta;
  }

  /// `true` when the device heading is within [tolerance] degrees of the qibla
  /// bearing, measured the short way round.
  static bool isAligned(
    double heading,
    double target, {
    double tolerance = 2.0,
  }) =>
      shortestAngleDelta(heading, target).abs() <= tolerance;

  /// One low-pass step of a **circular** exponential moving average.
  ///
  /// A plain `a + (b - a) * t` breaks at the wrap (359 -> 1 moves 358 degrees
  /// the long way, so the needle visibly spins the wrong way). Smoothing the
  /// wrapped delta keeps the motion monotonic everywhere on the circle.
  static double smoothAngle(double current, double next, double factor) =>
      (current + shortestAngleDelta(next, current) * factor) % 360.0;

  /// A `lat:lon` key rounded to [decimals] places — the cache key of the radar.
  static String cellKey(double latitude, double longitude, {int decimals = 2}) =>
      '${latitude.toStringAsFixed(decimals)}:${longitude.toStringAsFixed(decimals)}';
}

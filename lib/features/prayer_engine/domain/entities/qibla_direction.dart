import 'package:equatable/equatable.dart';

/// Where the Kaaba is, and how far the user is from it.
///
/// The bearing is what the compass renders; the distance is what the screen
/// uses for the calm line under the dial ("1,339 km to Makkah").
class QiblaDirection extends Equatable {
  const QiblaDirection({
    required this.bearingDegrees,
    required this.distanceKm,
    required this.fromLatitude,
    required this.fromLongitude,
  });

  /// Degrees clockwise from **true north**.
  final double bearingDegrees;

  /// Great-circle distance to Makkah, kilometres.
  final double distanceKm;

  final double fromLatitude;
  final double fromLongitude;

  @override
  List<Object?> get props =>
      <Object?>[bearingDegrees, distanceKm, fromLatitude, fromLongitude];
}

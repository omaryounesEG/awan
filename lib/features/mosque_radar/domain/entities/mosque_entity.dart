import 'package:equatable/equatable.dart';

/// A mosque the radar can walk to.
///
/// Pure domain value: no JSON, no `Isar`, no `LatLng`. The `data` layer parses
/// Google Places and OpenStreetMap payloads into this, and the presentation layer
/// only ever formats it.
class MosqueEntity extends Equatable {
  const MosqueEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.address,
    this.provider = 'osm',
  });

  /// Place id (Google) or OSM element id — stable enough to key a marker.
  final String id;

  final String name;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the search point, metres.
  final double distanceMeters;

  /// `vicinity` (Google) or `addr:*` (OSM) when the source knows one.
  final String? address;

  /// `google` | `osm` — shown in the UI so the user knows where data came from.
  final String provider;

  /// Minutes on foot, from the same 1.35 m/s pace the rest of the app uses.
  int get walkingMinutes => _walkingMinutesFrom(distanceMeters);

  static int _walkingMinutesFrom(double meters) {
    final int minutes = (meters / 1.35 / 60).round();
    return minutes < 1 ? 1 : minutes;
  }

  MosqueEntity copyWith({double? distanceMeters}) => MosqueEntity(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        address: address,
        provider: provider,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'distance': distanceMeters,
        'address': address,
        'provider': provider,
      };

  static MosqueEntity fromJson(Map<String, dynamic> json) => MosqueEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String?,
        provider: json['provider'] as String? ?? 'osm',
      );

  @override
  List<Object?> get props => <Object?>[id, name, latitude, longitude];
}

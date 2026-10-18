import 'package:flutter/foundation.dart';

/// A mosque the reader placed themselves, from inside it or in front of it.
///
/// The public map data is incomplete in exactly the places this app is used:
/// a small neighbourhood mosque in a village is often missing from OSM, and a
/// reader standing in it is told "no mosques nearby". Adding one is a two-tap
/// fix, and it stays on the device — there is no account to attach it to.
@immutable
class UserMosque {
  const UserMosque({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.name,
    this.accuracyMeters = defaultAccuracyMeters,
  });

  /// The circle the reader is telling us the mosque occupies: standing inside
  /// it or at its door is the same place, ten metres either way.
  static const double defaultAccuracyMeters = 10;

  final String id;
  final String? name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  /// How precisely the position was captured, shown next to the pin.
  final double accuracyMeters;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'createdAt': createdAt.toIso8601String(),
        'accuracy': accuracyMeters,
      };

  static UserMosque? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? lat = raw['lat'];
    final Object? lng = raw['lng'];
    if (lat is! num || lng is! num) return null;
    return UserMosque(
      id: '${raw['id'] ?? ''}',
      name: (raw['name'] as String?)?.trim(),
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      createdAt:
          DateTime.tryParse('${raw['createdAt'] ?? ''}') ?? DateTime.now(),
      accuracyMeters:
          (raw['accuracy'] as num?)?.toDouble() ?? defaultAccuracyMeters,
    );
  }
}

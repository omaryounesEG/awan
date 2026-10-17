import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';

/// Mosques near a point, nearest first.
///
/// The repository hides *where* the answer came from — Google Places when the
/// build carries a key, OpenStreetMap otherwise — and hides the cache. Callers
/// only decide whether they want to pay for freshness.
abstract class MosqueRepository {
  Future<Either<Failure, List<MosqueEntity>>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters,
    bool forceRefresh,
  });

  /// The provider that actually answered last time (`google` | `osm` | `cache`).
  ///
  /// Surfaced so the radar can say "Google Places" or "OpenStreetMap" instead of
  /// implying that every result is equally authoritative.
  String? get lastProvider;
}

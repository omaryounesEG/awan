import 'package:dartz/dartz.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/domain/repositories/mosque_repository.dart';

/// "Mosques near me", trimmed to what the radar shows.
///
/// Sorting and trimming live here rather than in the widget so the same five
/// mosques drive the markers **and** the card list — one source, one order.
class GetNearbyMosques {
  const GetNearbyMosques(this._repository);

  final MosqueRepository _repository;

  Future<Either<Failure, List<MosqueEntity>>> call({
    required double latitude,
    required double longitude,
    int radiusMeters = AppConstants.mosqueRadiusMeters,
    bool forceRefresh = false,
    int limit = AppConstants.radarTopMosques,
  }) async {
    final Either<Failure, List<MosqueEntity>> result =
        await _repository.nearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      forceRefresh: forceRefresh,
    );

    return result.map((List<MosqueEntity> mosques) {
      final List<MosqueEntity> sorted = <MosqueEntity>[...mosques]
        ..sort(
          (MosqueEntity a, MosqueEntity b) =>
              a.distanceMeters.compareTo(b.distanceMeters),
        );
      return sorted.take(limit).toList(growable: false);
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/mosque_radar/data/cache/mosque_cache_store.dart';
import 'package:awan/features/mosque_radar/data/datasources/google_places_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/nominatim_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/osm_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/repositories/mosque_repository_impl.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/domain/repositories/mosque_repository.dart';
import 'package:awan/features/mosque_radar/domain/usecases/get_nearby_mosques.dart';

// ---------------------------------------------------------------- data layer

final Provider<GooglePlacesMosqueDataSource>
    googlePlacesMosqueDataSourceProvider =
    Provider<GooglePlacesMosqueDataSource>(
  (Ref ref) => GooglePlacesMosqueDataSource(ref.watch(apiClientProvider)),
);

/// The keyless tiers, in the order the repository tries them.
final Provider<OsmMosqueDataSource> osmMosqueDataSourceProvider =
    Provider<OsmMosqueDataSource>(
  (Ref ref) => OsmMosqueDataSource(ref.watch(apiClientProvider)),
);

final Provider<NominatimMosqueDataSource> nominatimMosqueDataSourceProvider =
    Provider<NominatimMosqueDataSource>(
  (Ref ref) => NominatimMosqueDataSource(ref.watch(apiClientProvider)),
);

final Provider<MosqueRepository> mosqueRepositoryProvider =
    Provider<MosqueRepository>(
  (Ref ref) => MosqueRepositoryImpl(
    cache: IsarMosqueCacheStore(ref.watch(isarServiceProvider).isar),
    google: ref.watch(googlePlacesMosqueDataSourceProvider),
    osm: ref.watch(osmMosqueDataSourceProvider),
    nominatim: ref.watch(nominatimMosqueDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

// ------------------------------------------------------------ domain layer

final Provider<GetNearbyMosques> getNearbyMosquesProvider =
    Provider<GetNearbyMosques>(
  (Ref ref) => GetNearbyMosques(ref.watch(mosqueRepositoryProvider)),
);

// -------------------------------------------------------- presentation layer

/// True when this build carries a Google Places key.
///
/// Drives one calm line in the radar ("Google Places" vs "OpenStreetMap") — and
/// nothing else, because the repository already falls back on its own.
final Provider<bool> placesKeyConfiguredProvider = Provider<bool>(
  (Ref ref) => AppConstants.placesApiKey.trim().isNotEmpty,
);

/// The five nearest mosques (or none) for the app's current location.
///
/// `autoDispose` so the list — and the cached entities it holds — is released
/// when the radar screen closes; `forceRefresh` is what the pull-to-refresh and
/// the "refresh" button set.
final AutoDisposeFutureProvider<List<MosqueEntity>> nearbyMosquesProvider =
    FutureProvider.autoDispose<List<MosqueEntity>>((Ref ref) async {
  final AppLocation location = ref.watch(locationProvider);
  final GetNearbyMosques usecase = ref.watch(getNearbyMosquesProvider);

  final Either<Failure, List<MosqueEntity>> result = await usecase(
    latitude: location.latitude,
    longitude: location.longitude,
    radiusMeters: AppConstants.mosqueRadiusMeters,
  );

  // A Failure becomes `AsyncValue.error` and is rendered as a sentence.
  return unwrapOrThrow(result);
});

/// The location the radar is searching around (so the header can name the city).
final AutoDisposeProvider<AppLocation> radarLocationProvider =
    Provider.autoDispose<AppLocation>((Ref ref) => ref.watch(locationProvider));

/// Where the last answer came from — read after a successful fetch.
final AutoDisposeProvider<String?> lastMosqueProviderProvider =
    Provider.autoDispose<String?>(
  (Ref ref) => ref.watch(mosqueRepositoryProvider).lastProvider,
);

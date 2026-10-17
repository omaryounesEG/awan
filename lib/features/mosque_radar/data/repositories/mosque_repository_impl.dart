import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/network/network_info.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/data/cache/mosque_cache_policy.dart';
import 'package:awan/features/mosque_radar/data/cache/mosque_cache_store.dart';
import 'package:awan/features/mosque_radar/data/datasources/google_places_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/nominatim_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/osm_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/models/mosque_cache_entry.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/domain/repositories/mosque_repository.dart';

/// Cache first, then up to three sources in a fixed order.
///
/// The order is the whole cost story:
///
/// 1. **local cache** — a fresh (48 h) payload within 500 m means nothing touches
///    the radio and no Places quota is spent. This is the common case: the radar
///    is usually opened from the same place as last time (home, work, the mosque
///    itself).
/// 2. **Google Places** — only when the build carries a key. A missing key is not
///    an error here, it is an expected configuration, and it cascades.
/// 3. **Overpass/OSM** — keyless, and the best mosque coverage in this app's
///    markets.
/// 4. **Nominatim** — the safety net for when every Overpass mirror is down
///    (observed while building this: `kumi.systems` answering 500 and the main
///    instance rate-limiting under load).
///
/// **First provider that answers wins**, even if it answers "none here": asking
/// the next provider for the same square kilometre would only cost time and
/// quota. Failures cascade. If everything fails, the failure reported is the last
/// *real* one — never "add a Google key" when the actual problem is that the
/// phone is offline.
///
/// Whatever the answer, it is cached — an empty result included: "there are no
/// mosques within 2 km" is a valid answer and must not be re-fetched on every
/// screen open.
class MosqueRepositoryImpl implements MosqueRepository {
  MosqueRepositoryImpl({
    required MosqueCacheStore cache,
    required GooglePlacesMosqueDataSource google,
    required OsmMosqueDataSource osm,
    required NominatimMosqueDataSource nominatim,
    required NetworkInfo networkInfo,
    MosqueCachePolicy policy = const MosqueCachePolicy(),
    DateTime Function()? clock,
  })  : _cache = cache,
        _google = google,
        _osm = osm,
        _nominatim = nominatim,
        _network = networkInfo,
        _policy = policy,
        _clock = clock ?? DateTime.now;

  final MosqueCacheStore _cache;
  final GooglePlacesMosqueDataSource _google;
  final OsmMosqueDataSource _osm;
  final NominatimMosqueDataSource _nominatim;
  final NetworkInfo _network;
  final MosqueCachePolicy _policy;
  final DateTime Function() _clock;

  String? _lastProvider;

  @override
  String? get lastProvider => _lastProvider;

  @override
  Future<Either<Failure, List<MosqueEntity>>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    bool forceRefresh = false,
  }) async {
    final DateTime now = _clock();

    if (!forceRefresh) {
      final List<MosqueEntity>? cached =
          await _readCache(latitude, longitude, now);
      if (cached != null) {
        _lastProvider = 'cache';
        // Logged because a cache hit is *invisible* otherwise: it makes no network
        // traffic and no other log line, which reads like "nothing happened".
        debugPrint('[AwanRadar] cache hit -> ${cached.length} mosques (no network)');
        return right<Failure, List<MosqueEntity>>(cached);
      }
    }

    Failure? firstFailure;
    Failure? lastRealFailure;

    for (final _Source source in <_Source>[
      _Source(
        name: GooglePlacesMosqueDataSource.provider,
        fetch: () => _google.search(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
        ),
      ),
      _Source(
        name: OsmMosqueDataSource.provider,
        fetch: () => _osm.search(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
        ),
      ),
      _Source(
        name: NominatimMosqueDataSource.provider,
        fetch: () => _nominatim.search(
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
        ),
      ),
    ]) {
      final Either<Failure, List<MosqueEntity>> attempt =
          await _network.guard<List<MosqueEntity>>(source.fetch);

      if (attempt.isRight()) {
        final List<MosqueEntity> mosques =
            attempt.valueOrNull ?? const <MosqueEntity>[];
        _lastProvider = source.name;
        debugPrint('[AwanRadar] ${source.name} answered ${mosques.length} mosques');
        await _writeCache(
          latitude: latitude,
          longitude: longitude,
          provider: source.name,
          mosques: mosques,
          now: now,
        );
        return right<Failure, List<MosqueEntity>>(mosques);
      }

      final Failure failure = attempt.failureOrNull!;
      firstFailure ??= failure;
      // A missing Places key is a configuration fact, not a reason to tell the
      // user something went wrong while OSM is about to answer.
      if (failure is! PlacesKeyMissingFailure) lastRealFailure = failure;
      debugPrint('[AwanRadar] ${source.name} failed: $failure');
    }

    return left<Failure, List<MosqueEntity>>(
      lastRealFailure ?? firstFailure ?? const ServerFailure(),
    );
  }

  // ------------------------------------------------------------------- cache

  Future<List<MosqueEntity>?> _readCache(
    double latitude,
    double longitude,
    DateTime now,
  ) async {
    final List<MosqueCacheEntry> candidates = await _cache.candidates(
      _policy.candidateCellKeys(latitude, longitude),
    );

    final MosqueCacheEntry? best = _policy.best(
      candidates,
      latitude: latitude,
      longitude: longitude,
      now: now,
    );
    if (best == null) return null;

    try {
      final Object? decoded = jsonDecode(best.payload);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> item) =>
              MosqueEntity.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on FormatException {
      // A corrupt payload is treated as a miss, not as a crash: the next
      // successful fetch overwrites it.
      return null;
    }
  }

  Future<void> _writeCache({
    required double latitude,
    required double longitude,
    required String provider,
    required List<MosqueEntity> mosques,
    required DateTime now,
  }) async {
    try {
      await _cache.put(
        MosqueCacheEntry()
          ..cellKey = Geo.cellKey(latitude, longitude)
          ..fetchedAt = now
          ..provider = provider
          ..latitude = latitude
          ..longitude = longitude
          ..payload = jsonEncode(
            mosques.map((MosqueEntity m) => m.toJson()).toList(growable: false),
          ),
      );

      // Hygiene: drop anything twice the TTL old so the table cannot grow without
      // bound while the user travels.
      await _cache.pruneBefore(now.subtract(Duration(hours: _policy.ttlHours * 2)));
    } catch (_) {
      // Never let a cache write break a successful fetch.
    }
  }
}

/// One candidate source: a name for the UI and the call to make.
class _Source {
  const _Source({required this.name, required this.fetch});

  final String name;
  final Future<List<MosqueEntity>> Function() fetch;
}

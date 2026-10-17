import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/network/network_info.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/data/cache/mosque_cache_policy.dart';
import 'package:awan/features/mosque_radar/data/cache/mosque_cache_store.dart';
import 'package:awan/features/mosque_radar/data/datasources/google_places_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/nominatim_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/datasources/osm_mosque_datasource.dart';
import 'package:awan/features/mosque_radar/data/models/mosque_cache_entry.dart';
import 'package:awan/features/mosque_radar/data/repositories/mosque_repository_impl.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/domain/repositories/mosque_repository.dart';
import 'package:awan/features/mosque_radar/domain/usecases/get_nearby_mosques.dart';

/// The radar's *decisions* — what to cache, what to re-fetch, what to show —
/// are pure logic and are pinned here, with fakes instead of a database and a
/// network. The Isar adapter and the two HTTP data sources are thin translations
/// of the same rules.

class _MemoryCache implements MosqueCacheStore {
  final Map<String, MosqueCacheEntry> rows = <String, MosqueCacheEntry>{};
  final List<DateTime> prunes = <DateTime>[];

  @override
  Future<List<MosqueCacheEntry>> candidates(List<String> cellKeys) async =>
      <MosqueCacheEntry>[
        for (final String key in cellKeys)
          if (rows[key] != null) rows[key]!,
      ];

  @override
  Future<void> put(MosqueCacheEntry entry) async {
    rows[entry.cellKey] = entry;
  }

  @override
  Future<void> pruneBefore(DateTime cutoff) async {
    prunes.add(cutoff);
  }
}

/// A repository that answers with whatever it was told, and counts the calls.
class _FakeRepository implements MosqueRepository {
  _FakeRepository({this.mosques = const <MosqueEntity>[], this.failure});

  final List<MosqueEntity> mosques;
  final Failure? failure;
  int calls = 0;

  @override
  String? lastProvider = 'fake';

  @override
  Future<Either<Failure, List<MosqueEntity>>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 2000,
    bool forceRefresh = false,
  }) async {
    calls++;
    if (failure != null) return left<Failure, List<MosqueEntity>>(failure!);
    return right<Failure, List<MosqueEntity>>(mosques);
  }
}

MosqueEntity _mosque(String name, double meters) => MosqueEntity(
      id: name,
      name: name,
      latitude: 30.0444,
      longitude: 31.2357,
      distanceMeters: meters,
    );

void main() {
  group('MosqueCachePolicy — the 500 m / 48 h rule', () {
    const MosqueCachePolicy policy = MosqueCachePolicy();
    final DateTime now = DateTime(2026, 10, 10, 13, 0);

    MosqueCacheEntry entryAt(double lat, double lng, DateTime at) =>
        MosqueCacheEntry()
          ..cellKey = Geo.cellKey(lat, lng)
          ..fetchedAt = at
          ..provider = 'osm'
          ..latitude = lat
          ..longitude = lng
          ..payload = '[]';

    test('a payload cached 300 m away two hours ago is reused', () {
      final MosqueCacheEntry? best = policy.best(
        <MosqueCacheEntry>[entryAt(30.0470, 31.2357, now.subtract(const Duration(hours: 2)))],
        latitude: 30.0444,
        longitude: 31.2357,
        now: now,
      );
      expect(best, isNotNull);
    });

    test('600 m away is a miss even when fresh', () {
      final MosqueCacheEntry? best = policy.best(
        <MosqueCacheEntry>[entryAt(30.0498, 31.2357, now)],
        latitude: 30.0444,
        longitude: 31.2357,
        now: now,
      );
      expect(best, isNull);
    });

    test('49 hours old is a miss even when 50 m away', () {
      final MosqueCacheEntry? best = policy.best(
        <MosqueCacheEntry>[entryAt(30.0448, 31.2357, now.subtract(const Duration(hours: 49)))],
        latitude: 30.0444,
        longitude: 31.2357,
        now: now,
      );
      expect(best, isNull);
    });

    test('the nearest fresh candidate wins', () {
      final MosqueCacheEntry? best = policy.best(
        <MosqueCacheEntry>[
          entryAt(30.0480, 31.2357, now), // ~400 m
          entryAt(30.0449, 31.2357, now), // ~55 m
        ],
        latitude: 30.0444,
        longitude: 31.2357,
        now: now,
      );
      expect(best, isNotNull);
      expect(best!.latitude, closeTo(30.0449, 1e-6));
    });

    test('the neighbourhood is nine cells and includes the point itself', () {
      final List<String> keys = policy.candidateCellKeys(30.0444, 31.2357);
      expect(keys.length, 9);
      expect(keys.toSet().length, 9);
      expect(keys, contains(Geo.cellKey(30.0444, 31.2357)));
    });
  });

  group('GetNearbyMosques — one order for markers and cards', () {
    test('sorts by distance and keeps only the five nearest', () async {
      final _FakeRepository repository = _FakeRepository(
        mosques: <MosqueEntity>[
          _mosque('f', 600),
          _mosque('b', 200),
          _mosque('e', 500),
          _mosque('a', 100),
          _mosque('d', 400),
          _mosque('c', 300),
          _mosque('g', 700),
        ],
      );

      final List<MosqueEntity>? result = (await GetNearbyMosques(repository)(
        latitude: 30,
        longitude: 31,
      ))
          .valueOrNull;

      expect(result, isNotNull);
      expect(result!.length, 5);
      expect(
        result.map((MosqueEntity m) => m.name).toList(),
        <String>['a', 'b', 'c', 'd', 'e'],
      );
    });

    test('a failure travels through untouched', () async {
      final _FakeRepository repository =
          _FakeRepository(failure: const NetworkFailure());
      final Either<Failure, List<MosqueEntity>> result =
          await GetNearbyMosques(repository)(latitude: 30, longitude: 31);
      expect(result.isLeft(), isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('MosqueEntity', () {
    test('walking minutes come from the 1.35 m/s pace', () {
      expect(_mosque('x', 400).walkingMinutes, 5);
      expect(_mosque('x', 81).walkingMinutes, 1);
    });

    test('survives a JSON round-trip (what the cache stores)', () {
      const MosqueEntity original = MosqueEntity(
        id: 'osm:node/1',
        name: 'مسجد النور',
        latitude: 30.0444,
        longitude: 31.2357,
        distanceMeters: 320,
        address: 'شارع النيل',
        provider: 'osm',
      );
      final MosqueEntity restored = MosqueEntity.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.distanceMeters, original.distanceMeters);
      expect(restored.address, original.address);
      expect(restored.walkingMinutes, original.walkingMinutes);
    });
  });

  group('Google Places key handling and the fallback order', () {
    test('a keyless build is answered by OpenStreetMap, and the answer is cached',
        () async {
      final _MemoryCache cache = _MemoryCache();
      final _FakeGoogle google = _FakeGoogle(throwsKeyMissing: true);
      final _FakeNominatim nominatim = _FakeNominatim();
      final _FakeOsm osm = _FakeOsm(
        mosques: <MosqueEntity>[_mosque('نور', 300), _mosque('تقوى', 900)],
      );

      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: cache,
        google: google,
        osm: osm,
        nominatim: nominatim,
        networkInfo: NetworkInfo(),
        clock: () => DateTime(2026, 10, 10, 13),
      );

      final List<MosqueEntity>? result = (await repository.nearby(
        latitude: 30.0444,
        longitude: 31.2357,
        radiusMeters: 2000,
      ))
          .valueOrNull;

      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(repository.lastProvider, 'osm');
      expect(google.calls, 1, reason: 'the keyless call must be attempted once');
      expect(osm.calls, 1);
      expect(cache.rows.length, 1, reason: 'the OSM answer is cached');
      expect(cache.rows.values.first.provider, 'osm');
    });

    test('Google answers when it can, and OSM is never called', () async {
      final _MemoryCache cache = _MemoryCache();
      final _FakeGoogle google =
          _FakeGoogle(mosques: <MosqueEntity>[_mosque('جامع', 120)]);
      final _FakeNominatim nominatim = _FakeNominatim();
      final _FakeOsm osm = _FakeOsm(mosques: <MosqueEntity>[_mosque('احتياطي', 400)]);

      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: cache,
        google: google,
        osm: osm,
        nominatim: nominatim,
        networkInfo: NetworkInfo(),
        clock: () => DateTime(2026, 10, 10, 13),
      );

      final List<MosqueEntity>? result = (await repository.nearby(
        latitude: 30.0444,
        longitude: 31.2357,
      ))
          .valueOrNull;

      expect(result!.first.name, 'جامع');
      expect(repository.lastProvider, 'google');
      expect(osm.calls, 0);
    });

    test('a fresh cached cell within 500 m costs zero network calls', () async {
      final _MemoryCache cache = _MemoryCache();
      final DateTime now = DateTime(2026, 10, 10, 13);
      cache.rows['30.04:31.24'] = MosqueCacheEntry()
        ..cellKey = '30.04:31.24'
        ..fetchedAt = now.subtract(const Duration(hours: 3))
        ..provider = 'osm'
        ..latitude = 30.0444
        ..longitude = 31.2357
        ..payload = '[{"id":"osm:node/9","name":"من الذاكرة","lat":30.0444,'
            '"lng":31.2357,"distance":180,"address":null,"provider":"osm"}]';

      final _FakeGoogle google = _FakeGoogle(mosques: <MosqueEntity>[_mosque('x', 1)]);
      final _FakeNominatim nominatim = _FakeNominatim();
      final _FakeOsm osm = _FakeOsm(mosques: <MosqueEntity>[_mosque('y', 1)]);

      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: cache,
        google: google,
        osm: osm,
        nominatim: nominatim,
        networkInfo: NetworkInfo(),
        clock: () => now,
      );

      final List<MosqueEntity>? result = (await repository.nearby(
        latitude: 30.0444,
        longitude: 31.2357,
      ))
          .valueOrNull;

      expect(result!.single.name, 'من الذاكرة');
      expect(repository.lastProvider, 'cache');
      expect(google.calls, 0);
      expect(osm.calls, 0);
      expect(cache.prunes.length, 0);
    });

    test('forceRefresh ignores a fresh cache', () async {
      final _MemoryCache cache = _MemoryCache();
      final DateTime now = DateTime(2026, 10, 10, 13);
      cache.rows['30.04:31.24'] = MosqueCacheEntry()
        ..cellKey = '30.04:31.24'
        ..fetchedAt = now
        ..provider = 'osm'
        ..latitude = 30.0444
        ..longitude = 31.2357
        ..payload = '[]';

      final _FakeNominatim nominatim = _FakeNominatim();
      final _FakeOsm osm = _FakeOsm(mosques: <MosqueEntity>[_mosque('جديد', 250)]);
      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: cache,
        google: _FakeGoogle(throwsKeyMissing: true),
        osm: osm,
        nominatim: nominatim,
        networkInfo: NetworkInfo(),
        clock: () => now,
      );

      await repository.nearby(
        latitude: 30.0444,
        longitude: 31.2357,
        forceRefresh: true,
      );

      expect(osm.calls, 1);
      expect(cache.prunes.length, 1, reason: 'a write also prunes old cells');
    });

    test('both sources failing is a Failure, not a crash', () async {
      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: _MemoryCache(),
        google: _FakeGoogle(failWith: const NetworkFailure()),
        osm: _FakeOsm(failWith: const NetworkFailure()),
        nominatim: _FakeNominatim(failWith: const NetworkFailure()),
        networkInfo: NetworkInfo(),
      );

      final Either<Failure, List<MosqueEntity>> result =
          await repository.nearby(latitude: 30.0444, longitude: 31.2357);

      expect(result.isLeft(), isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('an empty answer from the first configured provider is not an error',
        () async {
      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: _MemoryCache(),
        google: _FakeGoogle(mosques: const <MosqueEntity>[]),
        osm: _FakeOsm(mosques: const <MosqueEntity>[]),
        nominatim: _FakeNominatim(),
        networkInfo: NetworkInfo(),
      );

      final Either<Failure, List<MosqueEntity>> result =
          await repository.nearby(latitude: 30.0444, longitude: 31.2357);

      expect(result.isRight(), isTrue);
      expect(result.valueOrNull, isEmpty);
      // Google answered "none here"; asking OSM for the same square kilometre
      // would only cost time and quota.
      expect(repository.lastProvider, 'google');
    });

    test('when every Overpass mirror is down, Nominatim still answers', () async {
      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: _MemoryCache(),
        google: _FakeGoogle(throwsKeyMissing: true),
        osm: _FakeOsm(failWith: const ServerFailure()),
        nominatim: _FakeNominatim(
          mosques: <MosqueEntity>[_mosque('جامع من Nominatim', 420)],
        ),
        networkInfo: NetworkInfo(),
      );

      final Either<Failure, List<MosqueEntity>> result =
          await repository.nearby(latitude: 30.0444, longitude: 31.2357);

      expect(result.valueOrNull!.single.name, 'جامع من Nominatim');
      expect(repository.lastProvider, 'osm');
    });

    test('a dead network reports the network, not the missing Google key',
        () async {
      final MosqueRepositoryImpl repository = MosqueRepositoryImpl(
        cache: _MemoryCache(),
        google: _FakeGoogle(throwsKeyMissing: true),
        osm: _FakeOsm(failWith: const NetworkFailure()),
        nominatim: _FakeNominatim(failWith: const NetworkFailure()),
        networkInfo: NetworkInfo(),
      );

      final Either<Failure, List<MosqueEntity>> result =
          await repository.nearby(latitude: 30.0444, longitude: 31.2357);

      expect(result.isLeft(), isTrue);
      expect(
        result.failureOrNull,
        isA<NetworkFailure>(),
        reason: 'the keyless build must never show a Google-key message offline',
      );
    });
  });

  group('the Nominatim tier parses a real jsonv2 payload', () {
    test('jsonv2 `category` + `extratags.religion` — the bug that emptied Cairo',
        () async {
      final ApiClient client = ApiClient();
      final _StubAdapter adapter = _StubAdapter(_nominatimFixture);
      client.dio.httpClientAdapter = adapter;
      final NominatimMosqueDataSource source = NominatimMosqueDataSource(client);

      final List<MosqueEntity> mosques = await source.search(
        latitude: 30.0444,
        longitude: 31.2357,
        radiusMeters: 2000,
        language: 'ar',
      );

      expect(mosques, isNotEmpty, reason: 'Cairo has mosques mapped in OSM');
      expect(mosques.every((MosqueEntity m) => m.provider == 'osm'), isTrue);
      expect(mosques.first.name, 'مسجد مصطفى محمود');
      expect(
        mosques.any((MosqueEntity m) => m.name.contains('كنيسة')),
        isFalse,
        reason: 'a church in the same payload must be filtered out',
      );
      expect(
        mosques.any((MosqueEntity m) => m.name == 'Mosque Market'),
        isFalse,
        reason: 'a shop whose name contains "mosque" is not a mosque',
      );

      // The query shape matters as much as the parsing: `format=jsonv2` is what
      // makes the fields above appear, and `extratags` is what carries religion.
      final Map<String, dynamic> params =
          adapter.requests.single.queryParameters.cast<String, dynamic>();
      expect(params['format'], 'jsonv2');
      expect(params['extratags'], 1);
      expect(params['bounded'], 1);
      expect('${params['viewbox']}'.split(',').length, 4);
    });
  });
}

/// A Cairo-shaped `jsonv2` response: one mosque, one church, one shop, and a
/// mosque 5 km away that must fall outside the radius.
const String _nominatimFixture = '''
[
  {
    "place_id": 101,
    "lat": "30.0481",
    "lon": "31.2547",
    "category": "amenity",
    "type": "place_of_worship",
    "name": "مسجد مصطفى محمود",
    "display_name": "مسجد مصطفى محمود، شارع سعد زغلول، الزمالك، القاهرة",
    "extratags": {"religion": "muslim"},
    "address": {"road": "شارع سعد زغلول", "suburb": "الزمالك"}
  },
  {
    "place_id": 102,
    "lat": "30.0450",
    "lon": "31.2400",
    "category": "amenity",
    "type": "place_of_worship",
    "name": "كنيسة السيدة العذراء",
    "display_name": "كنيسة السيدة العذراء، القاهرة",
    "extratags": {"religion": "christian"},
    "address": {"road": "شارع رمسيس"}
  },
  {
    "place_id": 103,
    "lat": "30.0460",
    "lon": "31.2380",
    "category": "shop",
    "type": "supermarket",
    "name": "Mosque Market",
    "display_name": "Mosque Market, القاهرة"
  },
  {
    "place_id": 104,
    "lat": "30.0900",
    "lon": "31.2357",
    "category": "amenity",
    "type": "place_of_worship",
    "name": "مسجد بعيد",
    "display_name": "مسجد بعيد",
    "extratags": {"religion": "muslim"}
  }
]
''';

/// Answers every request with the same body — no sockets in unit tests.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final String body;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A Google Places data source that never touches the network.
class _FakeGoogle extends GooglePlacesMosqueDataSource {
  _FakeGoogle({
    this.mosques = const <MosqueEntity>[],
    this.throwsKeyMissing = false,
    this.failWith,
  }) : super(ApiClient());

  final List<MosqueEntity> mosques;
  final bool throwsKeyMissing;
  final Failure? failWith;
  int calls = 0;

  @override
  bool get hasKey => !throwsKeyMissing;

  @override
  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    calls++;
    if (throwsKeyMissing) throw const PlacesKeyMissingException();
    if (failWith is NetworkFailure) throw const NetworkException();
    if (failWith != null) throw const ServerException();
    return mosques;
  }
}

/// An Overpass data source that never touches the network.
class _FakeOsm extends OsmMosqueDataSource {
  _FakeOsm({this.mosques = const <MosqueEntity>[], this.failWith})
      : super(ApiClient());

  final List<MosqueEntity> mosques;
  final Failure? failWith;
  int calls = 0;

  @override
  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    calls++;
    if (failWith is NetworkFailure) throw const NetworkException();
    if (failWith != null) throw const ServerException();
    return mosques;
  }
}

/// A Nominatim data source that never touches the network.
class _FakeNominatim extends NominatimMosqueDataSource {
  _FakeNominatim({this.mosques = const <MosqueEntity>[], this.failWith})
      : super(ApiClient());

  final List<MosqueEntity> mosques;
  final Failure? failWith;
  int calls = 0;

  @override
  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    calls++;
    if (failWith is NetworkFailure) throw const NetworkException();
    if (failWith != null) throw const ServerException();
    return mosques;
  }
}

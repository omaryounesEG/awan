import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';

/// OpenStreetMap mosques, through Overpass — the keyless path.
///
/// Why it exists at all: a Google Places key costs money and belongs to the
/// person who owns the billing account, so the radar must be *useful* without
/// one. OSM's coverage of mosques in Egypt, Saudi Arabia and the Gulf is good
/// (they are mapped as `amenity=place_of_worship` + `religion=muslim`), and the
/// query is narrow enough that Overpass answers in a few hundred milliseconds.
///
/// The mirrors in [AppConstants.overpassEndpoints] are tried in order because the
/// main instance returns 429/504 when busy and `kumi.systems` returns 500 more
/// often than it works. Two rules keep the user from ever watching a spinner for
/// a minute:
///
/// * **each mirror gets [_perMirrorTimeout]** — measured on the device, a healthy
///   Overpass answers this query in well under a second, so a mirror that has not
///   answered in 12s is not going to;
/// * **every failure is logged**, so "the radar is empty" can be diagnosed from
///   `adb logcat` instead of guessed at.
class OsmMosqueDataSource {
  OsmMosqueDataSource(this._client);

  final ApiClient _client;

  static const String provider = 'osm';

  /// One mirror's budget before the next one is tried.
  static const Duration _perMirrorTimeout = Duration(seconds: 12);

  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    // `out center` makes ways (buildings) report a centre point, so a mosque
    // mapped as a polygon is not silently dropped.
    final String query = '''
[out:json][timeout:20];
(
  node(around:$radiusMeters,$latitude,$longitude)[amenity=place_of_worship][religion=muslim];
  way(around:$radiusMeters,$latitude,$longitude)[amenity=place_of_worship][religion=muslim];
);
out center 60;''';

    Object? lastError;
    for (final String endpoint in AppConstants.overpassEndpoints) {
      final Stopwatch clock = Stopwatch()..start();
      try {
        final Response<dynamic> response = await _client
            .postOverpass(endpoint, query)
            .timeout(_perMirrorTimeout);
        final List<MosqueEntity> parsed = _parse(
          response.data,
          fromLatitude: latitude,
          fromLongitude: longitude,
          language: language,
        );
        debugPrint(
          '[AwanRadar] overpass ok ${endpoint.split('/')[2]} '
          '${clock.elapsedMilliseconds}ms -> ${parsed.length} mosques',
        );
        return parsed;
      } catch (error) {
        // Try the next mirror; report the last failure only if all of them fail.
        lastError = error;
        debugPrint(
          '[AwanRadar] overpass failed ${endpoint.split('/')[2]} '
          '${clock.elapsedMilliseconds}ms: ${error.runtimeType} $error',
        );
      }
    }
    throw ServerException(message: 'Overpass unreachable', cause: lastError);
  }

  List<MosqueEntity> _parse(
    Object? data, {
    required double fromLatitude,
    required double fromLongitude,
    required String language,
  }) {
    if (data is! Map) {
      throw const ParseException(message: 'Unexpected Overpass payload');
    }
    final Object? elements = data['elements'];
    if (elements is! List) return const <MosqueEntity>[];

    final List<MosqueEntity> mosques = <MosqueEntity>[];
    for (final Object? element in elements) {
      if (element is! Map) continue;

      final Map<Object?, Object?> tags =
          (element['tags'] as Map?)?.cast<Object?, Object?>() ??
              const <Object?, Object?>{};

      // Coordinates: nodes carry lat/lon, ways carry a computed centre.
      double? lat = (element['lat'] as num?)?.toDouble();
      double? lng = (element['lon'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        final Object? center = element['center'];
        if (center is Map) {
          lat = (center['lat'] as num?)?.toDouble();
          lng = (center['lon'] as num?)?.toDouble();
        }
      }
      if (lat == null || lng == null) continue;

      final String? name = _name(tags, language);
      mosques.add(
        MosqueEntity(
          id: 'osm:${element['type']}/${element['id']}',
          name: name ?? (language == 'ar' ? 'مسجد' : 'Mosque'),
          latitude: lat,
          longitude: lng,
          distanceMeters: Geo.distanceMeters(
            fromLatitude: fromLatitude,
            fromLongitude: fromLongitude,
            toLatitude: lat,
            toLongitude: lng,
          ),
          address: _address(tags),
          provider: provider,
        ),
      );
    }
    return mosques;
  }

  /// Prefers the Arabic name when the UI is Arabic, then any local name.
  String? _name(Map<Object?, Object?> tags, String language) {
    final String? arabic = tags['name:ar'] as String?;
    final String? english = tags['name:en'] as String?;
    final String? any = tags['name'] as String?;
    final String? chosen =
        language == 'ar' ? (arabic ?? any ?? english) : (english ?? any ?? arabic);
    final String trimmed = (chosen ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _address(Map<Object?, Object?> tags) {
    final String street = ((tags['addr:street'] as String?) ?? '').trim();
    final String number = ((tags['addr:housenumber'] as String?) ?? '').trim();
    if (street.isEmpty && number.isEmpty) return null;
    return <String>[if (street.isNotEmpty) street, if (number.isNotEmpty) number]
        .join(' ');
  }
}

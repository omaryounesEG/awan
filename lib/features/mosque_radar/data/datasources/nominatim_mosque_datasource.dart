import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';

/// The last keyless tier: Nominatim search, when every Overpass mirror is down.
///
/// It exists because Overpass genuinely goes down — during the build of this
/// feature `kumi.systems` answered 500 and the main instance is rate-limited
/// under load. Since the radar's promise is "works without a Google key", it
/// cannot have a single point of failure behind it.
///
/// Nominatim is a *geocoder*, so it is asked for mosques inside a bounding box
/// derived from the search radius, and the results are filtered to
/// `amenity=place_of_worship` and finally trimmed to the real radius (a box
/// contains the circle, not the other way round). Its usage policy allows one
/// request per second for a user-triggered search like this one, and the 48-hour
/// Isar cache means a given place is normally asked for once.
class NominatimMosqueDataSource {
  NominatimMosqueDataSource(this._client);

  final ApiClient _client;

  static const String provider = 'osm';

  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    // Nominatim's viewbox is `left,top,right,bottom` in lon,lat order.
    final double latDelta = radiusMeters / 111320.0;
    final double lonDelta =
        radiusMeters / (111320.0 * math.cos(latitude * math.pi / 180.0));

    final Response<dynamic> response = await _client.dio.get<dynamic>(
      '${AppConstants.nominatimBase}/search',
      queryParameters: <String, dynamic>{
        'q': 'mosque',
        'format': 'jsonv2',
        'addressdetails': 1,
        // `extratags` is what carries `religion=muslim`: without it a mosque
        // search returns churches and synagogues too.
        'extratags': 1,
        'bounded': 1,
        'limit': 50,
        'viewbox': '${longitude - lonDelta},${latitude + latDelta},'
            '${longitude + lonDelta},${latitude - latDelta}',
      },
      options: Options(
        headers: <String, String>{'Accept-Language': language},
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    final Object? data = response.data;
    if (data is! List) {
      throw const ParseException(message: 'Unexpected Nominatim payload');
    }

    final List<MosqueEntity> mosques = <MosqueEntity>[];
    for (final Object? item in data) {
      if (item is! Map) continue;

      // Keep only actual places of worship: `q=mosque` can also match a shop
      // called "Mosque Market" or a street named after one.
      //
      // Two traps live here, both hit on the device and both fixed by
      // `test/mosque_radar_test.dart`'s Nominatim fixture:
      //   * the category field is `category` in `jsonv2` and only `class` in
      //     `jsonv1` — reading `class` alone filtered *every* result away and the
      //     radar showed "no mosques nearby" for central Cairo;
      //   * `religion` only arrives when `extratags=1` is asked for, so it is
      //     checked only when present (older OSM data has no religion tag).
      final String? type = item['type'] as String?;
      final String? category = (item['category'] ?? item['class']) as String?;
      if (category != 'amenity' || type != 'place_of_worship') continue;

      final Object? extra = item['extratags'];
      final Object? religion = extra is Map ? extra['religion'] : null;
      if (religion != null && '$religion'.toLowerCase() != 'muslim') continue;

      final double? lat = double.tryParse('${item['lat']}');
      final double? lng = double.tryParse('${item['lon']}');
      if (lat == null || lng == null) continue;

      final double distance = Geo.distanceMeters(
        fromLatitude: latitude,
        fromLongitude: longitude,
        toLatitude: lat,
        toLongitude: lng,
      );
      // The bounding box is a square around a circle: trim the corners.
      if (distance > radiusMeters) continue;

      final String name =
          '${item['name'] ?? item['display_name'] ?? ''}'.split(',').first.trim();
      mosques.add(
        MosqueEntity(
          id: 'osm:nominatim/${item['osm_id'] ?? item['place_id']}',
          name: name.isEmpty ? (language == 'ar' ? 'مسجد' : 'Mosque') : name,
          latitude: lat,
          longitude: lng,
          distanceMeters: distance,
          address: _address(item['address']),
          provider: provider,
        ),
      );
    }

    debugPrint('[AwanRadar] nominatim -> ${mosques.length} mosques');
    return mosques;
  }

  String? _address(Object? address) {
    if (address is! Map) return null;
    final String road = '${address['road'] ?? ''}'.trim();
    final String suburb = '${address['suburb'] ?? address['neighbourhood'] ?? ''}'
        .trim();
    final String joined = <String>[
      if (road.isNotEmpty) road,
      if (suburb.isNotEmpty) suburb,
    ].join('، ');
    return joined.isEmpty ? null : joined;
  }
}

import 'package:dio/dio.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';

/// Google Places `nearbysearch` — the paid, best-named source.
///
/// Cost discipline (Step 6 asks for it explicitly):
///
/// * the key comes from the build (`--dart-define=PLACES_API_KEY=...`), never
///   from the source tree, so no secret can be committed by accident;
/// * without a key the call is **not attempted at all** — a typed exception goes
///   up and the repository answers from OpenStreetMap, so a keyless build costs
///   nothing rather than failing loudly;
/// * the request asks for one page of 20 results at the radius the user's screen
///   shows, and the repository caches the answer for 48 h per 500 m.
class GooglePlacesMosqueDataSource {
  GooglePlacesMosqueDataSource(this._client);

  final ApiClient _client;

  static const String provider = 'google';

  /// `OK` and `ZERO_RESULTS` are both answers; anything else is a real error.
  static const String _statusOk = 'OK';
  static const String _statusZero = 'ZERO_RESULTS';

  bool get hasKey => AppConstants.placesApiKey.trim().isNotEmpty;

  Future<List<MosqueEntity>> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String language = 'ar',
  }) async {
    if (!hasKey) {
      throw const PlacesKeyMissingException();
    }

    final Response<dynamic> response = await _client.dio.get<dynamic>(
      AppConstants.googlePlacesBase,
      queryParameters: <String, dynamic>{
        'location': '$latitude,$longitude',
        'radius': radiusMeters,
        'type': 'mosque',
        'language': language,
        'key': AppConstants.placesApiKey,
      },
    );

    final Object? data = response.data;
    if (data is! Map) {
      throw const ParseException(message: 'Unexpected Places payload');
    }

    final String status = (data['status'] as String?) ?? '';
    if (status != _statusOk && status != _statusZero) {
      // REQUEST_DENIED / OVER_QUERY_LIMIT / INVALID_REQUEST all land here, with
      // Google's own message kept in the exception for the log.
      throw ServerException(
        message: 'Places ${status.isEmpty ? 'error' : status}'
            '${data['error_message'] == null ? '' : ': ${data['error_message']}'}',
      );
    }

    final Object? results = data['results'];
    if (results is! List) return const <MosqueEntity>[];

    final List<MosqueEntity> mosques = <MosqueEntity>[];
    for (final Object? item in results) {
      if (item is! Map) continue;
      final Object? geometry = item['geometry'];
      if (geometry is! Map) continue;
      final Object? location = geometry['location'];
      if (location is! Map) continue;

      final double? lat = (location['lat'] as num?)?.toDouble();
      final double? lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      mosques.add(
        MosqueEntity(
          id: (item['place_id'] as String?) ??
              'google:$lat:$lng',
          name: (item['name'] as String?)?.trim().isNotEmpty == true
              ? (item['name'] as String).trim()
              : 'مسجد',
          latitude: lat,
          longitude: lng,
          distanceMeters: Geo.distanceMeters(
            fromLatitude: latitude,
            fromLongitude: longitude,
            toLatitude: lat,
            toLongitude: lng,
          ),
          address: item['vicinity'] as String?,
          provider: provider,
        ),
      );
    }
    return mosques;
  }
}

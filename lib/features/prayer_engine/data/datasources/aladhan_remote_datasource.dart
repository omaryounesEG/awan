import 'package:dio/dio.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/exceptions.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// Aladhan — the *verification* source of the hybrid engine.
///
/// Nothing the user sees comes from here: if this call fails, the app keeps
/// showing the offline computation and simply records "not verified".
class AladhanRemoteDatasource {
  AladhanRemoteDatasource(this._client);

  final ApiClient _client;

  static final RegExp _timeOnly = RegExp(r'(\d{1,2}):(\d{2})');
  static final RegExp _timeZoneSuffix = RegExp(r'\s*\([^)]*\)\s*');

  /// Throws [ServerException]/[NetworkException]; the repository turns those
  /// into a `Failure` through `NetworkInfo.guard`.
  Future<Map<PrayerName, DateTime>> fetchDay({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    required String madhab,
  }) async {
    final Response<dynamic> response = await _client.dio.get<dynamic>(
      '${AppConstants.aladhanBase}/timings/${_formatDate(date)}',
      queryParameters: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'method': method.aladhanId,
        'school': madhab == 'hanafi' ? 1 : 0,
      },
    );

    final Object? data = response.data;
    if (data is! Map || data['data'] is! Map) {
      throw const ServerException(message: 'Unexpected Aladhan payload');
    }
    final Object? timings = (data['data'] as Map)['timings'];
    if (timings is! Map) {
      throw const ServerException(message: 'Aladhan returned no timings');
    }

    final Map<PrayerName, DateTime> out = <PrayerName, DateTime>{};
    for (final PrayerName name in PrayerName.values) {
      final DateTime? parsed = _parse(timings[_apiKey(name)] as String?, date);
      if (parsed != null) out[name] = parsed;
    }
    if (out.isEmpty) {
      throw const ServerException(message: 'Aladhan returned unparsable times');
    }
    return out;
  }

  /// Worst whole-minute difference between [local] and the reference.
  Future<int> mismatchMinutes({
    required DateTime date,
    required Map<PrayerName, DateTime> local,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    required String madhab,
  }) async {
    final Map<PrayerName, DateTime> reference = await fetchDay(
      date: date,
      latitude: latitude,
      longitude: longitude,
      method: method,
      madhab: madhab,
    );

    int worst = 0;
    for (final PrayerName name in PrayerName.obligatory) {
      final DateTime? ref = reference[name];
      final DateTime? mine = local[name];
      if (ref == null || mine == null) continue;
      final int diff = mine.difference(ref).inMinutes.abs();
      if (diff > worst) worst = diff;
    }
    return worst;
  }

  static String _apiKey(PrayerName name) => switch (name) {
        PrayerName.fajr => 'Fajr',
        PrayerName.sunrise => 'Sunrise',
        PrayerName.dhuhr => 'Dhuhr',
        PrayerName.asr => 'Asr',
        PrayerName.maghrib => 'Maghrib',
        PrayerName.isha => 'Isha',
      };

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.year}';

  /// Aladhan answers `"04:50 (EET)"`; only the wall clock matters because the
  /// coordinates are the user's own.
  static DateTime? _parse(String? raw, DateTime date) {
    if (raw == null) return null;
    final Match? match =
        _timeOnly.firstMatch(raw.replaceAll(_timeZoneSuffix, ''));
    if (match == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }
}

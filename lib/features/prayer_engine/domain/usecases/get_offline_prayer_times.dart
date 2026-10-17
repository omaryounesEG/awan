import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Parameters of the offline calculation (Step 3, Task 2).
class OfflinePrayerParams {
  const OfflinePrayerParams({
    required this.latitude,
    required this.longitude,
    required this.date,
    this.method = PrayerMethod.egyptian,
    this.madhab = AsrMadhab.shafi,
    this.highLatitude = HighLatitude.middleOfTheNight,
    this.adjustments = const <String, int>{},
    this.now,
  });

  final double latitude;
  final double longitude;
  final DateTime date;

  /// Default = `CalculationMethod.egyptian`, as specified; the app replaces it
  /// with whatever the user picked.
  final PrayerMethod method;
  final AsrMadhab madhab;
  final HighLatitude highLatitude;

  /// Per-prayer tweaks in minutes (`{'fajr': 5}`).
  final Map<String, int> adjustments;

  /// Injectable clock, so tests are deterministic.
  final DateTime? now;

  PrayerCalcSpec toSpec() => PrayerCalcSpec(
        latitude: latitude,
        longitude: longitude,
        method: method,
        madhab: madhab,
        highLatitude: highLatitude,
        adjustments: adjustments,
      );
}

/// **The offline engine** — pure arithmetic, no network, no database.
///
/// `adhan_dart` is kept behind this use case so no widget and no data source
/// ever imports it: `Coordinates`, `CalculationMethod` and `PrayerTimes` live in
/// one place ([CalculatePrayerTimes]), and this use case is the Clean
/// Architecture contract the rest of the app talks to.
///
/// The calculation is infallible in practice, but it still returns
/// `Either<Failure, PrayerTimesEntity>`: latitude/longitude outside ±90/±180 or
/// an impossible date must surface as a typed `Failure` instead of an exception
/// crossing a layer boundary.
class GetOfflinePrayerTimes {
  const GetOfflinePrayerTimes([this._engine = const CalculatePrayerTimes()]);

  final CalculatePrayerTimes _engine;

  Future<Either<Failure, PrayerTimesEntity>> call(
    OfflinePrayerParams params,
  ) async {
    if (_invalid(params.latitude, params.longitude, params.date)) {
      return left<Failure, PrayerTimesEntity>(
        const ServerFailure(
          message: 'invalid_location_or_date',
          statusCode: 400,
        ),
      );
    }
    try {
      final DayPrayerTimes day = _engine.forDate(
        date: params.date,
        spec: params.toSpec(),
      );
      return right<Failure, PrayerTimesEntity>(
        PrayerTimesEntity.fromDay(day, now: params.now),
      );
    } catch (error) {
      // A leap-second edge case or a bad parameter reaches us here; the caller
      // still gets a typed failure rather than a crash.
      return left<Failure, PrayerTimesEntity>(
        ServerFailure(message: 'prayer_calculation_failed', cause: error),
      );
    }
  }

  bool _invalid(double lat, double lng, DateTime date) =>
      lat.isNaN ||
      lng.isNaN ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180 ||
      date.year < 1900 ||
      date.year > 2200;
}

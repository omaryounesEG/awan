import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';

/// "Give me the times of a given day."
class GetDayPrayerTimes {
  const GetDayPrayerTimes(this._repository);

  final PrayerRepository _repository;

  Future<DayPrayerTimes> call(DateTime date, {bool forceRecompute = false}) =>
      _repository.day(date, forceRecompute: forceRecompute);
}

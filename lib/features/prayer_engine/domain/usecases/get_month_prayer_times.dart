import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';

/// "Give me the whole month" — the monthly timetable screen.
class GetMonthPrayerTimes {
  const GetMonthPrayerTimes(this._repository);

  final PrayerRepository _repository;

  Future<List<DayPrayerTimes>> call(int year, int month) =>
      _repository.month(year, month);
}

import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';

/// "What is the next prayer?" — the dashboard's whole reason to exist.
class GetNextPrayer {
  const GetNextPrayer(this._repository);

  final PrayerRepository _repository;

  Future<NextPrayer?> call(DateTime now) => _repository.next(now);
}

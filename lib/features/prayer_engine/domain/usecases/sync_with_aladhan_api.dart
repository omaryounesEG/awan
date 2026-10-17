import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';

/// The hybrid half of the engine: once a week (or on demand) the offline
/// results are checked against Aladhan. A mismatch larger than
/// `AppConstants.syncMismatchThresholdMinutes` is surfaced to the user with a
/// suggestion to review the calculation method — never applied silently.
class SyncPrayerTimesWithApi {
  const SyncPrayerTimesWithApi(this._repository);

  final PrayerRepository _repository;

  /// Returns the worst observed difference, in minutes.
  Future<Either<Failure, int>> call(DateTime date) =>
      _repository.syncWithAladhanApi(date);
}

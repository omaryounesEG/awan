import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_offline_prayer_times.dart';

/// Step 3 contract tests: the use case returns `Either`, the entity carries
/// current/next, and an impossible location is a typed failure rather than an
/// exception.
void main() {
  const GetOfflinePrayerTimes useCase = GetOfflinePrayerTimes();
  final DateTime day = DateTime(2026, 10, 10);

  group('GetOfflinePrayerTimes', () {
    test('returns Right with the six times for Cairo', () async {
      final Either<Failure, PrayerTimesEntity> result = await useCase(
        OfflinePrayerParams(latitude: 30.0444, longitude: 31.2357, date: day),
      );

      expect(result.isRight(), isTrue);
      final PrayerTimesEntity entity =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(entity.date, day);
      expect(entity.ordered.length, 6);
      for (int i = 1; i < entity.ordered.length; i++) {
        expect(entity.ordered[i].isAfter(entity.ordered[i - 1]), isTrue);
      }
      // Defaults: Egyptian method, shafi madhab.
      expect(entity.spec?.method, PrayerMethod.egyptian);
      expect(entity.spec?.madhab, AsrMadhab.shafi);
    });

    test('rejects an out-of-range latitude with a Left', () async {
      final Either<Failure, PrayerTimesEntity> result = await useCase(
        OfflinePrayerParams(latitude: 120, longitude: 31.2357, date: day),
      );

      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => throw StateError('')), isA<Failure>());
    });

    test('rejects an out-of-range longitude with a Left', () async {
      final Either<Failure, PrayerTimesEntity> result = await useCase(
        OfflinePrayerParams(latitude: 30.0444, longitude: 400, date: day),
      );
      expect(result.isLeft(), isTrue);
    });

    test('honours the injected clock when deriving current/next', () async {
      final Either<Failure, PrayerTimesEntity> result = await useCase(
        OfflinePrayerParams(
          latitude: 30.0444,
          longitude: 31.2357,
          date: day,
          // 00:01 — before fajr, so nothing is "current" yet.
          now: DateTime(2026, 10, 10, 0, 1),
        ),
      );

      final PrayerTimesEntity entity =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(entity.currentPrayer, isNull);
      expect(entity.nextPrayer, PrayerName.fajr);
    });
  });

  group('PrayerTimesEntity', () {
    test('at() moves current/next forward without recalculating', () {
      final PrayerTimesEntity entity = PrayerTimesEntity.fromDay(
        probeDay(DateTime(2026, 10, 10)),
        now: DateTime(2026, 10, 10, 0, 1),
      );

      final PrayerTimesEntity afterDhuhr =
          entity.at(entity.dhuhr.add(const Duration(minutes: 1)));
      expect(afterDhuhr.currentPrayer, PrayerName.dhuhr);
      expect(afterDhuhr.nextPrayer, PrayerName.asr);
      expect(afterDhuhr.fajr, entity.fajr); // untouched
    });

    test('remaining() is null after isha', () {
      final PrayerTimesEntity entity = PrayerTimesEntity.fromDay(
        probeDay(DateTime(2026, 10, 10)),
        now: DateTime(2026, 10, 10, 23, 59),
      );
      expect(entity.nextPrayer, isNull);
      expect(entity.isDayOver, isTrue);
      expect(entity.remaining(DateTime(2026, 10, 10, 23, 59)), isNull);
    });

    test('equality is by value', () {
      final PrayerTimesEntity a = PrayerTimesEntity.fromDay(
        probeDay(DateTime(2026, 10, 10)),
        now: DateTime(2026, 10, 10, 5),
      );
      final PrayerTimesEntity b = a.at(DateTime(2026, 10, 10, 5));
      expect(a, b);
    });
  });
}

/// Small helper so the entity tests can build a day without going async.
DayPrayerTimes probeDay(DateTime date) => const CalculatePrayerTimes().forDate(
      date: date,
      spec: PrayerCalcSpec.fallback(latitude: 30.0444, longitude: 31.2357),
    );

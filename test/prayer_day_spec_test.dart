import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';

/// Counts the days the app actually asks for, and answers with a different fajr
/// each time so a cached answer is unmistakable.
class _CountingRepo implements PrayerRepository {
  int dayCalls = 0;

  @override
  Future<DayPrayerTimes> day(
    DateTime date, {
    bool forceRecompute = false,
  }) async {
    dayCalls++;
    final DateTime base =
        DateTime(date.year, date.month, date.day, 4 + dayCalls, 30);
    return DayPrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      times: <PrayerName, DateTime>{
        for (final PrayerName name in PrayerName.values)
          name: base.add(Duration(hours: name.index * 2)),
      },
      spec: const PrayerCalcSpec(
        latitude: 0,
        longitude: 0,
        method: PrayerMethod.egyptian,
        madhab: AsrMadhab.shafi,
        highLatitude: HighLatitude.middleOfTheNight,
      ),
      computedAt: base,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not needed here: \${invocation.memberName}');
}

void main() {
  test('changing the place recomputes the day instead of serving the old city',
      () async {
    final _CountingRepo repo = _CountingRepo();
    final StateProvider<AppSettings> settings =
        StateProvider<AppSettings>((Ref ref) => const AppSettings());
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsProvider.overrideWith((Ref ref) => ref.watch(settings)),
        prayerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final DateTime day = DateTime(2026, 10, 10);
    final DayPrayerTimes cairo =
        await container.read(dayPrayerTimesProvider(day).future);
    expect(cairo.times[PrayerName.fajr]!.hour, 5);
    expect(repo.dayCalls, 1);

    // The reader picks a different city: the same date must be recomputed, not
    // served from the provider's memo (the bug the pre-prayer reminder exposed).
    container.read(settings.notifier).state =
        const AppSettings(latitude: 25.2854, longitude: 51.531);
    final DayPrayerTimes doha =
        await container.read(dayPrayerTimesProvider(day).future);
    expect(repo.dayCalls, 2);
    expect(doha.times[PrayerName.fajr]!.hour, 6,
        reason: 'the memo held the old place until the spec was watched');
  });
}

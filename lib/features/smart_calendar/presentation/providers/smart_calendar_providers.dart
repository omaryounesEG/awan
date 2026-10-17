
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/error/failures.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/presentation/providers/mosque_providers.dart';
import 'package:awan/features/smart_calendar/data/repositories/smart_calendar_repository_impl.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';
import 'package:awan/features/smart_calendar/domain/usecases/build_rolling_blocks.dart';
import 'package:awan/features/smart_calendar/domain/usecases/decide_context.dart';
import 'package:awan/features/smart_calendar/domain/usecases/detect_conflicts.dart';

/// One repository for the screen and the background pass alike.
final Provider<SmartCalendarRepositoryImpl> smartCalendarRepositoryProvider =
    Provider<SmartCalendarRepositoryImpl>(
  (Ref ref) => SmartCalendarRepositoryImpl(),
);


const BuildRollingBlocks _blockBuilder = BuildRollingBlocks();
const DetectConflicts _conflictDetector = DetectConflicts();
const DecideContext _contextEngine = DecideContext();

/// The blocks the architecture wants to exist, for the current settings.
///
/// Recomputed when the window, the duration or the working hours change — and on
/// every day boundary, because the rolling window slides.
final FutureProvider<List<PrayerBlock>> smartBlocksProvider =
    FutureProvider<List<PrayerBlock>>((Ref ref) async {
  final AppSettings settings = ref.watch(settingsProvider);
  final int days = settings.smartBlockDays.clamp(1, 30);
  final DateTime today = DateTime.now();
  final List<DayPrayerTimes> computed = <DayPrayerTimes>[];
  for (int offset = 0; offset < days; offset++) {
    final DateTime date =
        DateTime(today.year, today.month, today.day + offset);
    computed.add(await ref.read(prayerRepositoryProvider).day(date));
  }
  return _blockBuilder(
    days: computed,
    prayers: <PrayerName>{
      for (final PrayerName prayer in PrayerName.obligatory)
        if (settings.isPrayerEnabled(prayer.key)) prayer,
    },
    workStart: ClockTime.parse(settings.smartWorkStart),
    workEnd: ClockTime.parse(settings.smartWorkEnd),
    duration: Duration(minutes: settings.smartBlockMinutes.clamp(5, 60)),
    now: today,
  );
});

/// The phone's own events for the same window — read, never written, here.
final FutureProvider<List<CalendarEvent>> calendarEventsProvider =
    FutureProvider<List<CalendarEvent>>((Ref ref) async {
  final SmartCalendarRepositoryImpl repository =
      ref.read(smartCalendarRepositoryProvider);
  if (!await repository.hasPermission()) return const <CalendarEvent>[];
  final AppSettings settings = ref.read(settingsProvider);
  final DateTime from = DateTime.now();
  final DateTime to = from.add(Duration(days: settings.smartBlockDays + 1));
  return repository.eventsBetween(from, to);
});

/// Meetings sitting on a prayer.
final FutureProvider<List<Conflict>> smartConflictsProvider =
    FutureProvider<List<Conflict>>((Ref ref) async {
  final List<PrayerBlock> blocks = await ref.watch(smartBlocksProvider.future);
  final List<CalendarEvent> events =
      await ref.watch(calendarEventsProvider.future);
  return _conflictDetector(events: events, blocks: blocks);
});

/// True once the reader has granted both calendar permissions.
final FutureProvider<bool> calendarPermissionProvider =
    FutureProvider<bool>((Ref ref) =>
        ref.watch(smartCalendarRepositoryProvider).hasPermission());

/// The mosques around the reader, fetched once per position and kept.
final FutureProvider<List<Mosque>> nearbyMosquesProvider =
    FutureProvider<List<Mosque>>((Ref ref) async {
  final AppSettings settings = ref.watch(settingsProvider);
  final Either<Failure, List<MosqueEntity>> result =
      await ref.watch(mosqueRepositoryProvider).nearby(
            latitude: settings.latitude,
            longitude: settings.longitude,
            radiusMeters: 3000,
          );
  return result.fold(
    (Failure _) => const <Mosque>[],
    (List<MosqueEntity> items) => <Mosque>[
      for (final MosqueEntity mosque in items.take(15))
        Mosque(
          id: mosque.id,
          name: mosque.name,
          latitude: mosque.latitude,
          longitude: mosque.longitude,
          distanceMeters: mosque.distanceMeters.round(),
        ),
    ],
  );
});

/// What the phone would do right now, given the calendar and the position.
///
/// Deliberately synchronous over the *cached* value of both inputs: the card
/// must answer instantly, and a slow map lookup may only refine the answer,
/// never hold it hostage.
final Provider<ContextDecision> contextDecisionProvider =
    Provider<ContextDecision>((Ref ref) {
  final List<CalendarEvent> events =
      ref.watch(calendarEventsProvider).valueOrNull ?? const <CalendarEvent>[];
  final List<Mosque> mosques =
      ref.watch(nearbyMosquesProvider).valueOrNull ?? const <Mosque>[];
  final AppSettings settings = ref.read(settingsProvider);
  return _contextEngine(
    mosques: mosques,
    events: events,
    now: DateTime.now(),
    radiusMeters: settings.smartSilentRadius,
  );
});

/// Writes the current blocks to the phone's calendar and reports what happened.
final StateProvider<SyncOutcome?> lastSyncProvider =
    StateProvider<SyncOutcome?>((Ref ref) => null);

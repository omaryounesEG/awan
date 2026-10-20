import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/adhkar/data/adhkar_audio_service.dart';
import 'package:awan/features/adhkar/data/adhkar_progress_store.dart';
import 'package:awan/features/adhkar/data/adhkar_reminders.dart';
import 'package:awan/features/adhkar/data/adhkar_repository.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';

final Provider<AdhkarRepository> adhkarRepositoryProvider =
    Provider<AdhkarRepository>((Ref ref) => AdhkarRepository());

final FutureProvider<AdhkarChapter> adhkarChapterProvider =
    FutureProvider<AdhkarChapter>(
  (Ref ref) => ref.watch(adhkarRepositoryProvider).load(),
);

final Provider<AdhkarProgressStore> adhkarProgressStoreProvider =
    Provider<AdhkarProgressStore>((Ref ref) => AdhkarProgressStore());

final Provider<AdhkarAudioService> adhkarAudioServiceProvider =
    Provider<AdhkarAudioService>((Ref ref) {
  final AdhkarAudioService service = AdhkarAudioService();
  ref.onDispose(service.stop);
  return service;
});

final Provider<AdhkarReminders> adhkarRemindersProvider =
    Provider<AdhkarReminders>((Ref ref) => AdhkarReminders());

/// Midnight today, so a long session that crosses midnight still records the
/// day it started in until the app is reopened.
DateTime adhkarToday() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Today's two sittings.
final FutureProvider<Map<AdhkarSession, AdhkarSessionProgress>>
    adhkarTodayProgressProvider =
    FutureProvider<Map<AdhkarSession, AdhkarSessionProgress>>((Ref ref) async {
  final AdhkarChapter chapter = await ref.watch(adhkarChapterProvider.future);
  final AdhkarProgressStore store = ref.watch(adhkarProgressStoreProvider);
  final DateTime day = adhkarToday();
  return <AdhkarSession, AdhkarSessionProgress>{
    AdhkarSession.morning: AdhkarSessionProgress.of(
      chapter.items,
      await store.countsFor(day, AdhkarSession.morning),
    ),
    AdhkarSession.evening: AdhkarSessionProgress.of(
      chapter.items,
      await store.countsFor(day, AdhkarSession.evening),
    ),
  };
});

/// The month, computed from the same counters the screen writes.
class AdhkarMonthSummary {
  const AdhkarMonthSummary({
    required this.days,
    required this.morningDays,
    required this.eveningDays,
    required this.bothDays,
    required this.morningAverage,
    required this.eveningAverage,
  });

  final Map<DateTime, AdhkarDayCounts> days;
  final int morningDays;
  final int eveningDays;
  final int bothDays;
  final double morningAverage;
  final double eveningAverage;
}

final FutureProviderFamily<AdhkarMonthSummary, DateTime>
    adhkarMonthProvider =
    FutureProvider.family<AdhkarMonthSummary, DateTime>((Ref ref, DateTime month) async {
  final AdhkarChapter chapter = await ref.watch(adhkarChapterProvider.future);
  final Map<String, AdhkarDayCounts> all =
      await ref.watch(adhkarProgressStoreProvider).readAll();

  final Map<DateTime, AdhkarDayCounts> days = <DateTime, AdhkarDayCounts>{};
  int morningDays = 0;
  int eveningDays = 0;
  int bothDays = 0;
  double morningSum = 0;
  double eveningSum = 0;
  int counted = 0;

  all.forEach((String key, AdhkarDayCounts value) {
    final DateTime? date = DateTime.tryParse(key);
    if (date == null || date.year != month.year || date.month != month.month) {
      return;
    }
    days[DateTime(date.year, date.month, date.day)] = value;
    final AdhkarSessionProgress morning =
        AdhkarSessionProgress.of(chapter.items, value.morning);
    final AdhkarSessionProgress evening =
        AdhkarSessionProgress.of(chapter.items, value.evening);
    if (morning.finished) morningDays++;
    if (evening.finished) eveningDays++;
    if (morning.finished && evening.finished) bothDays++;
    morningSum += morning.ratio;
    eveningSum += evening.ratio;
    counted++;
  });

  return AdhkarMonthSummary(
    days: days,
    morningDays: morningDays,
    eveningDays: eveningDays,
    bothDays: bothDays,
    morningAverage: counted == 0 ? 0 : morningSum / counted,
    eveningAverage: counted == 0 ? 0 : eveningSum / counted,
  );
});

/// Writes go through here so one place refreshes the screens.
class AdhkarActions {
  AdhkarActions(this._ref);

  final Ref _ref;

  Future<void> increment(AdhkarSession session, AdhkarItem item) async {
    await _ref
        .read(adhkarProgressStoreProvider)
        .increment(adhkarToday(), session, item);
    _refresh();
  }

  Future<void> complete(AdhkarSession session, AdhkarItem item) async {
    await _ref
        .read(adhkarProgressStoreProvider)
        .complete(adhkarToday(), session, item);
    _refresh();
  }

  Future<void> resetItem(AdhkarSession session, AdhkarItem item) async {
    await _ref
        .read(adhkarProgressStoreProvider)
        .resetItem(adhkarToday(), session, item.id);
    _refresh();
  }

  Future<void> resetSession(AdhkarSession session) async {
    await _ref
        .read(adhkarProgressStoreProvider)
        .resetSession(adhkarToday(), session);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(adhkarTodayProgressProvider);
    _ref.invalidate(adhkarMonthProvider);
  }
}

final Provider<AdhkarActions> adhkarActionsProvider =
    Provider<AdhkarActions>(AdhkarActions.new);

/// The reminder settings, read once per screen open.
class AdhkarReminderSettings {
  const AdhkarReminderSettings({
    required this.enabled,
    required this.morningMinutes,
    required this.eveningMinutes,
  });

  final bool enabled;
  final int morningMinutes;
  final int eveningMinutes;

  String get morningLabel => _label(morningMinutes);
  String get eveningLabel => _label(eveningMinutes);

  static String _label(int minutes) {
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;
    final String suffix = hour < 12 ? 'ص' : 'م';
    final int display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

final FutureProvider<AdhkarReminderSettings> adhkarReminderSettingsProvider =
    FutureProvider<AdhkarReminderSettings>((Ref ref) async {
  final AdhkarReminders reminders = ref.watch(adhkarRemindersProvider);
  return AdhkarReminderSettings(
    enabled: await reminders.enabled(),
    morningMinutes: await reminders.morningMinutes(),
    eveningMinutes: await reminders.eveningMinutes(),
  );
});

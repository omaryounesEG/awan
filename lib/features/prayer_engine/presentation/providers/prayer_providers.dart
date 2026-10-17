import 'dart:async';
import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/network/network_info.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/presentation/l10n/reminder_wording.dart';
import 'package:awan/core/utils/clock_shift.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/data/datasources/aladhan_remote_datasource.dart';
import 'package:awan/features/prayer_engine/data/datasources/prayer_local_datasource.dart';
import 'package:awan/features/prayer_engine/data/repositories/prayer_repository_impl.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/pre_prayer_due.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_day_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_offline_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_month_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_next_prayer.dart';
import 'package:awan/features/prayer_engine/domain/usecases/sync_with_aladhan_api.dart';
import 'package:awan/features/prayer_engine/presentation/providers/qibla_providers.dart';

// ---------------------------------------------------------------- data layer

final Provider<CalculatePrayerTimes> calculatePrayerTimesProvider =
    Provider<CalculatePrayerTimes>((Ref ref) => const CalculatePrayerTimes());

final Provider<PrayerLocalDatasource> prayerLocalDatasourceProvider =
    Provider<PrayerLocalDatasource>(
  (Ref ref) => PrayerLocalDatasource(
    ref.watch(isarServiceProvider),
    ref.watch(calculatePrayerTimesProvider),
  ),
);

final Provider<AladhanRemoteDatasource> aladhanRemoteDatasourceProvider =
    Provider<AladhanRemoteDatasource>(
  (Ref ref) => AladhanRemoteDatasource(ref.watch(apiClientProvider)),
);

final Provider<NetworkInfo> networkInfoProvider = Provider<NetworkInfo>(
  (Ref ref) => NetworkInfo(),
);

final Provider<PrayerRepository> prayerRepositoryProvider =
    Provider<PrayerRepository>((Ref ref) {
  return PrayerRepositoryImpl(
    local: ref.watch(prayerLocalDatasourceProvider),
    remote: ref.watch(aladhanRemoteDatasourceProvider),
    network: ref.watch(networkInfoProvider),
    notifications: ref.watch(notificationServiceProvider),
    silentMode: ref.watch(silentModeServiceProvider),
    // Read lazily so a settings change is picked up on the next call.
    settings: () => ref.read(settingsProvider),
    adhanText: (PrayerName prayer, DateTime at) {
      final AppSettings s = ref.read(settingsProvider);
      final l10n = localizationsFor(s.localeCode);
      final String name = prayerLabel(l10n, prayer);
      final String clock = formatClock(at, s.localeCode);
      final String city = s.isArabic ? s.cityAr : s.cityEn;
      return (
        title: '${l10n.adhan} · $name',
        body: '$clock${city.isEmpty ? '' : ' — $city'}',
      );
    },
    // «باقي ٢٠ دقيقة على العصر» — a warning, not an announcement, so it is
    // worded and titled differently from the adhan itself.
    reminderText: (PrayerName prayer, DateTime at, int minutes) {
      final AppSettings s = ref.read(settingsProvider);
      final l10n = localizationsFor(s.localeCode);
      final String name = prayerLabel(l10n, prayer);
      final String clock = formatClock(at, s.localeCode);
      return (
        title: prePrayerHeadline(l10n, minutes, name),
        body: '$clock · ${l10n.reminderPrepare(name)}',
      );
    },
    // The lock-screen card: the same wording shape as the adhan, titled as
    // «الصلاة القادمة» so it cannot be mistaken for an announcement.
    cardText: (
      PrayerName prayer,
      DateTime at,
      List<({PrayerName prayer, DateTime at})> rest,
    ) {
      final AppSettings s = ref.read(settingsProvider);
      final l10n = localizationsFor(s.localeCode);
      final String name = prayerLabel(l10n, prayer);
      final String clock = formatClock(at, s.localeCode);
      final String city = s.isArabic ? s.cityAr : s.cityEn;
      // «٣:٤٢ م — القاهرة» then the day's remaining clocks, one line, so the
      // card answers «المتبقي على كل صلاة» and not just the next one.
      final String line = rest
          .map(
            (({PrayerName prayer, DateTime at}) item) =>
                '${prayerLabel(l10n, item.prayer)} ${formatClock(item.at, s.localeCode)}',
          )
          .join(' · ');
      return (
        title: '${l10n.nextPrayer} · $name',
        body: <String>[
          '$clock${city.isEmpty ? '' : ' — $city'}',
          if (line.isNotEmpty) line,
        ].join('\n'),
      );
    },
    // The card in the twenty minutes after the adhan: elapsed, not remaining.
    elapsedText: (PrayerName prayer, DateTime at, Duration elapsed) {
      final AppSettings s = ref.read(settingsProvider);
      final l10n = localizationsFor(s.localeCode);
      final String name = prayerLabel(l10n, prayer);
      final String clock = formatClock(at, s.localeCode);
      return (
        title: '${l10n.adhanPassed} · $name',
        body: '$clock · ${l10n.elapsedHint}',
      );
    },
    channelNames: () {
      final AppSettings s = ref.read(settingsProvider);
      final l10n = localizationsFor(s.localeCode);
      return (
        adhan: l10n.adhan,
        adhanDescription: l10n.adhanNotifications,
        reminder: l10n.adhanNotifications,
        friday: l10n.fridaySchedule,
      );
    },
  );
});

// ------------------------------------------------------------ domain objects

final Provider<PrayerCalcSpec> prayerSpecProvider = Provider<PrayerCalcSpec>(
  (Ref ref) {
    final AppSettings s = ref.watch(settingsProvider);
    return PrayerCalcSpec(
      latitude: s.latitude,
      longitude: s.longitude,
      method: PrayerMethod.fromKey(s.calcMethod),
      madhab: AsrMadhab.fromKey(s.madhab),
      highLatitude: HighLatitude.fromKey(s.highLatitudeRule),
      adjustments: s.adjustments,
    );
  },
);

final Provider<GetDayPrayerTimes> getDayPrayerTimesProvider =
    Provider<GetDayPrayerTimes>(
  (Ref ref) => GetDayPrayerTimes(ref.watch(prayerRepositoryProvider)),
);

/// The offline engine as a use case (Step 3, Task 2).
///
/// Const-constructed: it is pure arithmetic with no collaborators, so every
/// caller shares one instance.
final Provider<GetOfflinePrayerTimes> getOfflinePrayerTimesProvider =
    Provider<GetOfflinePrayerTimes>((Ref ref) => const GetOfflinePrayerTimes());

final Provider<GetMonthPrayerTimes> getMonthPrayerTimesProvider =
    Provider<GetMonthPrayerTimes>(
  (Ref ref) => GetMonthPrayerTimes(ref.watch(prayerRepositoryProvider)),
);

final Provider<GetNextPrayer> getNextPrayerProvider = Provider<GetNextPrayer>(
  (Ref ref) => GetNextPrayer(ref.watch(prayerRepositoryProvider)),
);

final Provider<SyncPrayerTimesWithApi> syncPrayerTimesWithApiProvider =
    Provider<SyncPrayerTimesWithApi>(
  (Ref ref) => SyncPrayerTimesWithApi(ref.watch(prayerRepositoryProvider)),
);

// --------------------------------------------------------------- presentation

/// How many adhan notifications the OS currently holds.
///
/// Surfaced in settings so "no adhan today" can never be a silent failure; every
/// scheduling call invalidates it.
final FutureProvider<int> pendingAdhanCountProvider = FutureProvider<int>(
  (Ref ref) => ref.watch(notificationServiceProvider).pendingCount(),
);

/// Local midnight of the day being displayed.
///
/// Every date-keyed provider must use *this*, never a raw `DateTime.now()`: as a
/// family key, a value that carries seconds and milliseconds changes on every
/// rebuild, so the provider would be recreated (and stay `loading`) forever —
/// which is exactly what the one-second countdown ticker would trigger.
final Provider<DateTime> todayProvider = Provider<DateTime>((Ref ref) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// The user's manual summer/winter-time correction, in minutes.
///
/// `auto` resolves to 0: the device's own timezone is trusted by default. This is
/// the single value both the screens and the adhan alarms are built from, which is
/// what guarantees the shown time and the ringing time never disagree — see
/// `core/utils/clock_shift.dart`.
final Provider<int> dstShiftMinutesProvider = Provider<int>(
  (Ref ref) => resolveDstMinutes(ref.watch(settingsProvider).dstMode),
);

/// Today's times (keyed by local midnight), cached by Isar.
///
/// The cache holds the untouched astronomical instants; the manual clock
/// correction is applied on the way out, so flipping the setting re-renders
/// instantly and never invalidates a month of cached calculations.
final FutureProviderFamily<DayPrayerTimes, DateTime> dayPrayerTimesProvider =
    FutureProvider.family<DayPrayerTimes, DateTime>(
  (Ref ref, DateTime date) async {
    // Watching the spec is what makes a *place* change visible here at all: the
    // repository caches by date **and** spec, but this provider is only keyed by
    // date, so without this line its own memo keeps the previous city's times for
    // the rest of the day — a stale day that only shows up as "the reminder never
    // appeared after I changed the city".
    ref.watch(prayerSpecProvider);
    final DayPrayerTimes day = await ref.watch(getDayPrayerTimesProvider)(date);
    return day.shifted(ref.watch(dstShiftMinutesProvider));
  },
);

final FutureProviderFamily<List<DayPrayerTimes>, DateTime>
    monthPrayerTimesProvider =
    FutureProvider.family<List<DayPrayerTimes>, DateTime>(
  (Ref ref, DateTime month) async {
    final DateTime target = DateTime(month.year, month.month);
    final List<DayPrayerTimes> days =
        await ref.watch(getMonthPrayerTimesProvider)(target.year, target.month);
    final int shift = ref.watch(dstShiftMinutesProvider);
    return <DayPrayerTimes>[
      for (final DayPrayerTimes day in days) day.shifted(shift),
    ];
  },
);

/// Qibla bearing for the current location (pure maths, no sensor required).
///
/// Kept as the single number older call sites read: it is now derived from the
/// same use case the compass uses (`GetQiblaDirection`), so the dashboard and the
/// compass can never disagree by a degree.
final Provider<double> qiblaBearingProvider = Provider<double>(
  (Ref ref) =>
      ref.watch(qiblaDirectionProvider)?.bearingDegrees ??
      ref
          .watch(calculatePrayerTimesProvider)
          .qiblaBearing(ref.watch(prayerSpecProvider)),
);

final FutureProvider<({DateTime middle, DateTime lastThird})>
    nightTimesProvider = FutureProvider<({DateTime middle, DateTime lastThird})>(
  (Ref ref) async {
    final DayPrayerTimes today =
        await ref.watch(dayPrayerTimesProvider(DateTime.now()).future);
    return ref.watch(calculatePrayerTimesProvider).nightTimes(today);
  },
);

/// Whether the user has ever verified the angles online.
final Provider<int?> lastVerifiedDiffProvider = Provider<int?>(
  (Ref ref) => ref.watch(settingsProvider).lastVerifiedDiffMinutes,
);

/// "Verify now" — feeds the settings screen and the mismatch banner.
final FutureProvider<Either<Failure, int>> runVerificationProvider =
    FutureProvider<Either<Failure, int>>((Ref ref) async {
  final Either<Failure, int> result =
      await ref.watch(syncPrayerTimesWithApiProvider)(DateTime.now());
  result.fold((Failure _) {}, (int diff) {
    ref.read(settingsControllerProvider.notifier).setVerificationResult(
          at: DateTime.now(),
          diffMinutes: diff,
        );
  });
  return result;
});

/// The countdown state — updated by a timer that exists **only** while the app
/// is in the foreground (the shell pauses it on `AppLifecycleState.paused`).
class NextPrayerState {
  const NextPrayerState({
    this.next,
    this.remaining = Duration.zero,
    this.loading = true,
  });

  final NextPrayer? next;
  final Duration remaining;
  final bool loading;

  bool get isDue => next != null && remaining.inSeconds <= 0;
}

class NextPrayerTicker extends StateNotifier<NextPrayerState> {
  NextPrayerTicker(this._ref) : super(const NextPrayerState()) {
    _load();
  }

  final Ref _ref;
  Timer? _timer;
  bool _active = false;
  bool _loading = false;

  /// Called by the app shell: `true` on resume, `false` on pause/detach.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (active) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _tick();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (Timer _) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    final NextPrayer? next = state.next;
    if (next == null) {
      if (!_loading) _load();
      return;
    }
    final Duration remaining = next.at.difference(DateTime.now());
    if (remaining.isNegative) {
      if (!_loading) _load();
      return;
    }
    state = NextPrayerState(next: next, remaining: remaining, loading: false);
  }

  Future<void> _load() async {
    _loading = true;
    try {
      final NextPrayer? next =
          await _ref.read(getNextPrayerProvider)(DateTime.now());
      final Duration remaining = next == null
          ? Duration.zero
          : next.at.difference(DateTime.now());
      state = NextPrayerState(next: next, remaining: remaining, loading: false);
    } finally {
      _loading = false;
    }
  }

  /// Re-reads the times (used after a settings or location change).
  Future<void> refresh() => _load();

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// Occurrences the reader has already waved away this session.
///
/// Deliberately in memory only: a dismissed reminder that reappears after a
/// restart is a *valid* reminder, and writing a transient dismissal to disk
/// would mean a crash between the two writes could silence a real one.
final StateProvider<Set<String>> dismissedPrePrayerProvider =
    StateProvider<Set<String>>((Ref ref) => <String>{});

/// The hourglass that should be floating right now, or null.
///
/// It rides on [nextPrayerProvider]'s one-second ticker instead of starting a
/// second timer: the app already has exactly one clock in the foreground, and
/// two timers would mean two chances to disagree.
/// The clock the hourglass reads.
///
/// At runtime it rides on [nextPrayerProvider]'s one-second ticker — the app
/// already has exactly one clock in the foreground and a second timer would only
/// be a second chance to disagree. Tests override it with a fixed instant, which
/// is what lets the banner be exercised without a repository or a ticker at all.
final Provider<DateTime> nowProvider = Provider<DateTime>((Ref ref) {
  ref.watch(nextPrayerProvider);
  return DateTime.now();
});

final Provider<PrePrayerDue?> prePrayerDueProvider =
    Provider<PrePrayerDue?>((Ref ref) {
  final AppSettings settings = ref.watch(settingsProvider);
  if (!settings.preAdhanEnabled) return null;

  final DayPrayerTimes? day = ref
      .watch(dayPrayerTimesProvider(ref.watch(todayProvider)))
      .valueOrNull;
  if (day == null) return null;

  return duePrePrayer(
    times: day.times,
    now: ref.watch(nowProvider),
    minutes: settings.preAdhanMinutes > 0
        ? settings.preAdhanMinutes
        : AppConstants.defaultPreAdhanMinutes,
    enabled: true,
    dismissed: ref.watch(dismissedPrePrayerProvider),
  );
});

final StateNotifierProvider<NextPrayerTicker, NextPrayerState>
    nextPrayerProvider =
    StateNotifierProvider<NextPrayerTicker, NextPrayerState>(
  (Ref ref) => NextPrayerTicker(ref),
);

/// Computes a whole month off the UI isolate (the library and add-on flows use
/// this while they are also doing disk work).
Future<List<DayPrayerTimes>> computeMonthInIsolate(
  PrayerCalcSpec spec,
  int year,
  int month,
) {
  return Isolate.run(
    () => const CalculatePrayerTimes().forMonth(year: year, month: month, spec: spec),
  );
}

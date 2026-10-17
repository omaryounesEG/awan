import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_offline_prayer_times.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';

part 'prayer_provider.g.dart';

/// Step 3, Task 5 — the controller the UI (Step 4) will read.
///
/// Three decisions worth noting:
///
/// * **The location comes from the settings**, whose defaults are Cairo
///   (30.0444, 31.2357, `AppConstants.defaultLatitude/Longitude`) — so the app
///   runs with the exact coordinates the step asked to mock, but without a
///   hard-coded value that would later have to be *un*-hard-coded.
/// * **No polling.** The remaining time is re-derived from the already-computed
///   entity by a single one-second `Timer` that only exists while the app is in
///   the foreground ([setForeground]); `adhan_dart` is never called by it.
/// * **Errors are typed.** The use case returns `Either<Failure, …>`; it is
///   converted to an `AsyncValue.error` here, at the boundary, so the UI never
///   sees an exception and never sees an `Either`.
@Riverpod(keepAlive: true)
class PrayerController extends _$PrayerController {
  Timer? _ticker;

  @override
  Future<PrayerTimesEntity> build() async {
    // Rebuilds when the location or the calculation parameters change.
    final AppSettings settings = ref.watch(settingsProvider);
    final DateTime today = ref.watch(todayProvider);

    ref.onDispose(_stopTicker);

    final Either<Failure, PrayerTimesEntity> result =
        await ref.watch(getOfflinePrayerTimesProvider)(
      OfflinePrayerParams(
        latitude: settings.latitude,
        longitude: settings.longitude,
        date: today,
        method: PrayerMethod.fromKey(settings.calcMethod),
        madhab: AsrMadhab.fromKey(settings.madhab),
        highLatitude: HighLatitude.fromKey(settings.highLatitudeRule),
        adjustments: settings.adjustments,
      ),
    );

    // `Left` becomes a thrown `Failure`, which Riverpod exposes as
    // `AsyncValue.error` — the presentation layer stays Either-free.
    return result.fold(
      (Failure failure) => throw failure,
      (PrayerTimesEntity entity) => entity,
    );
  }

  /// Starts or stops the one-second countdown ticker.
  ///
  /// The app shell calls this from `WidgetsBindingObserver`: `true` on
  /// `resumed`, `false` on `paused`/`inactive`/`detached`. A backgrounded app
  /// therefore holds **no** timer at all — that is the entire battery story for
  /// the countdown.
  void setForeground(bool foreground) {
    if (foreground) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  /// Recalculates from scratch (after a location or method change).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      final PrayerTimesEntity? current = state.valueOrNull;
      if (current == null) return; // still loading or failed
      // Pure re-derivation: no I/O, no recalculation, no allocation of a new
      // entity beyond the copy that carries the new current/next pair.
      state = AsyncData<PrayerTimesEntity>(current.at(DateTime.now()));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

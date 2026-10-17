// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$prayerControllerHash() => r'e9412520e7cf680c6dae71c73265dada49527a90';

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
///
/// Copied from [PrayerController].
@ProviderFor(PrayerController)
final prayerControllerProvider =
    AsyncNotifierProvider<PrayerController, PrayerTimesEntity>.internal(
  PrayerController.new,
  name: r'prayerControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$prayerControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PrayerController = AsyncNotifier<PrayerTimesEntity>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

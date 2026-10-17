import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/network/network_info.dart';
import 'package:awan/core/services/audio_manager_service.dart';
import 'package:awan/core/services/sound_preview_service.dart';
import 'package:awan/core/services/heading_service.dart';
import 'package:awan/core/services/isar_service.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/services/location/location_service.dart';
import 'package:awan/core/services/clock_overlay_service.dart';
import 'package:awan/core/services/notification_service.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/settings/settings_controller.dart';

/// Dependency injection for the whole app.
///
/// Everything a layer needs is reachable from here and nothing reaches for a
/// global singleton, which is what keeps the features testable (each provider
/// can be overridden in a `ProviderScope` during a test).

/// Opened in `main()` and injected — no widget ever awaits a database open.
final Provider<IsarService> isarServiceProvider = Provider<IsarService>(
  (Ref ref) => throw UnimplementedError(
    'isarServiceProvider must be overridden in main()',
  ),
);

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final Provider<ApiClient> apiClientProvider =
    Provider<ApiClient>((Ref ref) => ApiClient());

final Provider<NetworkInfo> networkInfoProvider =
    Provider<NetworkInfo>((Ref ref) => NetworkInfo());

/// Live connectivity, so any screen can say "offline — showing saved data".
final StreamProvider<bool> connectivityProvider = StreamProvider<bool>(
  (Ref ref) => Connectivity().onConnectivityChanged.map(
        (List<ConnectivityResult> results) =>
            results.isNotEmpty && !results.contains(ConnectivityResult.none),
      ),
);

final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>(
  (Ref ref) => LocationService(dio: ref.watch(apiClientProvider).dio),
);

final Provider<ClockOverlayService> clockOverlayServiceProvider =
    Provider<ClockOverlayService>((Ref ref) => ClockOverlayService());

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) => NotificationService());

final Provider<AudioManagerService> audioManagerServiceProvider =
    Provider<AudioManagerService>((Ref ref) => AudioManagerService());

/// Auditions the bundled alert clips (native player, `res/raw`).
final Provider<SoundPreviewService> soundPreviewServiceProvider =
    Provider<SoundPreviewService>((Ref ref) => const SoundPreviewService());

/// The compass, over its own native `EventChannel`.
final Provider<HeadingService> headingServiceProvider =
    Provider<HeadingService>((Ref ref) => HeadingService());

/// Kept as an alias so older call sites keep reading naturally.
final Provider<AudioManagerService> silentModeServiceProvider =
    audioManagerServiceProvider;

final StateNotifierProvider<SettingsController, AppSettings>
    settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
  (Ref ref) => SettingsController(ref.watch(sharedPreferencesProvider)),
);

/// Convenience read-only view of the persistent settings.
final Provider<AppSettings> settingsProvider =
    Provider<AppSettings>((Ref ref) => ref.watch(settingsControllerProvider));

/// The location the whole app calculates with: the settings are the single
/// source of truth, so no two screens can drift apart.
final Provider<AppLocation> locationProvider = Provider<AppLocation>(
  (Ref ref) {
    final AppSettings s = ref.watch(settingsProvider);
    return AppLocation(
      latitude: s.latitude,
      longitude: s.longitude,
      cityAr: s.cityAr,
      cityEn: s.cityEn,
      fromDevice: s.locationMode == 'auto',
    );
  },
);

/// Turns a location failure reason into the domain `Failure` the UI renders.
Failure failureFromLocation(LocationFailure? reason) => switch (reason) {
      LocationFailure.permissionDenied ||
      LocationFailure.permissionPermanentlyDenied =>
        const PermissionFailure(),
      LocationFailure.serviceDisabled =>
        const LocationFailureReason(message: 'location_service_disabled'),
      LocationFailure.timeout =>
        const LocationFailureReason(message: 'location_timeout'),
      _ => const LocationFailureReason(),
    };

class LocationUiState {
  const LocationUiState({this.busy = false, this.failure, this.resolved});

  final bool busy;
  final Failure? failure;
  final AppLocation? resolved;

  LocationUiState copyWith({
    bool? busy,
    Failure? failure,
    AppLocation? resolved,
    bool clearFailure = false,
  }) =>
      LocationUiState(
        busy: busy ?? this.busy,
        failure: clearFailure ? null : (failure ?? this.failure),
        resolved: resolved ?? this.resolved,
      );
}

/// Drives "detect my location" and writes the outcome into the settings.
class LocationController extends StateNotifier<LocationUiState> {
  LocationController(this._service, this._settings)
      : super(const LocationUiState());

  final LocationService _service;
  final SettingsController _settings;

  Future<void> detect() async {
    state = state.copyWith(busy: true, clearFailure: true);
    final LocationOutcome outcome = await _service.resolve();
    final AppLocation? located = outcome.location;
    if (located == null) {
      state = LocationUiState(
        busy: false,
        failure: failureFromLocation(outcome.failure),
      );
      return;
    }
    await _settings.setLocation(
      latitude: located.latitude,
      longitude: located.longitude,
      cityAr: located.cityAr ?? '',
      cityEn: located.cityEn ?? '',
      mode: 'auto',
    );
    state = LocationUiState(busy: false, resolved: located);
  }

  Future<void> chooseCity(AppLocation location, {String? method}) async {
    await _settings.setLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      cityAr: location.cityAr ?? '',
      cityEn: location.cityEn ?? '',
      mode: 'manual',
    );
    if (method != null) await _settings.setCalculationMethod(method);
    state = LocationUiState(busy: false, resolved: location);
  }
}

final StateNotifierProvider<LocationController, LocationUiState>
    locationActionProvider =
    StateNotifierProvider<LocationController, LocationUiState>(
  (Ref ref) => LocationController(
    ref.watch(locationServiceProvider),
    ref.watch(settingsControllerProvider.notifier),
  ),
);

/// One-shot start-up work: notification channels, then cache pruning.
///
/// Runs after the first frame (watched from the shell) so nothing on the cold
/// start path can be delayed by it.
final FutureProvider<void> bootstrapProvider = FutureProvider<void>(
  (Ref ref) async {
    unawaited(
      ref.watch(notificationServiceProvider).init().catchError((Object _) {}),
    );
    await ref.watch(isarServiceProvider).prunePrayerCache();
  },
);

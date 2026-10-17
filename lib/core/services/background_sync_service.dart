import 'package:workmanager/workmanager.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/prayer_engine/data/datasources/prayer_sync_worker.dart';

/// Workmanager wiring — the app's *only* background footprint.
///
/// Layout note: the platform entry point has to be a top-level function that
/// can reach the work it performs, so this service is the one place in `core`
/// that imports a feature (the prayer engine's verification worker). Keeping it
/// here instead of in the feature makes the "how the OS wakes us" concern
/// explicit and single-sourced.
class BackgroundSyncService {
  BackgroundSyncService._();

  /// Registers a 7-day periodic verification with a network constraint.
  /// Idempotent: `ExistingWorkPolicy.keep` means re-registering is harmless.
  static Future<bool> registerWeeklyPrayerSync() async {
    try {
      await Workmanager().initialize(prayerSyncDispatcher);
      await Workmanager().registerPeriodicTask(
        AppConstants.weeklySyncTask,
        AppConstants.weeklySyncTask,
        frequency: AppConstants.weeklySyncFrequency,
        initialDelay: const Duration(minutes: 30),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      return true;
    } catch (_) {
      // Background scheduling is a nice-to-have; never block the app for it.
      return false;
    }
  }

  static Future<void> cancelWeeklyPrayerSync() async {
    try {
      await Workmanager().initialize(prayerSyncDispatcher);
      await Workmanager().cancelByUniqueName(AppConstants.weeklySyncTask);
    } catch (_) {
      // ignore
    }
  }
}

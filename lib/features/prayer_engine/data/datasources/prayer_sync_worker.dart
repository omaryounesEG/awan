import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/services/isar_service.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/data/datasources/aladhan_remote_datasource.dart';
import 'package:awan/features/prayer_engine/data/datasources/prayer_local_datasource.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Executes one verification pass of the offline angles against Aladhan and
/// persists the result.
///
/// Runs both from the UI isolate (the "verify now" button) and from the weekly
/// Workmanager isolate, so it only depends on the data layer — no Riverpod, no
/// `BuildContext`, no localisation.
Future<int?> verifyPrayerAnglesNow() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(AppConstants.prefsKeySettings);
  if (raw == null || raw.isEmpty) return null;

  final AppSettings settings = AppSettings.decode(raw);
  if (!settings.backgroundSyncEnabled && !_forcedFromUi) return null;

  final DateTime now = DateTime.now();
  IsarService? isar;
  try {
    isar = await IsarService.open();
    final PrayerLocalDatasource local =
        PrayerLocalDatasource(isar, const CalculatePrayerTimes());
    final AladhanRemoteDatasource remote =
        AladhanRemoteDatasource(ApiClient());

    final PrayerCalcSpec spec = PrayerCalcSpec(
      latitude: settings.latitude,
      longitude: settings.longitude,
      method: PrayerMethod.fromKey(settings.calcMethod),
      madhab: AsrMadhab.fromKey(settings.madhab),
      highLatitude: HighLatitude.fromKey(settings.highLatitudeRule),
      adjustments: settings.adjustments,
    );

    final DayPrayerTimes day =
        await local.cached(now, spec) ?? local.compute(now, spec);
    await local.store(day);

    final int diff = await remote.mismatchMinutes(
      date: day.date,
      local: day.times,
      latitude: spec.latitude,
      longitude: spec.longitude,
      method: spec.method,
      madhab: spec.madhab.key,
    );
    await local.store(day, verifiedDiffMinutes: diff);

    await prefs.setString(
      AppConstants.prefsKeySettings,
      settings
          .copyWith(lastVerifiedAt: now, lastVerifiedDiffMinutes: diff)
          .encode(),
    );
    return diff;
  } catch (_) {
    return null;
  } finally {
    await isar?.close();
  }
}

/// Set by the settings screen so a user-initiated verification runs even when
/// the weekly background task is switched off.
bool _forcedFromUi = false;

/// Runs the verification ignoring the `backgroundSyncEnabled` flag.
Future<int?> verifyPrayerAnglesNowForced() async {
  _forcedFromUi = true;
  try {
    return await verifyPrayerAnglesNow();
  } finally {
    _forcedFromUi = false;
  }
}

/// The Workmanager body: headless, single-shot, then exits.
///
/// `@pragma('vm:entry-point')` is essential — without it R8 strips the function
/// and the OS wakes an isolate that cannot find its entry point.
@pragma('vm:entry-point')
void prayerSyncDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? input) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != AppConstants.weeklySyncTask) return true;
    try {
      final int? diff = await verifyPrayerAnglesNow();
      // false lets Workmanager retry with its own exponential backoff.
      return diff != null;
    } catch (_) {
      return false;
    }
  });
}

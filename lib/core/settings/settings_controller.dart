import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_clock/domain/entities/clock_face.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/core/utils/clock_shift.dart';

/// Single source of truth for user configuration.
///
/// Every mutation writes through to [SharedPreferences] immediately, so a
/// process death never loses an adhan toggle or an elderly-mode switch.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _read(SharedPreferences prefs) {
    final String? raw = prefs.getString(AppConstants.prefsKeySettings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    return AppSettings.decode(raw);
  }

  Future<void> _commit(AppSettings next) async {
    state = next;
    await _prefs.setString(AppConstants.prefsKeySettings, next.encode());
  }

  Future<void> mutate(AppSettings Function(AppSettings current) change) =>
      _commit(change(state));

  // ------------------------------------------------------------- interface
  Future<void> setLocale(String code) =>
      _commit(state.copyWith(localeCode: code));

  Future<void> toggleLocale() =>
      setLocale(state.localeCode == 'ar' ? 'en' : 'ar');

  Future<void> setThemeMode(String mode) =>
      _commit(state.copyWith(themeMode: mode));

  Future<void> setElderlyMode(bool value) => _commit(
        state.copyWith(elderlyMode: value, textScale: value ? 1.5 : 1.0),
      );

  Future<void> setTextScale(double scale) =>
      _commit(state.copyWith(textScale: scale.clamp(0.85, 1.6)));

  Future<void> setHijriOffset(int days) =>
      _commit(state.copyWith(hijriOffsetDays: days.clamp(-3, 3)));

  /// Summer/winter time. An unrecognised value resets to automatic — a corrupted
  /// preference must never shift a prayer time silently.
  Future<void> setDstMode(String mode) => _commit(
        state.copyWith(dstMode: isKnownDstMode(mode) ? mode : kDstModeAuto),
      );

  // -------------------------------------------------------------- location
  Future<void> setLocation({
    required double latitude,
    required double longitude,
    required String cityAr,
    required String cityEn,
    required String mode,
  }) =>
      _commit(state.copyWith(
        latitude: latitude,
        longitude: longitude,
        cityAr: cityAr,
        cityEn: cityEn,
        locationMode: mode,
      ));

  // --------------------------------------------------------- prayer engine
  Future<void> setCalculationMethod(String key) =>
      _commit(state.copyWith(calcMethod: key));

  Future<void> setMadhab(String key) => _commit(state.copyWith(madhab: key));

  Future<void> setHighLatitudeRule(String key) =>
      _commit(state.copyWith(highLatitudeRule: key));

  Future<void> setAdjustment(String prayerKey, int minutes) {
    final Map<String, int> next = Map<String, int>.of(state.adjustments);
    if (minutes == 0) {
      next.remove(prayerKey);
    } else {
      next[prayerKey] = minutes.clamp(-60, 60);
    }
    return _commit(state.copyWith(adjustments: next));
  }

  Future<void> setVerificationResult({
    required DateTime at,
    required int diffMinutes,
  }) =>
      _commit(state.copyWith(
        lastVerifiedAt: at,
        lastVerifiedDiffMinutes: diffMinutes,
      ));

  // -------------------------------------------------------- notifications
  Future<void> setNotificationsEnabled(bool value) =>
      _commit(state.copyWith(notificationsEnabled: value));

  Future<void> togglePrayerNotification(String prayerKey, bool value) {
    final Map<String, bool> next = Map<String, bool>.of(state.enabledPrayers);
    next[prayerKey] = value;
    return _commit(state.copyWith(enabledPrayers: next));
  }

  Future<void> setPreAdhanMinutes(int minutes) =>
      _commit(state.copyWith(preAdhanMinutes: minutes.clamp(0, 60)));

  /// Enabling the hourglass also plants a sane lead time when none was chosen:
  /// an enabled reminder with a 0-minute lead would fire at the adhan itself.
  Future<void> setPreAdhanEnabled(bool value) => _commit(state.copyWith(
        preAdhanEnabled: value,
        preAdhanMinutes: value && state.preAdhanMinutes <= 0
            ? AppConstants.defaultPreAdhanMinutes
            : state.preAdhanMinutes,
      ));

  /// The clip the reminder before the adhan plays.
  Future<void> setPreAdhanSound(AdhanSound value) =>
      _commit(state.copyWith(preAdhanSound: value));

  Future<void> setLibraryReaderFontSize(double value) => _commit(
        state.copyWith(
          libraryReaderFontSize: value.clamp(12, 34).toDouble(),
        ),
      );

  Future<void> setLibraryReaderNight(bool value) =>
      _commit(state.copyWith(libraryReaderNight: value));

  Future<void> setQuranShowMutashabihat(bool value) =>
      _commit(state.copyWith(quranShowMutashabihat: value));

  /// Points the library at a different static host (a mirror, or a local one
  /// while the CDN is being filled).
  Future<void> setLibraryCdnBaseUrl(String value) =>
      _commit(state.copyWith(libraryCdnBaseUrl: value.trim()));

  /// The clip the adhan itself plays.
  Future<void> setAdhanSound(AdhanSound value) =>
      _commit(state.copyWith(adhanSound: value));

  Future<void> setNotificationVibration(bool value) =>
      _commit(state.copyWith(notificationVibration: value));

  /// Jumu'ah silence: minutes from the Jumu'ah adhan, zero to leave the phone
  /// alone. The caller re-plans the windows afterwards.
  Future<void> setJumuahSilentMinutes(int minutes) => _commit(
        state.copyWith(jumuahSilentMinutes: minutes.clamp(0, 180)),
      );

  Future<void> setPrayerClockFace(ClockFace face) =>
      _commit(state.copyWith(prayerClockFace: face.wire));

  Future<void> setPrayerClockNight(bool value) =>
      _commit(state.copyWith(prayerClockNight: value));

  /// Keeps (or drops) the all-day lock-screen card. Changing it only matters on
  /// the next re-plan, which the caller triggers — the card is posted, not
  /// scheduled.
  Future<void> setLockScreenAllDay(bool value) =>
      _commit(state.copyWith(lockScreenAllDay: value));

  // -------------------------------------------------------------- silence
  Future<void> setSilentMode(bool value) =>
      _commit(state.copyWith(silentModeEnabled: value));

  /// How one adhan announces itself. Re-arming the schedule is the caller's job
  /// (the prayer repository already does it after this), because the preference
  /// and the schedule are two different things.
  Future<void> setAdhanAlertMode(String prayerId, AdhanAlertMode mode) =>
      _commit(
        state.copyWith(
          adhanPreferences:
              state.adhanPreferences.withAlertMode(prayerId, mode),
        ),
      );

  /// When the ringer goes quiet around one adhan, and for how long.
  Future<void> setAdhanSilentWindow(
    String prayerId, {
    int? startMinutes,
    int? minutes,
  }) =>
      _commit(
        state.copyWith(
          adhanPreferences: state.adhanPreferences.withSilentWindow(
            prayerId,
            startMinutes: startMinutes,
            minutes: minutes,
          ),
        ),
      );

  Future<void> setMuteWindow({int? before, int? after}) => _commit(
        state.copyWith(
          muteBeforeMinutes: (before ?? state.muteBeforeMinutes).clamp(0, 60),
          unmuteAfterMinutes:
              (after ?? state.unmuteAfterMinutes).clamp(5, 180),
        ),
      );

  Future<void> setFridayMode(bool value) =>
      _commit(state.copyWith(fridayModeEnabled: value));

  Future<void> setFridayWindow({String? start, String? end}) => _commit(
        state.copyWith(
          fridayStart: start ?? state.fridayStart,
          fridayEnd: end ?? state.fridayEnd,
        ),
      );

  // ---------------------------------------------------------------- sync
  Future<void> setBackgroundSync(bool value) =>
      _commit(state.copyWith(backgroundSyncEnabled: value));

  // --------------------------------------------------------------- quran
  Future<void> setQuranFontScale(double scale) =>
      _commit(state.copyWith(quranFontScale: scale.clamp(20.0, 60.0)));

  Future<void> setQuranFont(String key) =>
      _commit(state.copyWith(quranFontKey: key));

  Future<void> setQuranTafsirSize(double size) =>
      _commit(state.copyWith(quranTafsirScale: size.clamp(13.0, 30.0)));

  /// Reading surface (`paper` | `sepia` | `dark` | `oled`), kept in step with the
  /// legacy [setNightReadingMode] flag so older call sites stay truthful.
  Future<void> setQuranPalette(String palette) => _commit(
        state.copyWith(
          quranPalette: palette,
          nightReadingMode: palette == 'dark' || palette == 'oled',
        ),
      );

  Future<void> setNightReadingMode(bool value) =>
      _commit(state.copyWith(nightReadingMode: value));

  Future<void> setLastRead(int surah, int ayah) => _commit(
        state.copyWith(lastReadSurah: surah, lastReadAyah: ayah),
      );

  Future<void> setActiveTafsir(int id) =>
      _commit(state.copyWith(activeTafsirId: id));

  // ---------------------------------------------------------------- misc
  Future<void> setTasbih({int? target, int? count, int? rounds}) => _commit(
        state.copyWith(
          tasbihTarget: target ?? state.tasbihTarget,
          tasbihCount: count ?? state.tasbihCount,
          tasbihRounds: rounds ?? state.tasbihRounds,
        ),
      );

  Future<void> setLibrarySource(String source) =>
      _commit(state.copyWith(librarySource: source));

  Future<void> setOnboardingSeen(bool value) =>
      _commit(state.copyWith(onboardingSeen: value));

  Future<void> resetAll() => _commit(const AppSettings());
}

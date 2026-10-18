import 'dart:convert';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/core/settings/adhan_preferences.dart';
import 'package:awan/core/utils/clock_shift.dart';

/// Immutable snapshot of everything the user can configure.
///
/// Persisted as a single JSON blob in [SharedPreferences] so start-up stays
/// instant (no database open on the critical path) — the religious *content*
/// lives in Isar instead.
class AppSettings {
  const AppSettings({
    this.localeCode = 'ar',
    this.themeMode = 'system',
    this.elderlyMode = false,
    this.textScale = 1.0,
    this.hijriOffsetDays = 0,
    this.dstMode = kDstModeAuto,
    this.locationMode = 'auto',
    this.latitude = 30.0444,
    this.longitude = 31.2357,
    this.cityAr = 'القاهرة',
    this.cityEn = 'Cairo',
    this.calcMethod = 'egyptian',
    this.madhab = 'shafi',
    this.highLatitudeRule = 'middleOfTheNight',
    this.adjustments = const <String, int>{},
    this.notificationsEnabled = true,
    this.enabledPrayers = const <String, bool>{
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    },
    this.preAdhanMinutes = 20,
    this.preAdhanEnabled = false,
    this.libraryCdnBaseUrl = AppConstants.libraryCdnDefaultUrl,
    this.libraryReaderFontSize = 19,
    this.libraryReaderNight = false,
    this.quranShowMutashabihat = false,
    this.preAdhanSound = AdhanSound.silent,
    this.adhanSound = AdhanSound.system,
    this.notificationVibration = true,
    this.lockScreenAllDay = true,
    this.prayerClockFace = 'segment',
    this.prayerClockNight = true,
    this.silentModeEnabled = false,
    this.adhanPreferences = const AdhanPreferences(),
    this.muteBeforeMinutes = 5,
    this.unmuteAfterMinutes = 30,
    this.fridayModeEnabled = true,
    this.fridayStart = '11:30',
    this.fridayEnd = '13:30',
    this.jumuahSilentMinutes = 0,
    this.smartCalendarEnabled = false,
    this.smartBlockDays = 14,
    this.smartBlockMinutes = 20,
    this.smartWorkStart = '09:00',
    this.smartWorkEnd = '17:00',
    this.smartSilentRadius = 60,
    this.smartDndEnabled = false,
    this.backgroundSyncEnabled = true,
    this.lastVerifiedAt,
    this.lastVerifiedDiffMinutes,
    this.quranFontScale = 30,
    this.quranFontKey = 'amiri',
    this.nightReadingMode = false,
    this.quranPalette = 'paper',
    this.quranTafsirScale = 18,
    this.lastReadSurah = 1,
    this.lastReadAyah = 1,
    this.tasbihTarget = 33,
    this.tasbihCount = 0,
    this.tasbihRounds = 0,
    this.activeTafsirId = 16,
    this.librarySource = 'shamela',
    this.onboardingSeen = false,
  });

  // ------------------------------------------------------------- interface
  final String localeCode; // 'ar' | 'en'
  final String themeMode; // 'system' | 'light' | 'dark'
  final bool elderlyMode;

  /// Free-form scale (1.0 default, elderly mode forces at least 1.5).
  final double textScale;
  final int hijriOffsetDays;

  /// Summer/winter-time handling: `auto` (trust the device), `plus1`, or
  /// `minus1`. Applied to everything shown *and* to the adhan alarms — see
  /// `core/utils/clock_shift.dart` for why both move together.
  final String dstMode;

  // -------------------------------------------------------------- location
  final String locationMode; // 'auto' | 'manual'
  final double latitude;
  final double longitude;
  final String cityAr;
  final String cityEn;

  /// True when the coordinates are still the built-in default because no fix
  /// has ever been taken — automatic mode that has not answered yet.
  ///
  /// Screens that *claim* to show what is around the reader must not treat
  /// Cairo as if the reader were in Cairo: that is how a phone in Alexandria
  /// shows Al-Azhar and calls it "nearby".
  bool get locationIsDefault =>
      locationMode == 'auto' &&
      (latitude - AppConstants.defaultLatitude).abs() < 1e-6 &&
      (longitude - AppConstants.defaultLongitude).abs() < 1e-6;

  // ------------------------------------------------------- prayer engine
  final String calcMethod;
  final String madhab; // 'shafi' | 'hanafi'
  final String highLatitudeRule;
  final Map<String, int> adjustments; // prayerKey -> minutes

  // ------------------------------------------------------- notifications
  final bool notificationsEnabled;
  final Map<String, bool> enabledPrayers;
  /// Lead time of the pre-prayer hourglass, in minutes.
  final int preAdhanMinutes;

  /// Base URL of the static book CDN (see [AppConstants.libraryCdnDefaultUrl]).
  final String libraryCdnBaseUrl;

  /// Reader text size and night paper, kept with the other reading preferences so
  /// a book opens the way it was left.
  final double libraryReaderFontSize;
  final bool libraryReaderNight;

  /// Tints the verses that carry a similarity relation while reading, so the
  /// reader can see where the Mutashabihat graph has something to say.
  final bool quranShowMutashabihat;

  /// The hourglass itself — opt-in, and the same switch drives the system
  /// notification and the floating card inside the app.
  final bool preAdhanEnabled;

  /// What the reminder before the adhan plays. Silent by default: it is meant to
  /// be gentle, and a reminder that calls without being asked for is not gentle.
  final AdhanSound preAdhanSound;

  /// What the adhan itself plays.
  final AdhanSound adhanSound;
  final bool notificationVibration;

  /// Keeps the next prayer — name, clock and a live countdown — on the lock
  /// screen the whole day, not only in the twenty minutes before an adhan. The
  /// card is silent and cannot be swiped away; it is replaced, not stacked.
  final bool lockScreenAllDay;

  // ------------------------------------------------------------ prayer clock
  /// The clock face's wire name — see `ClockFace.fromWire`.
  final String prayerClockFace;

  /// Digits and page in the night palette. The lock screen is dark; a wall clock
  /// in a lit room is not.
  final bool prayerClockNight;

  // -------------------------------------------------------- silent / DND
  final bool silentModeEnabled;

  /// Per-adhan alert mode and silence window — see [AdhanPreferences].
  final AdhanPreferences adhanPreferences;
  final int muteBeforeMinutes;
  final int unmuteAfterMinutes;
  final bool fridayModeEnabled;
  final String fridayStart;
  final String fridayEnd;

  /// Minutes of silence that begin at the Jumu'ah adhan. Zero keeps the phone
  /// as it is: the window is a choice, not a default.
  final int jumuahSilentMinutes;

  // -------------------------------------------------- smart calendar + DND
  /// Whether prayer blocks are written into the phone's calendar at all.
  final bool smartCalendarEnabled;

  /// How far ahead the rolling window writes: 14 by default, 30 at most.
  final int smartBlockDays;

  /// Length of each block, in minutes from the adhan.
  final int smartBlockMinutes;

  /// Working hours, as `HH:mm`. Prayer blocks outside them are not written.
  final String smartWorkStart;
  final String smartWorkEnd;

  /// How close to a mosque counts as "inside" it, in metres.
  final int smartSilentRadius;

  /// Whether the context engine is allowed to silence the phone by itself.
  final bool smartDndEnabled;

  // ------------------------------------------------------- background sync
  final bool backgroundSyncEnabled;
  final DateTime? lastVerifiedAt;
  final int? lastVerifiedDiffMinutes;

  // ------------------------------------------------------------- quran
  final double quranFontScale;
  final String quranFontKey;
  final bool nightReadingMode;

  /// Reading surface: `paper` | `sepia` | `dark` | `oled`.
  ///
  /// Separate from the app theme on purpose: the screen a person reads Qur'an on for
  /// twenty minutes is not the same choice as the dashboard's theme.
  final String quranPalette;

  /// Tafsir text size, independent of the verse size: a reader who needs big
  /// letters for the Mushaf may still want the commentary dense, or the reverse.
  final double quranTafsirScale;
  final int lastReadSurah;
  final int lastReadAyah;

  // ------------------------------------------------------------- misc
  final int tasbihTarget;
  final int tasbihCount;
  final int tasbihRounds;
  final int activeTafsirId;
  final String librarySource;
  final bool onboardingSeen;

  bool get isArabic => localeCode == 'ar';
  bool get isElderly => elderlyMode;

  /// The scale actually applied to the whole app.
  double get effectiveTextScale =>
      elderlyMode ? (textScale < 1.5 ? 1.5 : textScale) : textScale;

  int adjustmentFor(String prayerKey) => adjustments[prayerKey] ?? 0;
  /// Whether an adhan notification should be delivered at each prayer time.
  ///
  /// Steps 5's names, kept as the canonical ones the UI reads; the persisted keys
  /// stay `notificationsEnabled` / `silentModeEnabled` so existing installs need
  /// no migration.
  bool get isAdhanEnabled => notificationsEnabled;

  /// Whether the phone should be muted automatically around prayer times.
  bool get isAutoSilentEnabled => silentModeEnabled;

  bool isPrayerEnabled(String prayerKey) => enabledPrayers[prayerKey] ?? true;

  AppSettings copyWith({
    String? localeCode,
    String? themeMode,
    bool? elderlyMode,
    double? textScale,
    int? hijriOffsetDays,
    String? dstMode,
    String? locationMode,
    double? latitude,
    double? longitude,
    String? cityAr,
    String? cityEn,
    String? calcMethod,
    String? madhab,
    String? highLatitudeRule,
    Map<String, int>? adjustments,
    bool? notificationsEnabled,
    Map<String, bool>? enabledPrayers,
    int? preAdhanMinutes,
    bool? preAdhanEnabled,
    AdhanSound? preAdhanSound,
    String? libraryCdnBaseUrl,
    double? libraryReaderFontSize,
    bool? libraryReaderNight,
    bool? quranShowMutashabihat,
    AdhanSound? adhanSound,
    bool? notificationVibration,
    bool? lockScreenAllDay,
    String? prayerClockFace,
    bool? prayerClockNight,
    bool? silentModeEnabled,
    AdhanPreferences? adhanPreferences,
    int? muteBeforeMinutes,
    int? unmuteAfterMinutes,
    bool? fridayModeEnabled,
    String? fridayStart,
    String? fridayEnd,
    int? jumuahSilentMinutes,
    bool? smartCalendarEnabled,
    int? smartBlockDays,
    int? smartBlockMinutes,
    String? smartWorkStart,
    String? smartWorkEnd,
    int? smartSilentRadius,
    bool? smartDndEnabled,
    bool? backgroundSyncEnabled,
    DateTime? lastVerifiedAt,
    int? lastVerifiedDiffMinutes,
    double? quranFontScale,
    String? quranFontKey,
    bool? nightReadingMode,
    String? quranPalette,
    double? quranTafsirScale,
    int? lastReadSurah,
    int? lastReadAyah,
    int? tasbihTarget,
    int? tasbihCount,
    int? tasbihRounds,
    int? activeTafsirId,
    String? librarySource,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      elderlyMode: elderlyMode ?? this.elderlyMode,
      textScale: textScale ?? this.textScale,
      hijriOffsetDays: hijriOffsetDays ?? this.hijriOffsetDays,
      dstMode: dstMode ?? this.dstMode,
      locationMode: locationMode ?? this.locationMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityAr: cityAr ?? this.cityAr,
      cityEn: cityEn ?? this.cityEn,
      calcMethod: calcMethod ?? this.calcMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? this.adjustments,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      preAdhanMinutes: preAdhanMinutes ?? this.preAdhanMinutes,
      preAdhanEnabled: preAdhanEnabled ?? this.preAdhanEnabled,
      preAdhanSound: preAdhanSound ?? this.preAdhanSound,
      libraryCdnBaseUrl: libraryCdnBaseUrl ?? this.libraryCdnBaseUrl,
      libraryReaderFontSize:
          libraryReaderFontSize ?? this.libraryReaderFontSize,
      libraryReaderNight: libraryReaderNight ?? this.libraryReaderNight,
      quranShowMutashabihat:
          quranShowMutashabihat ?? this.quranShowMutashabihat,
      adhanSound: adhanSound ?? this.adhanSound,
      notificationVibration:
          notificationVibration ?? this.notificationVibration,
      lockScreenAllDay: lockScreenAllDay ?? this.lockScreenAllDay,
      prayerClockFace: prayerClockFace ?? this.prayerClockFace,
      prayerClockNight: prayerClockNight ?? this.prayerClockNight,
      silentModeEnabled: silentModeEnabled ?? this.silentModeEnabled,
      adhanPreferences: adhanPreferences ?? this.adhanPreferences,
      muteBeforeMinutes: muteBeforeMinutes ?? this.muteBeforeMinutes,
      unmuteAfterMinutes: unmuteAfterMinutes ?? this.unmuteAfterMinutes,
      fridayModeEnabled: fridayModeEnabled ?? this.fridayModeEnabled,
      fridayStart: fridayStart ?? this.fridayStart,
      fridayEnd: fridayEnd ?? this.fridayEnd,
      jumuahSilentMinutes: jumuahSilentMinutes ?? this.jumuahSilentMinutes,
      smartCalendarEnabled: smartCalendarEnabled ?? this.smartCalendarEnabled,
      smartBlockDays: smartBlockDays ?? this.smartBlockDays,
      smartBlockMinutes: smartBlockMinutes ?? this.smartBlockMinutes,
      smartWorkStart: smartWorkStart ?? this.smartWorkStart,
      smartWorkEnd: smartWorkEnd ?? this.smartWorkEnd,
      smartSilentRadius: smartSilentRadius ?? this.smartSilentRadius,
      smartDndEnabled: smartDndEnabled ?? this.smartDndEnabled,
      backgroundSyncEnabled: backgroundSyncEnabled ?? this.backgroundSyncEnabled,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      lastVerifiedDiffMinutes:
          lastVerifiedDiffMinutes ?? this.lastVerifiedDiffMinutes,
      quranFontScale: quranFontScale ?? this.quranFontScale,
      quranFontKey: quranFontKey ?? this.quranFontKey,
      nightReadingMode: nightReadingMode ?? this.nightReadingMode,
      quranPalette: quranPalette ?? this.quranPalette,
      quranTafsirScale: quranTafsirScale ?? this.quranTafsirScale,
      lastReadSurah: lastReadSurah ?? this.lastReadSurah,
      lastReadAyah: lastReadAyah ?? this.lastReadAyah,
      tasbihTarget: tasbihTarget ?? this.tasbihTarget,
      tasbihCount: tasbihCount ?? this.tasbihCount,
      tasbihRounds: tasbihRounds ?? this.tasbihRounds,
      activeTafsirId: activeTafsirId ?? this.activeTafsirId,
      librarySource: librarySource ?? this.librarySource,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'localeCode': localeCode,
        'themeMode': themeMode,
        'elderlyMode': elderlyMode,
        'textScale': textScale,
        'hijriOffsetDays': hijriOffsetDays,
        'dstMode': dstMode,
        'locationMode': locationMode,
        'latitude': latitude,
        'longitude': longitude,
        'cityAr': cityAr,
        'cityEn': cityEn,
        'calcMethod': calcMethod,
        'madhab': madhab,
        'highLatitudeRule': highLatitudeRule,
        'adjustments': adjustments,
        'notificationsEnabled': notificationsEnabled,
        'enabledPrayers': enabledPrayers,
        'preAdhanMinutes': preAdhanMinutes,
        'preAdhanEnabled': preAdhanEnabled,
        'preAdhanSoundKey': preAdhanSound.wire,
        'libraryCdnBaseUrl': libraryCdnBaseUrl,
        'libraryReaderFontSize': libraryReaderFontSize,
        'libraryReaderNight': libraryReaderNight,
        'quranShowMutashabihat': quranShowMutashabihat,
        'adhanSoundKey': adhanSound.wire,
        'notificationVibration': notificationVibration,
        'lockScreenAllDay': lockScreenAllDay,
        'prayerClockFace': prayerClockFace,
        'prayerClockNight': prayerClockNight,
        'silentModeEnabled': silentModeEnabled,
        'adhanPreferences': adhanPreferences.encode(),
        'muteBeforeMinutes': muteBeforeMinutes,
        'unmuteAfterMinutes': unmuteAfterMinutes,
        'fridayModeEnabled': fridayModeEnabled,
        'fridayStart': fridayStart,
        'fridayEnd': fridayEnd,
        'jumuahSilentMinutes': jumuahSilentMinutes,
        'smartCalendarEnabled': smartCalendarEnabled,
        'smartBlockDays': smartBlockDays,
        'smartBlockMinutes': smartBlockMinutes,
        'smartWorkStart': smartWorkStart,
        'smartWorkEnd': smartWorkEnd,
        'smartSilentRadius': smartSilentRadius,
        'smartDndEnabled': smartDndEnabled,
        'backgroundSyncEnabled': backgroundSyncEnabled,
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
        'lastVerifiedDiffMinutes': lastVerifiedDiffMinutes,
        'quranFontScale': quranFontScale,
        'quranFontKey': quranFontKey,
        'nightReadingMode': nightReadingMode,
        'quranPalette': quranPalette,
        'quranTafsirScale': quranTafsirScale,
        'lastReadSurah': lastReadSurah,
        'lastReadAyah': lastReadAyah,
        'tasbihTarget': tasbihTarget,
        'tasbihCount': tasbihCount,
        'tasbihRounds': tasbihRounds,
        'activeTafsirId': activeTafsirId,
        'librarySource': librarySource,
        'onboardingSeen': onboardingSeen,
      };

  static AppSettings fromJson(Map<String, dynamic> json) {
    const AppSettings defaults = AppSettings();
    T pick<T>(String key, T fallback) {
      final Object? value = json[key];
      return value is T ? value : fallback;
    }

    Map<String, int> adjustments() {
      final Object? raw = json['adjustments'];
      if (raw is Map) {
        return raw.map(
          (Object? k, Object? v) => MapEntry<String, int>(
            '$k',
            v is int ? v : int.tryParse('$v') ?? 0,
          ),
        );
      }
      return defaults.adjustments;
    }

    Map<String, bool> prayers() {
      final Object? raw = json['enabledPrayers'];
      if (raw is Map) {
        return raw.map(
          (Object? k, Object? v) => MapEntry<String, bool>('$k', v == true),
        );
      }
      return defaults.enabledPrayers;
    }

    // The chosen clips. Absent on an install that predates them, in which case the
    // two old booleans are read below as "the phone's tone" or "silence".
    final Object? adhanWire = json['adhanSoundKey'];
    final Object? preAdhanWire = json['preAdhanSoundKey'];

    return AppSettings(
      localeCode: pick<String>('localeCode', defaults.localeCode),
      themeMode: pick<String>('themeMode', defaults.themeMode),
      elderlyMode: pick<bool>('elderlyMode', defaults.elderlyMode),
      textScale: (json['textScale'] as num?)?.toDouble() ?? defaults.textScale,
      hijriOffsetDays: pick<int>('hijriOffsetDays', defaults.hijriOffsetDays),
      dstMode: pick<String>('dstMode', defaults.dstMode),
      locationMode: pick<String>('locationMode', defaults.locationMode),
      latitude: (json['latitude'] as num?)?.toDouble() ?? defaults.latitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? defaults.longitude,
      cityAr: pick<String>('cityAr', defaults.cityAr),
      cityEn: pick<String>('cityEn', defaults.cityEn),
      calcMethod: pick<String>('calcMethod', defaults.calcMethod),
      madhab: pick<String>('madhab', defaults.madhab),
      highLatitudeRule:
          pick<String>('highLatitudeRule', defaults.highLatitudeRule),
      adjustments: adjustments(),
      notificationsEnabled:
          pick<bool>('notificationsEnabled', defaults.notificationsEnabled),
      enabledPrayers: prayers(),
      preAdhanMinutes: pick<int>('preAdhanMinutes', defaults.preAdhanMinutes),
      preAdhanEnabled: pick<bool>('preAdhanEnabled', defaults.preAdhanEnabled),
      // The reader's clip, with the two older on/off switches read once as a
      // migration: on meant "the phone's own tone", off meant silence.
      preAdhanSound: preAdhanWire is String
          ? AdhanSound.fromWire(preAdhanWire)
          : (pick<bool>('preAdhanSound', false)
              ? AdhanSound.system
              : AdhanSound.silent),
      libraryCdnBaseUrl: pick<String>(
        'libraryCdnBaseUrl',
        defaults.libraryCdnBaseUrl,
      ),
      libraryReaderFontSize: pick<double>(
        'libraryReaderFontSize',
        defaults.libraryReaderFontSize,
      ),
      libraryReaderNight: pick<bool>(
        'libraryReaderNight',
        defaults.libraryReaderNight,
      ),
      quranShowMutashabihat: pick<bool>(
        'quranShowMutashabihat',
        defaults.quranShowMutashabihat,
      ),
      adhanSound: adhanWire is String
          ? AdhanSound.fromWire(adhanWire)
          : (pick<bool>('notificationSound', true)
              ? AdhanSound.system
              : AdhanSound.silent),
      notificationVibration:
          pick<bool>('notificationVibration', defaults.notificationVibration),
      lockScreenAllDay:
          pick<bool>('lockScreenAllDay', defaults.lockScreenAllDay),
      prayerClockFace: pick<String>(
        'prayerClockFace',
        defaults.prayerClockFace,
      ),
      prayerClockNight:
          pick<bool>('prayerClockNight', defaults.prayerClockNight),
      silentModeEnabled:
          pick<bool>('silentModeEnabled', defaults.silentModeEnabled),
      adhanPreferences: AdhanPreferences.decode(
        pick<String>(
          'adhanPreferences',
          defaults.adhanPreferences.encode(),
        ),
      ),
      muteBeforeMinutes:
          pick<int>('muteBeforeMinutes', defaults.muteBeforeMinutes),
      unmuteAfterMinutes:
          pick<int>('unmuteAfterMinutes', defaults.unmuteAfterMinutes),
      fridayModeEnabled:
          pick<bool>('fridayModeEnabled', defaults.fridayModeEnabled),
      fridayStart: pick<String>('fridayStart', defaults.fridayStart),
      fridayEnd: pick<String>('fridayEnd', defaults.fridayEnd),
      jumuahSilentMinutes:
          pick<int>('jumuahSilentMinutes', defaults.jumuahSilentMinutes),
      smartCalendarEnabled:
          pick<bool>('smartCalendarEnabled', defaults.smartCalendarEnabled),
      smartBlockDays: pick<int>('smartBlockDays', defaults.smartBlockDays),
      smartBlockMinutes:
          pick<int>('smartBlockMinutes', defaults.smartBlockMinutes),
      smartWorkStart:
          pick<String>('smartWorkStart', defaults.smartWorkStart),
      smartWorkEnd: pick<String>('smartWorkEnd', defaults.smartWorkEnd),
      smartSilentRadius:
          pick<int>('smartSilentRadius', defaults.smartSilentRadius),
      smartDndEnabled: pick<bool>('smartDndEnabled', defaults.smartDndEnabled),
      backgroundSyncEnabled:
          pick<bool>('backgroundSyncEnabled', defaults.backgroundSyncEnabled),
      lastVerifiedAt: json['lastVerifiedAt'] is String
          ? DateTime.tryParse(json['lastVerifiedAt'] as String)
          : null,
      lastVerifiedDiffMinutes: json['lastVerifiedDiffMinutes'] is int
          ? json['lastVerifiedDiffMinutes'] as int
          : null,
      quranFontScale:
          (json['quranFontScale'] as num?)?.toDouble() ??
              defaults.quranFontScale,
      quranFontKey: pick<String>('quranFontKey', defaults.quranFontKey),
      nightReadingMode:
          pick<bool>('nightReadingMode', defaults.nightReadingMode),
      lastReadSurah: pick<int>('lastReadSurah', defaults.lastReadSurah),
      lastReadAyah: pick<int>('lastReadAyah', defaults.lastReadAyah),
      tasbihTarget: pick<int>('tasbihTarget', defaults.tasbihTarget),
      tasbihCount: pick<int>('tasbihCount', defaults.tasbihCount),
      tasbihRounds: pick<int>('tasbihRounds', defaults.tasbihRounds),
      activeTafsirId: pick<int>('activeTafsirId', defaults.activeTafsirId),
      librarySource: pick<String>('librarySource', defaults.librarySource),
      onboardingSeen: pick<bool>('onboardingSeen', defaults.onboardingSeen),
    );
  }

  String encode() => jsonEncode(toJson());

  static AppSettings decode(String raw) {
    try {
      final Object? data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return AppSettings.fromJson(data);
    } catch (_) {
      // Corrupt payload: fall back to defaults instead of trapping the user.
    }
    return const AppSettings();
  }
}

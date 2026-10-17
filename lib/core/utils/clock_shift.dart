/// Manual daylight-saving correction — «التوقيت الصيفي / الشتوي».
///
/// The device's own timezone is the default authority: a phone that knows its zone
/// applies summer time by itself, and nothing here changes anything. But two real
/// situations need a switch:
///
/// * a device carrying **stale zone rules** for a country that changed its DST
///   policy (Egypt re-introduced DST in 2023 and many handsets still ship the
///   pre-2023 rule, so every prayer lands an hour off the clock the user reads);
/// * a user who deliberately keeps a **fixed offset** (travel, work, a device set
///   to "no automatic time").
///
/// The correction is a *clock* correction, never an astronomical one: it moves what
/// the app shows **and** the instant the adhan alarm fires by the same amount,
/// because both are built from this single value — so the screen and the alarm can
/// never disagree. The solar computation (a physical UTC instant) is left alone,
/// which is also what the weekly online verification compares.
library;

/// Automatic: trust the device's timezone (correct for almost everyone).
const String kDstModeAuto = 'auto';

/// Force one hour forward (summer time).
const String kDstModePlusOne = 'plus1';

/// Force one hour back (winter / standard time).
const String kDstModeMinusOne = 'minus1';

/// Every stored value, in the order the settings picker shows them.
const List<String> kDstModes = <String>[
  kDstModeAuto,
  kDstModePlusOne,
  kDstModeMinusOne,
];

/// Whether a stored value is one we know; unknown input means [kDstModeAuto].
bool isKnownDstMode(String mode) => kDstModes.contains(mode);

/// Minutes to move local times by.
///
/// `auto` and anything unrecognised resolve to 0 — a corrupt preference must never
/// silently shift a prayer time.
int resolveDstMinutes(String mode) {
  switch (mode) {
    case kDstModePlusOne:
      return 60;
    case kDstModeMinusOne:
      return -60;
    default:
      return 0;
  }
}

/// Whether the device's zone changes offset during the year — i.e. the zone has
/// daylight saving at all.
///
/// Dart exposes no `isDst`, so we compare the offset of the same calendar year in
/// January against July: a zone that shifts is a zone with DST. The comparison is
/// month-agnostic, so southern-hemisphere zones (DST over the new year) read the
/// same way. [now] exists so tests can pin the year instead of depending on today.
bool deviceObservesDst({DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final int january = DateTime(reference.year, 1, 15, 12).timeZoneOffset.inMinutes;
  final int july = DateTime(reference.year, 7, 15, 12).timeZoneOffset.inMinutes;
  return january != july;
}

/// Whether the device is currently in its **larger** offset — its summer time.
///
/// Only meaningful when [deviceObservesDst] is true; returns false for fixed zones.
bool deviceIsOnSummerTime({DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final int january = DateTime(reference.year, 1, 15, 12).timeZoneOffset.inMinutes;
  final int july = DateTime(reference.year, 7, 15, 12).timeZoneOffset.inMinutes;
  if (january == july) return false;
  final int summer = january > july ? january : july;
  return reference.timeZoneOffset.inMinutes >= summer;
}

/// The device's offset from UTC right now, in minutes (`180` for Cairo in summer).
int deviceUtcOffsetMinutes({DateTime? at}) =>
    (at ?? DateTime.now()).timeZoneOffset.inMinutes;

/// `UTC+03:00` / `UTC−02:30` — the offset as a person writes it.
String formatUtcOffset(int minutes) {
  final String sign = minutes < 0 ? '−' : '+';
  final int absolute = minutes.abs();
  final String hours = (absolute ~/ 60).toString().padLeft(2, '0');
  final String mins = (absolute % 60).toString().padLeft(2, '0');
  return mins == '00' ? 'UTC$sign$hours:00' : 'UTC$sign$hours:$mins';
}

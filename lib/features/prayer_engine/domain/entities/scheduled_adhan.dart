import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// One notification the operating system should deliver, described in the
/// domain's own terms.
///
/// The domain decides *what* and *when*; the platform layer (`NotificationService`
/// in `core/services`) decides *how*. That split is what lets
/// [ScheduleMonthlyPrayers] be tested without a single Android or iOS call.
class ScheduledAdhan {
  const ScheduledAdhan({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
    this.isReminder = false,
    this.playsSound = true,
    this.alertMode = AdhanAlertMode.tone,
    this.countdownTo,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;

  /// True for the "…in 15 minutes" reminder, which uses the quieter channel.
  final bool isReminder;

  /// Whether this one is allowed to make a sound. The adhan always does; the
  /// hourglass is a *gentle* reminder, so it is silent unless the reader asked
  /// for a soft chime — and Android freezes a channel's sound at creation, so an
  /// audible reminder needs its own channel (see `NotificationService`).
  final bool playsSound;

  /// How this adhan should announce itself — quiet, a buzz, or a buzz with the
  /// tone. Chosen per prayer in the settings, because Fajr at 4am and Asr at 4pm
  /// are not the same event in a household.
  ///
  /// Android bakes a channel's sound in at creation, so the three modes are three
  /// channels rather than a flag the platform would ignore.
  final AdhanAlertMode alertMode;

  /// For a pre-adhan reminder: the instant the system should count down to on the
  /// lock screen — the adhan itself, which is what the reader is waiting for.
  final DateTime? countdownTo;

  @override
  String toString() => 'ScheduledAdhan($id, $at, ${isReminder ? 'reminder' : 'adhan'})';
}

/// What an adhan is allowed to do when its time arrives.
enum AdhanAlertMode {
  /// A silent notification: it is on the screen and the lock screen, and says
  /// nothing.
  quiet(0),

  /// The notification plus a buzz.
  vibrate(1),

  /// The notification, a buzz, and the alert tone.
  tone(2);

  const AdhanAlertMode(this.wireValue);

  /// The number stored in the settings, so a saved preference survives.
  final int wireValue;

  static AdhanAlertMode fromWire(int? value) => AdhanAlertMode.values.firstWhere(
        (AdhanAlertMode mode) => mode.wireValue == value,
        orElse: () => AdhanAlertMode.tone,
      );

}

/// Deterministic notification ids, so a reschedule can cancel exactly what the
/// previous run created (day offset and prayer index are both bounded).
class NotificationIds {
  const NotificationIds._();

  static const int _base = 100000;
  static const int _daySpan = 100;

  /// Adhan for prayer index [prayerIndex] on day offset [dayOffset].
  static int adhan(int prayerIndex, int dayOffset) =>
      _base + dayOffset * _daySpan + prayerIndex;

  /// Pre-adhan reminder for the same slot.
  static int preAdhan(int prayerIndex, int dayOffset) =>
      _base + 50000 + dayOffset * _daySpan + prayerIndex;

  /// Silence windows are OS alarms, a different id space entirely.
  static int silenceWindow(int index) => 900000 + index;

  /// One fixed slot for the all-day lock-screen card. A single id on purpose:
  /// each refresh *replaces* the card instead of leaving a pile of stale clocks
  /// on the lock screen. Id 1 is below [_base] and below the silence space, so it
  /// is never mistaken for an adhan when the pending set is swept.
  static const int lockScreenCard = 1;

  static const int maxAdhanId = _base + 50000 + _daySpan * 100;

  /// True for ids this app owns as adhan notifications.
  static bool isAdhanId(int id) => id >= _base && id < maxAdhanId;
}

/// Builds the localized title/body of one adhan (or pre-adhan reminder).
///
/// Passed *into* the use case rather than written inside it: the wording is a
/// presentation concern (it needs `AppLocalizations`), while the schedule is not.
typedef AdhanTextBuilder = ({String title, String body}) Function(
  PrayerName prayer,
  DateTime at,
);

/// Builds the wording of the all-day lock-screen card.
///
/// [rest] is the remainder of the same day after [next] — the card answers
/// «المتبقي على كل صلاة» by listing the day's clocks while the system's
/// chronometer counts down to [next].
typedef LockScreenCardTextBuilder = ({String title, String body}) Function(
  PrayerName next,
  DateTime at,
  List<({PrayerName prayer, DateTime at})> rest,
);

/// Builds the wording of the pre-prayer hourglass: «باقي ٢٠ دقيقة على العصر».
///
/// Separate from [AdhanTextBuilder] because the message is different in kind —
/// the adhan announces, this one warns — and because it needs the lead time,
/// which the planner is the only one that knows.
typedef AdhanReminderTextBuilder = ({String title, String body}) Function(
  PrayerName prayer,
  DateTime at,
  int minutes,
);


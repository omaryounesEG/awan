import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/network/network_info.dart';
import 'package:awan/core/services/audio_manager_service.dart';
import 'package:awan/core/services/notification_service.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/clock_shift.dart';
import 'package:awan/features/prayer_engine/data/datasources/aladhan_remote_datasource.dart';
import 'package:awan/features/prayer_engine/data/datasources/prayer_local_datasource.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_offline_prayer_times.dart';
import 'package:awan/features/prayer_engine/domain/usecases/next_prayer.dart';
import 'package:awan/features/prayer_engine/domain/usecases/schedule_monthly_prayers.dart';

/// Wording of the card in the twenty minutes *after* an adhan, when it counts
/// up instead of down.
typedef ElapsedCardTextBuilder = ({String title, String body}) Function(
  PrayerName prayer,
  DateTime at,
  Duration elapsed,
);

/// Builds the (localized) notification channel names.
typedef ChannelNameBuilder = ({
  String adhan,
  String adhanDescription,
  String reminder,
  String friday,
}) Function();

/// The hybrid prayer engine.
///
/// * displayed times  : always `adhan_dart`, offline (never dependent on a call)
/// * online verification: Aladhan, once a week or on demand
/// * side effects      : notifications and silence windows are queued with the
///   OS and then forgotten — no Dart code keeps running
class PrayerRepositoryImpl implements PrayerRepository, AdhanSchedulerPort {
  PrayerRepositoryImpl({
    required PrayerLocalDatasource local,
    required AladhanRemoteDatasource remote,
    required NetworkInfo network,
    required NotificationService notifications,
    required AudioManagerService silentMode,
    required AppSettings Function() settings,
    required AdhanTextBuilder adhanText,
    required ChannelNameBuilder channelNames,
    AdhanReminderTextBuilder? reminderText,
    LockScreenCardTextBuilder? cardText,
    ElapsedCardTextBuilder? elapsedText,
    GetOfflinePrayerTimes offline = const GetOfflinePrayerTimes(),
  })  : _local = local,
        _remote = remote,
        _network = network,
        _notifications = notifications,
        _silentMode = silentMode,
        _settings = settings,
        _adhanText = adhanText,
        _reminderText = reminderText,
        _cardText = cardText,
        _elapsedText = elapsedText,
        _channelNames = channelNames,
        _offline = offline;

  final PrayerLocalDatasource _local;
  final AladhanRemoteDatasource _remote;
  final NetworkInfo _network;
  final NotificationService _notifications;
  final AudioManagerService _silentMode;
  final AppSettings Function() _settings;
  final AdhanTextBuilder _adhanText;
  final AdhanReminderTextBuilder? _reminderText;

  /// Wording of the all-day lock-screen card, built from the same prayer label
  /// the adhan uses so the two can never drift apart.
  final LockScreenCardTextBuilder? _cardText;

  /// How long after an adhan the card keeps counting up. Twenty minutes: the
  /// jama'ah in the mosque has started by then, so a number of minutes since
  /// the adhan has stopped being useful.
  static const Duration elapsedWindow = Duration(minutes: 20);

  final ElapsedCardTextBuilder? _elapsedText;
  final ChannelNameBuilder _channelNames;
  final GetOfflinePrayerTimes _offline;

  PrayerCalcSpec get spec {
    final AppSettings s = _settings();
    return PrayerCalcSpec(
      latitude: s.latitude,
      longitude: s.longitude,
      method: PrayerMethod.fromKey(s.calcMethod),
      madhab: AsrMadhab.fromKey(s.madhab),
      highLatitude: HighLatitude.fromKey(s.highLatitudeRule),
      adjustments: s.adjustments,
    );
  }

  @override
  Future<DayPrayerTimes> day(DateTime date, {bool forceRecompute = false}) async {
    final PrayerCalcSpec current = spec;
    final DateTime day = DateTime(date.year, date.month, date.day);

    if (!forceRecompute) {
      final DayPrayerTimes? hit = await _local.cached(day, current);
      if (hit != null) return hit;
    }

    final DayPrayerTimes computed = _local.compute(day, current);
    await _local.store(computed);
    return computed;
  }

  @override
  Future<List<DayPrayerTimes>> month(int year, int month) async {
    final PrayerCalcSpec current = spec;
    final Map<String, DayPrayerTimes> cached =
        await _local.cachedMonth(year, month, current);

    final List<DayPrayerTimes> result = <DayPrayerTimes>[];
    final List<DayPrayerTimes> missing = <DayPrayerTimes>[];
    final int days = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= days; d++) {
      final DateTime date = DateTime(year, month, d);
      final DayPrayerTimes? hit =
          cached['${DayPrayerTimes.dayKey(date)}|${current.cacheKeyPart}'];
      if (hit != null) {
        result.add(hit);
      } else {
        final DayPrayerTimes computed = _local.compute(date, current);
        missing.add(computed);
        result.add(computed);
      }
    }
    if (missing.isNotEmpty) await _local.storeAll(missing);
    return result;
  }

  @override
  Future<NextPrayer?> next(DateTime now) async {
    final DayPrayerTimes today = await day(now);
    final NextPrayer? pending = today.next(now);
    if (pending != null) return pending;

    // Next calendar day, not "+24h": across a DST change that instant is 23:00 of
    // the same date and the "tomorrow" fajr would be today's.
    final DayPrayerTimes tomorrow =
        await day(DateTime(now.year, now.month, now.day + 1));
    return NextPrayer(
      name: PrayerName.fajr,
      at: tomorrow.timeOf(PrayerName.fajr),
      previous: PrayerName.isha,
    );
  }

  @override
  Future<Either<Failure, PrayerTimesEntity>> getDailyPrayers(
    double lat,
    double lng,
    DateTime date,
  ) async {
    final AppSettings s = _settings();
    final Either<Failure, PrayerTimesEntity> outcome = await _offline(
      OfflinePrayerParams(
        latitude: lat,
        longitude: lng,
        date: date,
        method: PrayerMethod.fromKey(s.calcMethod),
        madhab: AsrMadhab.fromKey(s.madhab),
        highLatitude: HighLatitude.fromKey(s.highLatitudeRule),
        adjustments: s.adjustments,
      ),
    );

    final PrayerTimesEntity? entity = outcome.fold(
      (Failure _) => null,
      (PrayerTimesEntity value) => value,
    );
    if (entity == null) {
      // Pass the original typed failure straight through.
      return outcome.fold(
        (Failure failure) => left<Failure, PrayerTimesEntity>(failure),
        (PrayerTimesEntity value) => right<Failure, PrayerTimesEntity>(value),
      );
    }

    // Written to Isar so the monthly timetable and the notification scheduler
    // read the very same numbers instead of recalculating them.
    await _local.store(entity.toDay());
    return right<Failure, PrayerTimesEntity>(entity);
  }

  @override
  Future<Either<Failure, int>> syncWithAladhanApi(DateTime date) async {
    final DayPrayerTimes local = await day(date);
    final Either<Failure, int> result = await _network.guard(
      () => _remote.mismatchMinutes(
        date: local.date,
        local: local.times,
        latitude: local.spec.latitude,
        longitude: local.spec.longitude,
        method: local.spec.method,
        madhab: local.spec.madhab.key,
      ),
    );

    if (result.isLeft()) return result;
    final int diff = result.getOrElse(() => 0);
    await _local.store(local, verifiedDiffMinutes: diff);
    return right<Failure, int>(diff);
  }

  @override
  Future<void> ensureNotificationChannels() async {
    final AppSettings s = _settings();
    final ({String adhan, String adhanDescription, String reminder, String friday})
        channels = _channelNames();
    await _notifications.ensureChannels(
      adhanName: channels.adhan,
      adhanDescription: channels.adhanDescription,
      reminderName: channels.reminder,
      fridayName: channels.friday,
      lockScreenName: channels.reminder,
      adhanSound: s.adhanSound,
    );
  }

  @override
  Future<void> refreshLockScreenCard() async {
    final AppSettings s = _settings();
    final DateTime now = DateTime.now();
    // Today and tomorrow: enough to find "the next prayer" even after Isha, and
    // both come from the offline cache in the common case.
    final List<DayPrayerTimes> days = <DayPrayerTimes>[
      await day(now),
      await day(DateTime(now.year, now.month, now.day + 1)),
    ];
    await _refreshLockScreenCard(days, s);
  }

  @override
  Future<int> scheduleNotifications({
    int days = AppConstants.notificationDaysAhead,
  }) async {
    final AppSettings s = _settings();
    final ({String adhan, String adhanDescription, String reminder, String friday})
        channels = _channelNames();

    // Channels first: they are what a notification's sound and visibility are
    // read from, and creating an existing one costs nothing.
    await ensureNotificationChannels();

    // The month itself is planned by the *domain* use case (offline, pure) and
    // handed to the OS in one pass through this repository, which is the
    // `AdhanSchedulerPort` implementation. Each day the planner computes is also
    // written to the local cache, so the month screen never recomputes it.
    final ScheduleMonthlyPrayers planner = ScheduleMonthlyPrayers(
      engine: const CalculatePrayerTimes(),
      scheduler: this,
      reminderText: _reminderText,
    );

    final List<DayPrayerTimes> computed = <DayPrayerTimes>[];
    final int armed = await planner(
      settings: s,
      spec: spec,
      adhanText: _adhanText,
      days: days,
      channelName: channels.adhan,
      // The adhan must ring at the clock the app shows, so the manual
      // summer/winter correction is handed to the planner as well.
      shiftMinutes: resolveDstMinutes(s.dstMode),
      onDay: computed.add,
    );

    for (final DayPrayerTimes day in computed) {
      await _local.store(day);
    }

    await _refreshLockScreenCard(computed, s);
    return armed;
  }

  /// Hands the *next* prayer to the lock screen as one silent ongoing card.
  ///
  /// Called on every (re)plan, so the card is fresh whenever the app has run at
  /// all. Between runs the system's own chronometer keeps ticking — the card is
  /// drawn by the OS from a single `when` instant, so nothing of ours stays
  /// awake and the screen can be off.
  Future<void> _refreshLockScreenCard(
    List<DayPrayerTimes> computed,
    AppSettings s,
  ) async {
    try {
      if (!s.lockScreenAllDay || !s.notificationsEnabled) {
        await _notifications.cancelNextPrayerCard();
        return;
      }
      final int shift = resolveDstMinutes(s.dstMode);
      final ({PrayerName prayer, DateTime at})? next = nextPrayerAfter(
        days: computed,
        now: DateTime.now(),
        enabled: (PrayerName prayer) => s.isPrayerEnabled(prayer.key),
        shiftMinutes: resolveDstMinutes(s.dstMode),
      );
      if (next == null) {
        await _notifications.cancelNextPrayerCard();
        return;
      }
      // One card, one prayer: the next one. The elapsed state below replaces
      // it for twenty minutes after an adhan and then hands back to this text.
      final ({String title, String body}) card =
          _cardText?.call(next.prayer, next.at) ?? _adhanText(next.prayer, next.at);
      // The twenty minutes after an adhan belong to the congregation, not to
      // the countdown: the card flips to «how long ago», so the reader can still
      // judge whether to run. After that it returns to the next prayer.
      final DateTime now = DateTime.now();
      final ({PrayerName prayer, DateTime at})? called =
          _lastAdhanBefore(computed, now, s, shift);
      final bool elapsed = called != null &&
          now.difference(called.at) < elapsedWindow;
      final ({String title, String body}) text = elapsed
          ? _elapsedText?.call(
                called.prayer,
                called.at,
                now.difference(called.at),
              ) ??
              _adhanText(called.prayer, called.at)
          : card;
      await _notifications.showNextPrayerCard(
        target: next.at,
        since: elapsed ? called.at : null,
        countUp: elapsed,
        enabled: s.lockScreenAllDay,
        title: text.title,
        body: text.body,
        // The count-up has a lifetime: twenty minutes. Anything longer is a
        // number with no use, so the card switches itself back to the next
        // prayer at that instant — by alarm, because the app is not running.
        switchAt: elapsed ? called.at.add(elapsedWindow) : null,
        afterTitle: card.title,
        afterBody: card.body,
        afterWhen: next.at,
      );
    } catch (error) {
      // A lock-screen extra must never be the reason a schedule fails.
      if (kDebugMode) debugPrint('lock screen card failed: $error');
    }
  }

  // ------------------------------------------------------- AdhanSchedulerPort
  // The data layer's adapter: the domain asks for "replace the plan", and this
  // is where that becomes `flutter_local_notifications` calls.

  @override
  Future<int> replaceAll(
    List<ScheduledAdhan> items, {
    required AdhanSound adhanSound,
    required AdhanSound preAdhanSound,
    required bool vibrate,
    required String channelName,
  }) =>
      _notifications.replaceSchedule(
        items,
        adhanSound: adhanSound,
        preAdhanSound: preAdhanSound,
        vibrate: vibrate,
        channelName: channelName,
      );

  @override
  Future<void> cancelAll() => _notifications.cancelAdhan();

  @override
  Future<void> cancelNotifications() => _notifications.cancelAdhan();

  @override
  Future<int> scheduleSilence({int days = 7}) async {
    final AppSettings s = _settings();
    // Silence automation is strictly opt-in: without it, drop any pending alarm
    // so the phone can never be muted by a stale schedule.
    if (!s.silentModeEnabled && s.jumuahSilentMinutes == 0) {
      await _silentMode.cancelWindows();
      return 0;
    }

    final DateTime today = DateTime.now();
    final List<SilenceWindow> windows = <SilenceWindow>[];

    for (int offset = 0; offset < days; offset++) {
      // Calendar fields, not `+ Duration(days: …)`: a DST transition would make
      // one of these days 25 hours long and repeat a date (see
      // `ScheduleMonthlyPrayers` for the full note).
      final DateTime date = DateTime(today.year, today.month, today.day + offset);
      final DayPrayerTimes day = await this.day(date);

      for (final PrayerName prayer in PrayerName.obligatory) {
        if (!s.isPrayerEnabled(prayer.key)) continue;
        final DateTime at = day.timeOf(prayer);
        // Per prayer: the reader may want Isha silenced for 20 minutes and Fajr
        // not silenced at all, or the quiet to start a quarter of an hour after
        // the adhan rather than under it.
        final int starts = s.adhanPreferences.silentStartFor(prayer.key);
        final int lasts = s.adhanPreferences.silentDurationFor(prayer.key);
        windows.add(SilenceWindow(
          start: at.add(Duration(minutes: starts)),
          end: at.add(Duration(minutes: starts + lasts)),
        ));
      }

      if (date.weekday == DateTime.friday) {
        if (s.fridayModeEnabled) {
          final (int, int) start = _clock(s.fridayStart);
          final (int, int) end = _clock(s.fridayEnd);
          windows.add(SilenceWindow(
            start: DateTime(date.year, date.month, date.day, start.$1, start.$2),
            end: DateTime(date.year, date.month, date.day, end.$1, end.$2),
          ));
        }
        // The Jumu'ah hour itself, measured from the adhan rather than from a
        // typed clock: the khutbah starts when the adhan does.
        if (s.jumuahSilentMinutes > 0) {
          final DateTime at = day.timeOf(PrayerName.dhuhr);
          windows.add(SilenceWindow(
            start: at,
            end: at.add(Duration(minutes: s.jumuahSilentMinutes)),
          ));
        }
      }
    }

    return _silentMode.scheduleWindows(windows);
  }

  /// The latest adhan that has already happened among [days].
  ({PrayerName prayer, DateTime at})? _lastAdhanBefore(
    List<DayPrayerTimes> days,
    DateTime now,
    AppSettings s,
    int shift,
  ) {
    ({PrayerName prayer, DateTime at})? latest;
    for (final DayPrayerTimes day in days) {
      for (final PrayerName prayer in PrayerName.obligatory) {
        if (!s.isPrayerEnabled(prayer.key)) continue;
        final DateTime at = day.timeOf(prayer).add(Duration(minutes: shift));
        if (at.isAfter(now)) continue;
        if (latest == null || at.isAfter(latest.at)) {
          latest = (prayer: prayer, at: at);
        }
      }
    }
    return latest;
  }

  static (int, int) _clock(String value) {
    final List<String> parts = value.split(':');
    if (parts.length != 2) return (11, 30);
    return (int.tryParse(parts[0]) ?? 11, int.tryParse(parts[1]) ?? 30);
  }
}

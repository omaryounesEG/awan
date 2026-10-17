import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart';

/// The domain contract of the hybrid prayer engine.
///
/// Reading the times is infallible by design (offline arithmetic), so those
/// methods return plain values. Only the *online verification* can fail for a
/// reason the user can act on, so only it returns `Either<Failure, T>`.
///
/// It also *is* the [AdhanSchedulerPort]: the domain use case plans a month of
/// notifications and hands the plan to this contract; the data layer decides that
/// "hand it to the OS" means `flutter_local_notifications`.
abstract class PrayerRepository implements AdhanSchedulerPort {
  /// Always returns a value: the offline calculation, served from cache when
  /// the same parameters were used before.
  Future<DayPrayerTimes> day(DateTime date, {bool forceRecompute = false});

  /// A whole month, cached day by day (monthly timetable, notifications).
  Future<List<DayPrayerTimes>> month(int year, int month);

  /// The next prayer, rolling into tomorrow's fajr when the day is over.
  Future<NextPrayer?> next(DateTime now);

  /// **Clean-Architecture contract (Step 3).**
  ///
  /// The offline calculation for a coordinate/day pair, wrapped as
  /// `Either<Failure, PrayerTimesEntity>` so an invalid latitude or an
  /// impossible date is a typed failure instead of an exception crossing a layer
  /// boundary. Implemented on top of the same arithmetic core as [day], and the
  /// result is written to the offline cache.
  Future<Either<Failure, PrayerTimesEntity>> getDailyPrayers(
    double lat,
    double lng,
    DateTime date,
  );

  /// Compares the offline angles with Aladhan and returns the worst mismatch in
  /// whole minutes. `Left` means "could not verify (offline or server error)".
  Future<Either<Failure, int>> syncWithAladhanApi(DateTime date);

  /// Queues the coming [days] of adhan notifications with the OS.
  Future<int> scheduleNotifications({int days});

  /// Creates (or re-creates) the OS notification channels from the current
  /// settings.
  ///
  /// Separate from [scheduleNotifications] because it must run on **every**
  /// launch: Android bakes a channel's sound in at creation, so a build that
  /// changes the adhan tone only takes effect once the new channel id is
  /// actually created — and that call used to live behind a "the plan is already
  /// healthy, nothing to do" early return, which meant it never ran on a device
  /// that had been scheduled once. Idempotent and one binder call.
  Future<void> ensureNotificationChannels();

  /// Re-posts the all-day lock-screen card for the next prayer.
  ///
  /// Also idempotent and cheap (the card is one fixed notification id), and also
  /// has to run on every launch so the countdown on the lock screen is never
  /// left pointing at a prayer that has already passed.
  Future<void> refreshLockScreenCard();

  Future<void> cancelNotifications();

  /// Queues the OS-level mute/unmute alarms (Android).
  Future<int> scheduleSilence({int days});
}

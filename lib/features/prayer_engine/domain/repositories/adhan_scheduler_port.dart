import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';

/// The domain's port for "hand this plan to whatever will actually deliver it".
///
/// The implementation lives in the data layer (a thin adapter over
/// `NotificationService`), which is what keeps `core/` free of any knowledge of
/// the prayer feature and keeps the use case free of any knowledge of Android.
abstract interface class AdhanSchedulerPort {
  /// Replaces the whole pending adhan set in one shot and returns how many
  /// notifications were armed. Never schedules an instant in the past.
  Future<int> replaceAll(
    List<ScheduledAdhan> items, {
    required AdhanSound adhanSound,
    required AdhanSound preAdhanSound,
    required bool vibrate,
    required String channelName,
  });

  /// Drops every pending adhan notification (silence alarms are a different id
  /// space and are not touched).
  Future<void> cancelAll();
}

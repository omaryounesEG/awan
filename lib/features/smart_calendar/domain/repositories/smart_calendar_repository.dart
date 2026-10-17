import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// What the app needs from a calendar, whichever calendar it is.
///
/// The device calendar is the first implementation because it is the one that
/// needs no account: `device_calendar`-style access through the native bridge.
/// Google and Outlook sit behind the same four methods — the rolling window does
/// not know or care which one it is writing to.
abstract class SmartCalendarRepository {
  Future<bool> hasPermission();

  /// Asks the OS once; false means the reader said no (or the OS refused).
  Future<bool> requestPermission();

  Future<List<CalendarEvent>> eventsBetween(DateTime from, DateTime to);

  /// Writes one block and returns the calendar's event id, or null when the
  /// phone has no writable calendar.
  Future<String?> insertBlock(PrayerBlock block, {String? calendarId});

  Future<bool> moveEvent(String eventId, DateTime start, DateTime end);

  Future<bool> deleteEvent(String eventId);

  /// The calendar this app may write to, or null when there is none.
  Future<String?> writableCalendarId();

  /// Fires whenever the phone's calendar changes, throttled by the native side.
  Stream<void> get changes;

  Future<void> dispose();
}

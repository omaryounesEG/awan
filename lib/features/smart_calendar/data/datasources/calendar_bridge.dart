import 'package:flutter/services.dart';

import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';

/// The native calendar, through `awan/calendar`.
///
/// Every method degrades to "nothing" when the channel is absent (desktop,
/// tests), so no screen has to guard for the platform.
class CalendarBridge {
  static const MethodChannel _channel = MethodChannel('awan/calendar');
  static const EventChannel _changes = EventChannel('awan/calendar/changes');

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String?> writableCalendarId() async {
    try {
      return await _channel.invokeMethod<String>('writableCalendarId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<CalendarEvent>> query(DateTime from, DateTime to) async {
    try {
      final List<Object?>? rows = await _channel.invokeMethod<List<Object?>>(
        'query',
        <String, Object?>{
          'start': from.millisecondsSinceEpoch,
          'end': to.millisecondsSinceEpoch,
        },
      );
      if (rows == null) return const <CalendarEvent>[];
      return rows
          .whereType<Map<Object?, Object?>>()
          .map(_toEvent)
          .whereType<CalendarEvent>()
          .toList();
    } on PlatformException {
      return const <CalendarEvent>[];
    } on MissingPluginException {
      return const <CalendarEvent>[];
    }
  }

  static CalendarEvent? _toEvent(Map<Object?, Object?> row) {
    final int? start = (row['start'] as num?)?.toInt();
    final int? end = (row['end'] as num?)?.toInt();
    final Object? id = row['id'];
    if (start == null || end == null || id == null) return null;
    final String title = (row['title'] as String?)?.trim() ?? '';
    final String note = (row['note'] as String?) ?? '';
    return CalendarEvent(
      id: id.toString(),
      title: title.isEmpty ? '—' : title,
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
      allDay: row['allDay'] == true,
      isOrganizer: row['isOrganizer'] == true,
      busy: row['busy'] != false,
      calendarId: row['calendarId']?.toString(),
      note: note.isEmpty ? null : note,
    );
  }

  Future<String?> insert({
    required String title,
    required DateTime start,
    required DateTime end,
    required String marker,
    String? calendarId,
  }) async {
    try {
      return await _channel.invokeMethod<String>(
        'insert',
        <String, Object?>{
          'title': title,
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch,
          'marker': marker,
          'calendarId': calendarId,
        },
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> move(String id, DateTime start, DateTime end) async {
    try {
      return await _channel.invokeMethod<bool>(
            'move',
            <String, Object?>{
              'id': id,
              'start': start.millisecondsSinceEpoch,
              'end': end.millisecondsSinceEpoch,
            },
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      return await _channel.invokeMethod<bool>(
            'delete',
            <String, Object?>{'id': id},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Coalesced by the native side; one event per burst of calendar writes.
  Stream<void> get changes => _changes.receiveBroadcastStream().map((Object? _) {});
}

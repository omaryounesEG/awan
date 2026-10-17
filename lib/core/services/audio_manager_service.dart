import 'package:flutter/services.dart';

/// A window during which the phone should stay silent.
class SilenceWindow {
  const SilenceWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get startMs => start.millisecondsSinceEpoch;
  int get endMs => end.millisecondsSinceEpoch;
}

/// Auto-silent automation, implemented natively — channel `com.awan.app/audio`.
///
/// Android only (iOS forbids programmatic ringer changes): the mute/unmute
/// moments are handed to `AlarmManager`, so the **OS** — not a Dart background
/// service — performs the switch. Nothing of ours stays alive to consume
/// battery, and nothing polls: this is what makes "auto-silent at prayer time"
/// compatible with the app's zero-tracker rule.
///
/// Silencing the ringer needs Notification-Policy (Do-Not-Disturb) access, which
/// only the user can grant — [hasPolicyAccess] reports it so the UI can explain
/// instead of failing silently.
class AudioManagerService {
  static const MethodChannel _channel = MethodChannel('com.awan.app/audio');

  /// True when the app holds Notification Policy (Do Not Disturb) access.
  Future<bool> hasPolicyAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasPolicyAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openPolicySettings() async {
    try {
      await _channel.invokeMethod<void>('openPolicySettings');
    } catch (_) {
      // iOS has no equivalent — the UI explains that instead.
    }
  }

  Future<bool> hasExactAlarmAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasExactAlarmAccess') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Silences the ringer now (`RINGER_MODE_SILENT`).
  Future<bool> setSilentMode() => _setRinger(silent: true);

  /// Restores the ringer now (`RINGER_MODE_NORMAL`).
  Future<bool> setNormalMode() => _setRinger(silent: false);

  /// The original, parameterised form of the two helpers above — used where a
  /// single toggle needs to set either state from one call site.
  Future<bool> setSilentNow(bool silent) => _setRinger(silent: silent);

  Future<bool> _setRinger({required bool silent}) async {
    try {
      return await _channel.invokeMethod<bool>(
            'setSilentNow',
            <String, Object?>{'silent': silent},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Returns 'normal' | 'silent' | 'vibrate'.
  Future<String> currentMode() async {
    try {
      return await _channel.invokeMethod<String>('currentMode') ?? 'normal';
    } catch (_) {
      return 'normal';
    }
  }

  /// Queues every future mute/unmute moment with the OS alarm manager.
  ///
  /// Windows that already ended are dropped here, so a stale schedule can never
  /// mute the phone after the fact.
  Future<int> scheduleWindows(List<SilenceWindow> windows) async {
    final List<Map<String, int>> payload = <Map<String, int>>[
      for (final SilenceWindow window in windows)
        if (window.end.isAfter(DateTime.now()))
          <String, int>{'start': window.startMs, 'end': window.endMs},
    ];
    if (payload.isEmpty) return 0;
    try {
      return await _channel.invokeMethod<int>(
            'scheduleWindows',
            <String, Object?>{'windows': payload},
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  /// Gives the ringer back when this app is the one that silenced it.
  ///
  /// Used when auto-silent is switched off mid-window: cancelling the alarms
  /// would otherwise leave the phone silent with nothing left to undo it.
  Future<void> releaseRinger() async {
    try {
      await _channel.invokeMethod<void>('releaseRinger');
    } catch (_) {
      // ignore
    }
  }

  Future<void> cancelWindows() async {
    try {
      await _channel.invokeMethod<void>('cancelWindows');
    } catch (_) {
      // ignore
    }
  }
}

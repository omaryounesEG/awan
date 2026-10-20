import 'dart:async';

import 'package:flutter/services.dart';

/// What the player is doing, as one value the UI can switch on.
class AdhkarAudioEvent {
  const AdhkarAudioEvent({
    required this.state,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.reason,
  });

  final String state; // idle | loading | playing | paused | completed | error
  final Duration position;
  final Duration duration;
  final String? reason;

  bool get playing => state == 'playing';
  bool get busy => state == 'loading';

  static AdhkarAudioEvent from(Object? raw) {
    if (raw is! Map) return const AdhkarAudioEvent(state: 'idle');
    return AdhkarAudioEvent(
      state: '${raw['state'] ?? 'idle'}',
      position: Duration(milliseconds: (raw['position'] as num?)?.toInt() ?? 0),
      duration: Duration(milliseconds: (raw['duration'] as num?)?.toInt() ?? 0),
      reason: raw['reason'] as String?,
    );
  }
}

/// In-app recitation, over the native MediaPlayer.
///
/// A dhikr is one short clip, so the contract is small on purpose: play one
/// source, pause, resume, seek, stop — and listen for `completed` so the reader
/// can be carried to the next dhikr without touching the phone (car mode).
class AdhkarAudioService {
  AdhkarAudioService() {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  static const MethodChannel _channel =
      MethodChannel('com.awan.app/adhkar_audio');

  final StreamController<AdhkarAudioEvent> _events =
      StreamController<AdhkarAudioEvent>.broadcast();

  Stream<AdhkarAudioEvent> get events => _events.stream;

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'event') {
      _events.add(AdhkarAudioEvent.from(call.arguments));
    }
  }

  Future<void> play(String source, {String? title}) async {
    try {
      await _channel.invokeMethod<void>(
        'play',
        <String, Object?>{'source': source, 'title': title},
      );
    } on MissingPluginException {
      _events.add(const AdhkarAudioEvent(
        state: 'error',
        reason: 'unsupported',
      ));
    }
  }

  Future<void> pause() => _invoke('pause');

  Future<void> resume() => _invoke('resume');

  Future<void> stop() => _invoke('stop');

  Future<void> seek(Duration position) async {
    await _channel.invokeMethod<void>(
      'seek',
      <String, Object?>{'position': position.inMilliseconds},
    );
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // iOS has no native player in this build; the screen hides the controls.
    }
  }
}

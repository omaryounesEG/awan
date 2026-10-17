import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';

/// Auditions an alert clip through the native player.
///
/// Deliberately native and deliberately the *raw resource*: the reader is choosing
/// the sound a notification will make, and a notification's sound is played by the
/// system from `res/raw`. Playing a Flutter asset copy instead would be a rehearsal
/// of a different performance.
class SoundPreviewService {
  const SoundPreviewService();

  static const MethodChannel _channel = MethodChannel('awan/sounds');

  /// Plays [sound] from the start, stopping whatever was playing.
  ///
  /// [AdhanSound.system] plays the phone's own alarm tone; [AdhanSound.silent]
  /// plays nothing at all, which is the honest preview of silence.
  Future<void> play(AdhanSound sound) async {
    if (!_isAndroid) return;
    if (sound == AdhanSound.silent) {
      await stop();
      return;
    }
    final String? raw = sound.rawResource;
    if (raw == null) {
      await _channel.invokeMethod<void>('playSystem');
      return;
    }
    await _channel.invokeMethod<void>('playPreview', <String, Object?>{'res': raw});
  }

  Future<void> stop() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('stopPreview');
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

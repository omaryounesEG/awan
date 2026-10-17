import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:awan/features/recitation/domain/usecases/speech_segmenter.dart';

/// The microphone, configured exactly the way Whisper expects it.
///
/// 16 kHz, one channel, 16-bit PCM — the architecture note's numbers, and not
/// negotiable: Whisper was trained on that rate, and resampling inside the app
/// would throw away the high frequencies that distinguish ص from س.
///
/// The capture itself is a native `AudioRecord` behind an `EventChannel`, not a
/// plugin: the project already owns its sensor and model bridges, and the
/// contract here is narrower than any recorder package — bytes while the screen
/// is open, a hard release the moment it closes, nothing on disk.
class RecitationAudio {
  RecitationAudio({EventChannel? channel})
      : _channel = channel ?? const EventChannel('com.awan.app/recitation/audio');

  final EventChannel _channel;

  Future<bool> hasPermission() async {
    final PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    return (await Permission.microphone.request()).isGranted;
  }

  /// Opens the microphone and returns the float samples, chunk by chunk.
  Future<Stream<Float32List>> start() async {
    final Stream<dynamic> raw = _channel.receiveBroadcastStream();
    return raw
        .map((dynamic event) => pcm16ToFloat(event as Uint8List))
        .handleError((Object error) {
      throw error;
    });
  }

  /// Nothing to release here: cancelling the last listener on the channel is
  /// what sends `onCancel` to the native side, and the repository owns that
  /// subscription. Kept so the port stays symmetric.
  Future<void> dispose() async {}
}

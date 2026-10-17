import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native side of the prayer clock.
///
/// One thing a Flutter screen cannot do on its own: **keep the screen on** while
/// the clock is the thing being read. Every call degrades to a no-op when the
/// platform channel is absent (desktop, tests), so no screen guards for it.
class ClockOverlayService {
  ClockOverlayService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('awan/clock');

  final MethodChannel _channel;

  Future<void> keepScreenOn(bool on) async {
    try {
      await _channel.invokeMethod<void>(
        'keepScreenOn',
        <String, Object?>{'on': on},
      );
    } on MissingPluginException {
      // Nothing to keep awake on a desktop or in a test.
    } on PlatformException catch (error) {
      if (kDebugMode) debugPrint('clock channel keepScreenOn failed: $error');
    }
  }
}

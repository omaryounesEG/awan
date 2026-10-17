import 'dart:async';

import 'package:flutter/services.dart';

import 'package:awan/core/error/failures.dart';

/// One compass sample, already corrected to **true** north.
class HeadingReading {
  const HeadingReading({
    required this.trueHeading,
    required this.magneticHeading,
    required this.declination,
  });

  /// Degrees clockwise from true north — what the qibla needle must be compared
  /// against (the qibla bearing is also true-north based).
  final double trueHeading;

  /// The raw magnetometer azimuth.
  final double magneticHeading;

  /// Magnetic declination used for the correction (east positive). In Cairo it
  /// is roughly +3.5 degrees: ignoring it would point the needle several degrees
  /// off the qibla, which is exactly the mistake this class exists to avoid.
  final double declination;
}

/// The device's orientation sensor, over a native `EventChannel`.
///
/// **Why this replaces `flutter_compass`.** The package builds fine on this
/// toolchain (verified), but it exposes the *magnetic* azimuth only: there is no
/// API to apply the local declination, so the needle is 1-6 degrees off true
/// north depending on where the user lives, and the error is invisible on
/// screen. It also gives no explicit "this device has no magnetometer" signal and
/// no way to prove from outside that the sensor was really switched off when the
/// screen closed.
///
/// Doing it natively is ~60 lines of Kotlin (`NATIVE_SETUP.md`) and buys three
/// things this feature needs:
///
/// * **true north** — `SensorManager.getOrientation()` for the azimuth plus
///   `GeomagneticField.declination()` (the WMM model, offline) for the
///   correction;
/// * an explicit `no_sensor` error the UI turns into a sentence instead of an
///   empty dial;
/// * a `[AwanSensors]` log line on every register/unregister, so "the compass
///   stops when the screen closes" is *observable* in `adb logcat` rather than
///   taken on faith.
///
/// The stream is cold and *not* wrapped: `receiveBroadcastStream` already returns
/// a broadcast stream whose `onListen`/`onCancel` are wired to the platform's
/// `listen`/`cancel` calls, and cancelling its last listener is what powers the
/// sensor down. (`qiblaProvider` is `autoDispose`, so closing the screen is what
/// ends the subscription.)
///
/// **Do not wrap this in `asBroadcastStream`.** An earlier revision did, to count
/// listeners: the wrapper subscribes to the source on the first listener and
/// keeps that subscription alive after the last one leaves, so the platform
/// `cancel` is never sent and the magnetometer stays on for the life of the
/// process. It was caught on the device — `adb logcat` showed `[AwanSensors]
/// heading listener registered` and never `unregistered` — and is now locked by
/// `test/heading_service_test.dart`.
class HeadingService {
  /// [source] is an injection seam for tests: the platform's broadcast stream,
  /// replaced by a local controller so the cancel contract can be asserted
  /// without a device. Production always passes only [channel].
  HeadingService({EventChannel? channel, Stream<dynamic>? source})
      : _events = channel ?? const EventChannel('com.awan.app/sensors/heading'),
        _source = source;

  final EventChannel _events;
  final Stream<dynamic>? _source;

  Stream<HeadingReading> heading({double? latitude, double? longitude}) {
    // The native side takes the reference coordinates once, per subscription:
    // declination is a property of *where* the phone is, not of the sample rate.
    final Map<String, dynamic>? arguments =
        (latitude == null || longitude == null)
            ? null
            : <String, dynamic>{'latitude': latitude, 'longitude': longitude};

    final Stream<dynamic> raw =
        _source ?? _events.receiveBroadcastStream(arguments);

    return raw.transform(_nativeErrors()).map(_decode);
  }

  /// `PlatformException` (including our own `no_sensor` code) becomes a domain
  /// failure, so the UI never has to know about platform channels.
  StreamTransformer<dynamic, dynamic> _nativeErrors() =>
      StreamTransformer<dynamic, dynamic>.fromHandlers(
        handleError: (
          Object error,
          StackTrace stackTrace,
          EventSink<dynamic> sink,
        ) {
          sink.addError(toFailure(error));
        },
      );

  HeadingReading _decode(dynamic event) {
    if (event is Map) {
      final Map<Object?, Object?> map = event;
      final double? heading = (map['trueHeading'] as num?)?.toDouble();
      if (heading == null) {
        throw const UnsupportedFailure(message: 'sensor_unavailable');
      }
      return HeadingReading(
        trueHeading: (heading + 360.0) % 360.0,
        magneticHeading: ((map['magneticHeading'] as num?)?.toDouble() ?? 0) %
            360.0,
        declination: (map['declination'] as num?)?.toDouble() ?? 0,
      );
    }
    if (event is String && event == 'no_sensor') {
      throw const UnsupportedFailure(message: 'no_magnetometer');
    }
    throw const UnsupportedFailure(message: 'sensor_unavailable');
  }

  static Failure toFailure(Object error) {
    if (error is UnsupportedFailure) return error;
    if (error is PlatformException) {
      return UnsupportedFailure(message: error.code, cause: error);
    }
    return UnsupportedFailure(cause: error);
  }
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/services/heading_service.dart';

/// A broadcast controller shaped like `EventChannel.receiveBroadcastStream`:
/// `onListen` is the platform `listen`, `onCancel` is the platform `cancel`.
({StreamController<dynamic> controller, List<int> listens, List<int> cancels})
    _fakeSource() {
  final List<int> listens = <int>[];
  final List<int> cancels = <int>[];
  final StreamController<dynamic> controller =
      StreamController<dynamic>.broadcast(
    onListen: () => listens.add(1),
    onCancel: () => cancels.add(1),
  );
  return (controller: controller, listens: listens, cancels: cancels);
}

/// The compass channel is a *battery* contract, so it gets its own test file.
///
/// The bug these tests lock down was found on a real device, not by reasoning:
/// `adb logcat` showed `[AwanSensors] heading listener registered` when the qibla
/// screen opened and **never** `unregistered` after it closed, because the service
/// wrapped the platform stream in `asBroadcastStream` — and that wrapper keeps its
/// subscription to the source alive after the last listener cancels. The
/// magnetometer stayed on for the life of the process.
void main() {
  test(
    'cancelling the last listener releases the source, so the sensor powers off',
    () async {
      final ({
        StreamController<dynamic> controller,
        List<int> listens,
        List<int> cancels
      }) fake = _fakeSource();
      final HeadingService service =
          HeadingService(source: fake.controller.stream);

      final List<HeadingReading> received = <HeadingReading>[];
      final StreamSubscription<HeadingReading> subscription = service
          .heading(latitude: 30.0444, longitude: 31.2357)
          .listen(received.add);

      fake.controller.add(<String, double>{
        'trueHeading': 100.5,
        'magneticHeading': 95.5,
        'declination': 5.03492,
      });
      await pumpEventQueue();

      expect(fake.listens.length, 1, reason: 'listening starts the hardware');
      expect(received.single.trueHeading, 100.5);
      expect(received.single.declination, closeTo(5.03, 0.01));

      await subscription.cancel();
      await pumpEventQueue();

      expect(
        fake.cancels.length,
        1,
        reason: 'the magnetometer must be handed back when the screen closes',
      );

      await fake.controller.close();
    },
  );

  test('the wrapper that caused the leak provably never cancels its source',
      () async {
    // This is the *old* shape, kept as executable documentation. A future
    // refactor that reintroduces the wrapper fails this test and can read here
    // what it costs: the platform `cancel` is never sent, so the sensor runs
    // until the process dies.
    final ({
      StreamController<dynamic> controller,
      List<int> listens,
      List<int> cancels
    }) fake = _fakeSource();

    final StreamSubscription<dynamic> subscription =
        fake.controller.stream.asBroadcastStream().listen((_) {});
    await pumpEventQueue();
    await subscription.cancel();
    await pumpEventQueue();

    expect(fake.listens.length, 1);
    expect(
      fake.cancels,
      isEmpty,
      reason: 'asBroadcastStream never cancels its source — hence HeadingService '
          'must not wrap the platform stream',
    );

    await fake.controller.close();
  });

  test('a device with no magnetometer is a typed failure, not a dead dial',
      () async {
    final ({
      StreamController<dynamic> controller,
      List<int> listens,
      List<int> cancels
    }) fake = _fakeSource();
    final HeadingService service =
        HeadingService(source: fake.controller.stream);

    final Future<Object> failure = service.heading().first.then<Object>(
          (HeadingReading _) => 'no error',
          onError: (Object error) => error,
        );
    fake.controller.addError(
      PlatformException(code: 'no_sensor', message: 'no_magnetometer'),
    );

    final Object result = await failure;
    expect(result, isA<UnsupportedFailure>());
    expect((result as UnsupportedFailure).message, 'no_sensor');

    await fake.controller.close();
  });
}

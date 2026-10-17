import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/heading_service.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/prayer_engine/domain/entities/qibla_direction.dart';
import 'package:awan/features/prayer_engine/domain/usecases/get_qibla_direction.dart';

/// The qibla use case itself: Kaaba bearing + distance, offline, no sensor.
final Provider<GetQiblaDirection> getQiblaDirectionProvider =
    Provider<GetQiblaDirection>((Ref ref) => const GetQiblaDirection());

/// The qibla for the *saved* coordinates.
///
/// Offline and synchronous on purpose: the bearing exists the instant the screen
/// opens, before any GPS fix, and it is exact as long as the user is in the city
/// the settings name. A device fix only refines the declination correction.
final Provider<Either<Failure, QiblaDirection>> qiblaResultProvider =
    Provider<Either<Failure, QiblaDirection>>((Ref ref) {
  final AppSettings settings = ref.watch(settingsProvider);
  return ref.watch(getQiblaDirectionProvider)(
    latitude: settings.latitude,
    longitude: settings.longitude,
  );
});

/// The bearing alone, or `null` when the coordinates are unusable.
final Provider<QiblaDirection?> qiblaDirectionProvider =
    Provider<QiblaDirection?>(
  (Ref ref) => ref.watch(qiblaResultProvider).valueOrNull,
);

/// The live compass, as a cold auto-disposed stream.
///
/// **Battery.** `autoDispose` is the whole mechanism: the provider subscribes
/// while the qibla screen is on-screen and cancels the moment it is popped, which
/// — through the native `onCancel` — unregisters the sensor listener. Nothing in
/// this file holds the sensor open, and the app never keeps a compass running in
/// the background.
final AutoDisposeStreamProvider<HeadingReading> headingProvider =
    StreamProvider.autoDispose<HeadingReading>((Ref ref) {
  final QiblaDirection? direction = ref.watch(qiblaDirectionProvider);
  final HeadingService service = ref.watch(headingServiceProvider);

  // The reference point only matters for the magnetic-declination correction.
  return service.heading(
    latitude: direction?.fromLatitude,
    longitude: direction?.fromLongitude,
  );
});

/// Everything the compass needs in one value.
class QiblaReading {
  const QiblaReading({
    required this.direction,
    required this.heading,
    required this.declination,
    required this.sensorError,
    required this.isAligned,
  });

  final QiblaDirection? direction;

  /// True (north-referenced) heading, `null` while the sensor is warming up or
  /// when the device has no magnetometer.
  final double? heading;

  final double? declination;

  /// Set when the device cannot report a heading at all — the screen shows a
  /// sentence, not an empty dial.
  final Failure? sensorError;

  final bool isAligned;

  bool get hasHeading => heading != null;
}

/// The provider Step 6 asks for: current position + true qibla bearing + live
/// heading, recombined every time any of the three changes.
final AutoDisposeProvider<QiblaReading> qiblaProvider =
    Provider.autoDispose<QiblaReading>((Ref ref) {
  final QiblaDirection? direction = ref.watch(qiblaDirectionProvider);
  final AsyncValue<HeadingReading> heading = ref.watch(headingProvider);

  final HeadingReading? reading = heading.valueOrNull;
  final Failure? sensorError = heading.hasError
      ? HeadingService.toFailure(heading.error!)
      : null;

  final double? currentHeading = reading?.trueHeading;
  final bool aligned = currentHeading != null &&
      direction != null &&
      Geo.isAligned(
        currentHeading,
        direction.bearingDegrees,
        tolerance: AppConstants.qiblaToleranceDegrees,
      );

  return QiblaReading(
    direction: direction,
    heading: currentHeading,
    declination: reading?.declination,
    sensorError: sensorError,
    isAligned: aligned,
  );
});

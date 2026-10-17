import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:awan/core/services/location/app_location.dart';

/// A raw device fix.
class DeviceFix {
  const DeviceFix({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

/// Result of a location request: a value or a reason — never an exception.
class LocationOutcome {
  const LocationOutcome({this.location, this.failure});

  final AppLocation? location;
  final LocationFailure? failure;

  bool get isSuccess => location != null;
}

/// Device location over a thin platform channel.
///
/// **Why not `geolocator`:** on this toolchain (Flutter 3.24.3 + AGP 8) the
/// plugin's Android module fails to configure the build —
/// `A problem occurred configuring project ':geolocator_android' ...
/// compileSdkVersion is not specified` — reproduced in an isolated build probe
/// with 14.0.2 as well. The only workaround would be patching the pub cache,
/// which is not reproducible on another machine.
///
/// So the fix is read from `LocationManager` natively instead: last known fix
/// first, then a single bounded update. Nothing runs in the background and no
/// wakelock is ever taken. `NATIVE_SETUP.md` documents the Kotlin side.
class LocationService {
  LocationService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: const <String, String>{
                  // Nominatim (and Overpass) reject anonymous clients.
                  'User-Agent': 'AwanApp/1.0 (prayer times & quran)',
                  'Accept-Language': 'ar,en',
                },
              ),
            );

  static const MethodChannel _channel = MethodChannel('awan/location');
  final Dio _dio;

  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  Future<bool> isServiceEnabled() async =>
      await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;

  Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod<void>('openLocationSettings');
    } on MissingPluginException {
      // Desktop/test hosts have no implementation — silently ignore.
    }
  }

  /// Null when anything at all goes wrong; callers fall back to the saved city.
  Future<DeviceFix?> currentFix() async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('getLocation');
      if (raw == null) return null;
      final Object? lat = raw['latitude'];
      final Object? lng = raw['longitude'];
      if (lat is! num || lng is! num) return null;
      return DeviceFix(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        accuracyMeters: (raw['accuracy'] as num?)?.toDouble(),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Fills in a human-readable city name (best effort, skipped when offline).
  Future<AppLocation> withCityName(AppLocation location) async {
    if ((location.cityAr ?? '').isNotEmpty || (location.cityEn ?? '').isNotEmpty) {
      return location;
    }
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: <String, dynamic>{
          'format': 'jsonv2',
          'lat': location.latitude,
          'lon': location.longitude,
          'zoom': 10,
          'accept-language': 'ar,en',
        },
      );
      final Object? data = response.data;
      if (data is Map) {
        final Object? address = data['address'];
        final String? city = (data['name'] as String?) ??
            (address is Map
                ? (address['city'] ??
                        address['town'] ??
                        address['state'] ??
                        address['country']) as String?
                : null);
        if (city != null && city.trim().isNotEmpty) {
          return location.copyWith(cityAr: city.trim(), cityEn: city.trim());
        }
      }
    } catch (_) {
      // Offline or rate-limited: coordinates are enough for prayer times.
    }
    return location;
  }

  /// Request → fix → best-effort city naming. Never throws.
  Future<LocationOutcome> resolve() async {
    if (!await isServiceEnabled()) {
      return const LocationOutcome(failure: LocationFailure.serviceDisabled);
    }
    bool granted = await hasPermission();
    if (!granted) granted = await requestPermission();
    if (!granted) {
      return const LocationOutcome(failure: LocationFailure.permissionDenied);
    }
    final DeviceFix? fix = await currentFix();
    if (fix == null) {
      return const LocationOutcome(failure: LocationFailure.timeout);
    }
    final AppLocation located = AppLocation(
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyMeters: fix.accuracyMeters,
      fromDevice: true,
    );
    return LocationOutcome(location: await withCityName(located));
  }
}

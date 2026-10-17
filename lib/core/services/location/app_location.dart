/// A resolved geographic position used by every feature that needs one.
class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.cityAr,
    this.cityEn,
    this.fromDevice = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? cityAr;
  final String? cityEn;

  /// True when it came from the device sensor rather than manual selection.
  final bool fromDevice;

  String get label => cityAr ?? cityEn ?? _coords;

  String labelFor(String localeCode) => localeCode == 'ar'
      ? (cityAr ?? cityEn ?? _coords)
      : (cityEn ?? cityAr ?? _coords);

  String get _coords =>
      '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';

  AppLocation copyWith({
    String? cityAr,
    String? cityEn,
    double? accuracyMeters,
    bool? fromDevice,
  }) =>
      AppLocation(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters ?? this.accuracyMeters,
        cityAr: cityAr ?? this.cityAr,
        cityEn: cityEn ?? this.cityEn,
        fromDevice: fromDevice ?? this.fromDevice,
      );
}

/// Why a location request failed — the UI turns each case into a concrete
/// instruction ("enable location", "grant the permission", "pick a city").
enum LocationFailure {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  timeout,
  unknown,
}

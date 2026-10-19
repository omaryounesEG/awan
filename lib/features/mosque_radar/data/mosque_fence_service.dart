import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';

/// The answer to "am I standing in one of my mosques right now?".
@immutable
class MosqueFenceCheck {
  const MosqueFenceCheck({
    this.inside,
    this.name,
    this.distanceMeters,
    this.accuracyMeters,
    this.reason = 'unknown',
  });

  /// `null` means "we could not tell" — no permission, no fix, or no fences.
  final bool? inside;
  final String? name;
  final double? distanceMeters;
  final double? accuracyMeters;
  final String reason;

  bool get known => inside != null;
  bool get isInside => inside == true;
}

/// The bridge that lets the alarm know about the reader's mosques.
///
/// The native side cannot ask Flutter anything while the app is dead, so the
/// list is *pushed* to it: one JSON array in its own preference file, rewritten
/// whenever a mosque is added, removed, or the mode is switched.
///
/// Everything here fails soft. On iOS there is no ringer control at all, and a
/// missing plugin must read as "the feature is off", never as a crash.
class MosqueFenceService {
  static const MethodChannel _channel =
      MethodChannel('com.awan.app/mosque_fence');
  static const String _enabledKey = 'mosque_fence_enabled';

  Future<bool> isEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Writes the list and the switch to the native side. Returns how many
  /// fences it accepted (0 on a platform without the channel).
  Future<int> sync(
    List<UserMosque> mosques, {
    required bool enabled,
  }) async {
    try {
      return await _channel.invokeMethod<int>('sync', <String, Object?>{
        'enabled': enabled,
        'fences': <Map<String, Object?>>[
          for (final UserMosque mosque in mosques)
            <String, Object?>{
              'name': mosque.name ?? '',
              'lat': mosque.latitude,
              'lng': mosque.longitude,
              'radius': mosque.radiusMeters,
            },
        ],
      }) ??
          0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }

  /// Uses the same native check the alarm uses, so "تحقّق الآن" is a real test
  /// and not a second implementation that can drift.
  Future<MosqueFenceCheck> check() async {
    try {
      // The button always asks for a fresh fix; the alarm does not.
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>(
        'check',
        <String, Object?>{'force': true},
      );
      if (raw == null) return const MosqueFenceCheck();
      return MosqueFenceCheck(
        inside: raw['inside'] as bool?,
        name: raw['name'] as String?,
        distanceMeters: (raw['distance'] as num?)?.toDouble(),
        accuracyMeters: (raw['accuracy'] as num?)?.toDouble(),
        reason: '${raw['reason'] ?? 'unknown'}',
      );
    } on MissingPluginException {
      return const MosqueFenceCheck(reason: 'unsupported');
    } on PlatformException {
      return const MosqueFenceCheck(reason: 'error');
    }
  }
}

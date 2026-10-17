import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/data/models/mosque_cache_entry.dart';

/// The radar's cache rule, extracted so it can be tested without a database.
///
/// Step 6 asks for: *"if mosques were fetched for this exact coordinate (within a
/// 500 m threshold) in the last 48 hours, return the cached data"*. That sentence
/// is implemented as a **grid + neighbourhood** lookup rather than a scan:
///
/// * one row per ~1.1 km cell (`lat:lon` rounded to 2 decimals, which is the
///   `cellKey` index), so a lookup is an index hit, not a table scan;
/// * a 3x3 neighbourhood of cells is probed, because a point 500 m from where we
///   cached last time can fall in any of the eight neighbouring cells;
/// * the winner must be both **fresh** (48 h) and **near** (500 m, haversine,
///   not "same cell") — the distance test is what turns the grid into the 500 m
///   rule the brief asked for.
///
/// Cost of a hit: zero network calls, zero tile fetches, one indexed read.
class MosqueCachePolicy {
  const MosqueCachePolicy({
    this.ttlHours = AppConstants.mosqueCacheTtlHours,
    this.radiusMeters = AppConstants.mosqueCacheRadiusMeters,
  });

  final int ttlHours;
  final int radiusMeters;

  bool isFresh(DateTime fetchedAt, DateTime now) =>
      now.difference(fetchedAt) < Duration(hours: ttlHours);

  bool isNear({
    required double latitude,
    required double longitude,
    required double cachedLatitude,
    required double cachedLongitude,
  }) =>
      Geo.distanceMeters(
        fromLatitude: latitude,
        fromLongitude: longitude,
        toLatitude: cachedLatitude,
        toLongitude: cachedLongitude,
      ) <=
      radiusMeters;

  /// The entry that may be reused for `(latitude, longitude)`, or `null`.
  ///
  /// [candidates] is whatever the nine cell keys returned; picking the nearest
  /// fresh one here (rather than at the call site) keeps the rule in one place.
  MosqueCacheEntry? best(
    List<MosqueCacheEntry> candidates, {
    required double latitude,
    required double longitude,
    required DateTime now,
  }) {
    MosqueCacheEntry? winner;
    double winnerDistance = double.infinity;

    for (final MosqueCacheEntry entry in candidates) {
      if (!isFresh(entry.fetchedAt, now)) continue;
      final double distance = Geo.distanceMeters(
        fromLatitude: latitude,
        fromLongitude: longitude,
        toLatitude: entry.latitude,
        toLongitude: entry.longitude,
      );
      if (distance > radiusMeters) continue;
      if (distance < winnerDistance) {
        winner = entry;
        winnerDistance = distance;
      }
    }
    return winner;
  }

  /// The nine cell keys around a point — the caller's `where cellKey in (...)`.
  List<String> candidateCellKeys(double latitude, double longitude) {
    const double step = 0.01; // one cell of the 2-decimal grid
    final List<String> keys = <String>[];
    for (int dLat = -1; dLat <= 1; dLat++) {
      for (int dLon = -1; dLon <= 1; dLon++) {
        keys.add(
          Geo.cellKey(latitude + dLat * step, longitude + dLon * step),
        );
      }
    }
    return keys;
  }
}

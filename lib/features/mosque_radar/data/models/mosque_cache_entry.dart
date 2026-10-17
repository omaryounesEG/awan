import 'package:isar/isar.dart';

part 'mosque_cache_entry.g.dart';

/// Cached nearby-mosque payload for one geographic cell.
///
/// Data model of `mosque_radar`: the radar never queries Google/OSM twice for
/// the same cell within 48h, which is what keeps the Places bill — and the
/// radio — quiet.
///
/// The cell is a ~1.1 km square (`lat:lon` at 2 decimals). [latitude] and
/// [longitude] hold the *exact* point the search was made from, because the
/// 500 m rule in `MosqueCachePolicy` is a distance test, not an equality test:
/// the cell only makes the lookup cheap.
@collection
class MosqueCacheEntry {
  Id id = Isar.autoIncrement;

  /// `lat2dp:lon2dp` cell key.
  @Index(unique: true, replace: true)
  late String cellKey;

  late DateTime fetchedAt;

  /// 'google' | 'osm'
  late String provider;

  /// The exact search point (for the 500 m freshness rule).
  late double latitude;

  late double longitude;

  /// JSON list of mosques exactly as the data source returned them.
  late String payload;
}

import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';

/// What the repository needs from local storage.
///
/// The repository takes this rather than the Isar class so its two contracts —
/// "seed only when the store is empty" and "one lookup by ayah id" — are testable
/// on the host, without a database or a plugin.
abstract class MutashabihatLocalSource {
  /// Rows currently stored.
  Future<int> count();

  /// The node whose id is the ayah id — a primary-key read, never a scan.
  Future<MutashabihNode?> nodeFor(int absoluteAyahId);

  /// How many edges are stored in total.
  ///
  /// The home card prints it, and on a warm database it is the one number the
  /// store does not hand over for free: `count()` answers the nodes, so the
  /// edges are summed from the rows once per session.
  Future<int> targetCount();

  /// Every ayah id that appears in the stored rows, sources and targets.
  Future<Set<int>> involvedIds();

  /// Reads the bundled corpus and writes it, reporting what it did.
  Future<({int nodes, int targets, Duration elapsed})> seedFromAsset();

  /// Drops every seeded row so a newer bundled corpus can replace the old one.
  ///
  /// Without this the seeding guard (`existing > 0`) would keep a phone on the
  /// first corpus it ever saw — a graph fix shipped in an update would never
  /// reach it.
  Future<void> clear();
}

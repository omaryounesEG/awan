import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';

/// Reading and filling the Mutashabihat graph.
abstract class MutashabihatRepository {
  /// Parses the bundled corpus into Isar — but only when the collection is
  /// empty, so it is safe to call on every screen open.
  Future<MutashabihatSeedReport> seedIfNeeded();

  /// The node for one ayah, or `null` when the corpus has nothing on it.
  ///
  /// A primary-key lookup: the ayah id *is* the Isar id, so this is O(1) and
  /// never scans the 1,298 rows.
  Future<MutashabihNodeEntry?> similaritiesFor(int absoluteAyahId);

  /// How many nodes are on the device (0 before the first seed).
  Future<int> indexedNodeCount();

  /// Every ayah id the corpus mentions — as a source, as a similar target, or
  /// both.
  ///
  /// The reader uses this to tint the verses that carry a similarity relation,
  /// so a reader can see where the graph has something to say without asking
  /// ayah by ayah.
  Future<Set<int>> involvedAyahIds();
}

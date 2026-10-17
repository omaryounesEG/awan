import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_local_source.dart';
import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/domain/repositories/mutashabihat_repository.dart';

/// Raised when the bundled corpus cannot be read or parsed.
class MutashabihatCorpusFailure implements Exception {
  const MutashabihatCorpusFailure(this.message);

  final String message;

  @override
  String toString() => 'MutashabihatCorpusFailure: $message';
}

/// Isar rows in, domain entities out.
class MutashabihatRepositoryImpl implements MutashabihatRepository {
  MutashabihatRepositoryImpl(this._local);

  final MutashabihatLocalSource _local;

  /// Bumped whenever the bundled corpus changes.
  ///
  /// The store's contents are not enough on their own: a phone that seeded the
  /// graph once would keep that corpus for good, so a corpus fix shipped in an
  /// update — a link dropped, a source cited — would never reach it. The version
  /// is what makes the bundled asset, not the first install, authoritative.
  static const int corpusVersion = 2;
  static const String _corpusVersionKey = 'mutashabihatCorpusVersion';

  @override
  Future<MutashabihatSeedReport> seedIfNeeded() async {
    // The guard the spec asks for: seeding is idempotent, so every screen may
    // call it without the second call paying for a 2.7 MB decode.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int existing = await _local.count();
    final bool current = prefs.getInt(_corpusVersionKey) == corpusVersion;
    if (existing > 0 && current) {
      return MutashabihatSeedReport.skipped(existing, await _local.targetCount());
    }
    if (existing > 0) {
      // An older corpus: replace it, never mix the two.
      await _local.clear();
    }

    try {
      final ({int nodes, int targets, Duration elapsed}) result = await _local.seedFromAsset();
      if (result.nodes == 0) {
        throw const MutashabihatCorpusFailure('corpus parsed to zero nodes');
      }
      assert(() {
        debugPrint(
          '[graph] seeded ${result.nodes} nodes / ${result.targets} links '
          'in ${result.elapsed.inMilliseconds} ms',
        );
        return true;
      }());
      await prefs.setInt(_corpusVersionKey, corpusVersion);
      return MutashabihatSeedReport(
        nodes: result.nodes,
        targets: result.targets,
        elapsed: result.elapsed,
        alreadySeeded: false,
      );
    } on MutashabihatCorpusFailure {
      rethrow;
    } catch (error) {
      throw MutashabihatCorpusFailure('could not seed the graph: $error');
    }
  }

  @override
  Future<MutashabihNodeEntry?> similaritiesFor(int absoluteAyahId) async {
    final MutashabihNode? row = await _local.nodeFor(absoluteAyahId);
    return row == null ? null : _toEntry(row);
  }

  @override
  Future<int> indexedNodeCount() => _local.count();

  @override
  Future<Set<int>> involvedAyahIds() => _local.involvedIds();

  static MutashabihNodeEntry _toEntry(MutashabihNode row) => MutashabihNodeEntry(
        sourceAbsoluteId: row.sourceAbsoluteId,
        sourceSurahNumber: row.sourceSurahNumber,
        sourceAyahNumber: row.sourceAyahNumber,
        sourceText: row.sourceText,
        targets: row.targets
            .map(
              (MutashabihTarget target) => MutashabihTargetEntry(
                targetAbsoluteId: target.targetAbsoluteId,
                targetSurahNumber: target.targetSurahNumber,
                targetAyahNumber: target.targetAyahNumber,
                targetText: target.targetText,
                ruleText: target.ruleText,
              ),
            )
            .toList(growable: false),
      );
}

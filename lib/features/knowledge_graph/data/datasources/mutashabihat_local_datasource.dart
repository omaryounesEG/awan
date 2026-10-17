import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_json_parser.dart';
import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_local_source.dart';
import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';

/// The Isar side of the graph: one collection, one asset, one lookup.
class MutashabihatLocalDataSource implements MutashabihatLocalSource {
  MutashabihatLocalDataSource(this._isar);

  final Isar _isar;

  IsarCollection<MutashabihNode> get _nodes => _isar.collection<MutashabihNode>();

  @override
  Future<int> count() => _nodes.count();

  /// One pass over the rows answers both of the numbers the UI asks for
  /// repeatedly (the edge total on the home card, the id set the reader tints
  /// with), so neither pays for a second scan in a session.
  List<MutashabihNode>? _cachedRows;

  Future<List<MutashabihNode>> _rows() async =>
      _cachedRows ??= await _nodes.where().findAll();

  @override
  Future<int> targetCount() async {
    final List<MutashabihNode> rows = await _rows();
    return rows.fold<int>(
      0,
      (int sum, MutashabihNode node) => sum + node.targets.length,
    );
  }

  @override
  Future<Set<int>> involvedIds() async {
    final List<MutashabihNode> rows = await _rows();
    final Set<int> ids = <int>{};
    for (final MutashabihNode node in rows) {
      ids.add(node.sourceAbsoluteId);
      for (final MutashabihTarget target in node.targets) {
        ids.add(target.targetAbsoluteId);
      }
    }
    return ids;
  }

  /// `get` on an Isar collection is a primary-key lookup, and the primary key of
  /// a node is its ayah id — so this is the O(1) the screen needs, on a
  /// collection of any size.
  @override
  Future<MutashabihNode?> nodeFor(int absoluteAyahId) => _nodes.get(absoluteAyahId);

  /// Reads the asset, parses it on a worker isolate and writes the rows.
  ///
  /// Returns how many nodes and targets landed, plus how long the whole thing
  /// took — a number the UI can show instead of a spinner that lies.
  @override
  Future<({int nodes, int targets, Duration elapsed})> seedFromAsset() async {
    final Stopwatch watch = Stopwatch()..start();

    final String raw = await rootBundle.loadString(AppConstants.mutashabihatAssetPath);

    // `compute` copies the result back across the isolate boundary, which for
    // 1,298 nodes is a few milliseconds of copying against a JSON decode that
    // would otherwise run on the frame budget.
    final List<MutashabihNode> rows = await compute(parseMutashabihatCorpus, raw);

    await _isar.writeTxn(() async {
      await _nodes.clear();
      await _nodes.putAll(rows);
    });
    _cachedRows = null;

    watch.stop();
    final int targets = rows.fold<int>(0, (int sum, MutashabihNode n) => sum + n.targets.length);
    return (nodes: rows.length, targets: targets, elapsed: watch.elapsed);
  }

  @override
  Future<void> clear() async {
    await _isar.writeTxn(() async {
      await _nodes.clear();
    });
    _cachedRows = null;
  }

  /// Whether the corpus asset is where the app expects it — used to tell "the
  /// graph is empty" apart from "the asset was not bundled".
  Future<bool> assetExists() async {
    try {
      await rootBundle.load(AppConstants.mutashabihatAssetPath);
      return true;
    } on FlutterError {
      return false;
    } catch (_) {
      return false;
    }
  }
}

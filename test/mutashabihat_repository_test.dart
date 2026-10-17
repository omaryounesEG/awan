import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_local_source.dart';
import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';
import 'package:awan/features/knowledge_graph/data/repositories/mutashabihat_repository_impl.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';

/// A stand-in for Isar that records how it was called.
///
/// The two things worth proving about the repository are not about storage:
/// that a second call does not re-parse a 2.7 MB corpus, and that a lookup goes
/// straight to one row by ayah id. Both are visible in the calls themselves.
class _FakeLocalSource implements MutashabihatLocalSource {
  _FakeLocalSource({this.rows, this.seedResult, this.seedThrows = false});

  final Map<int, MutashabihNode>? rows;
  final ({int nodes, int targets, Duration elapsed})? seedResult;
  final bool seedThrows;

  int seedCalls = 0;
  int clearCalls = 0;
  final List<int> lookups = <int>[];
  int countCalls = 0;

  @override
  Future<int> count() async {
    countCalls++;
    return rows?.length ?? 0;
  }

  @override
  Future<MutashabihNode?> nodeFor(int absoluteAyahId) async {
    lookups.add(absoluteAyahId);
    return rows?[absoluteAyahId];
  }

  @override
  Future<Set<int>> involvedIds() async => <int>{
        ...?rows?.keys,
        ...?rows?.values.expand(
          (MutashabihNode node) => node.targets.map((t) => t.targetAbsoluteId),
        ),
      };

  @override
  Future<int> targetCount() async => rows?.values
          .fold<int>(0, (int sum, MutashabihNode node) => sum + node.targets.length) ??
      0;

  @override
  Future<void> clear() async {
    clearCalls++;
    rows?.clear();
  }

  @override
  Future<({int nodes, int targets, Duration elapsed})> seedFromAsset() async {
    seedCalls++;
    if (seedThrows) {
      throw StateError('asset missing');
    }
    return seedResult ?? (nodes: 0, targets: 0, elapsed: Duration.zero);
  }
}

MutashabihNode _row() => MutashabihNode()
  ..sourceAbsoluteId = 9
  ..sourceSurahNumber = 2
  ..sourceAyahNumber = 2
  ..sourceText = 'ذَٰلِكَ ٱلْكِتَـٰبُ'
  ..targets = <MutashabihTarget>[
    MutashabihTarget()
      ..targetAbsoluteId = 183
      ..targetSurahNumber = 2
      ..targetAyahNumber = 176
      ..targetText = 'ذَٰلِكَ بِأَنَّ ٱللَّهَ'
      ..ruleText = 'موضع التشابه: ذلك',
  ];

void main() {
  // The repository remembers which corpus version it seeded, so every test needs
  // a preferences store — and one that starts empty unless the test says
  // otherwise.
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('seeds once and reports what it wrote', () async {
    final _FakeLocalSource local = _FakeLocalSource(
      seedResult: (nodes: 1298, targets: 3705, elapsed: const Duration(milliseconds: 420)),
    );
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    final MutashabihatSeedReport first = await repository.seedIfNeeded();

    expect(local.seedCalls, 1);
    expect(first.nodes, 1298);
    expect(first.targets, 3705);
    expect(first.alreadySeeded, isFalse);
  });

  test('a populated store is never re-parsed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mutashabihatCorpusVersion': MutashabihatRepositoryImpl.corpusVersion,
    });
    final _FakeLocalSource local = _FakeLocalSource(
      rows: <int, MutashabihNode>{9: _row()},
      seedResult: (nodes: 1298, targets: 3705, elapsed: Duration.zero),
    );
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    final MutashabihatSeedReport report = await repository.seedIfNeeded();

    expect(local.seedCalls, 0, reason: 'the 2.7 MB decode must not run a second time');
    expect(report.alreadySeeded, isTrue);
    expect(report.nodes, 1);
    expect(report.targets, 1, reason: 'the home card prints the edge count too');
  });

  test('a store seeded from an older corpus is replaced, not kept', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'mutashabihatCorpusVersion': MutashabihatRepositoryImpl.corpusVersion - 1,
    });
    final _FakeLocalSource local = _FakeLocalSource(
      rows: <int, MutashabihNode>{9: _row()},
      seedResult: (nodes: 1298, targets: 2803, elapsed: Duration.zero),
    );
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    final MutashabihatSeedReport report = await repository.seedIfNeeded();

    expect(local.clearCalls, 1, reason: 'the fix must reach a phone that seeded the old corpus');
    expect(local.seedCalls, 1);
    expect(report.nodes, 1298);
  });

  test('parsing to nothing is a failure, not an empty graph', () async {
    final _FakeLocalSource local = _FakeLocalSource(
      seedResult: (nodes: 0, targets: 0, elapsed: Duration.zero),
    );
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    expect(repository.seedIfNeeded(), throwsA(isA<MutashabihatCorpusFailure>()));
  });

  test('a storage error surfaces as a corpus failure', () async {
    final _FakeLocalSource local = _FakeLocalSource(seedThrows: true);
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    expect(repository.seedIfNeeded(), throwsA(isA<MutashabihatCorpusFailure>()));
  });

  test('lookup asks for exactly one ayah id and maps it to an entity', () async {
    final _FakeLocalSource local = _FakeLocalSource(rows: <int, MutashabihNode>{9: _row()});
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    final MutashabihNodeEntry? entry = await repository.similaritiesFor(9);

    expect(local.lookups, <int>[9]);
    expect(entry, isNotNull);
    expect(entry!.sourceSurahNumber, 2);
    expect(entry.targetCount, 1);
    expect(entry.targets.single.ruleText, 'موضع التشابه: ذلك');
  });

  test('an ayah the corpus never recorded is null, not an error', () async {
    final _FakeLocalSource local = _FakeLocalSource(rows: <int, MutashabihNode>{9: _row()});
    final MutashabihatRepositoryImpl repository = MutashabihatRepositoryImpl(local);

    expect(await repository.similaritiesFor(6000), isNull);
    expect(local.lookups, <int>[6000]);
  });
}

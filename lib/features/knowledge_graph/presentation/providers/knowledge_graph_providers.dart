import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/isar_service.dart';
import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_local_datasource.dart';
import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_local_source.dart';
import 'package:awan/features/knowledge_graph/data/datasources/kisai_layer_datasource.dart';
import 'package:awan/features/knowledge_graph/data/repositories/kisai_layer_repository_impl.dart';
import 'package:awan/features/knowledge_graph/data/repositories/mutashabihat_repository_impl.dart';
import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/domain/repositories/mutashabihat_repository.dart';

/// The graph's Isar access, over the one database the app opens.
final Provider<MutashabihatLocalSource> mutashabihatLocalDataSourceProvider =
    Provider<MutashabihatLocalSource>((Ref ref) {
  final IsarService isarService = ref.watch(isarServiceProvider);
  return MutashabihatLocalDataSource(isarService.isar);
});

final FutureProvider<MutashabihatRepository> mutashabihatRepositoryProvider =
    FutureProvider<MutashabihatRepository>((Ref ref) async {
  return MutashabihatRepositoryImpl(ref.watch(mutashabihatLocalDataSourceProvider));
});

/// Fills the graph from the bundled corpus — once per install.
///
/// Idempotent by construction (the repository checks the row count first), so
/// watching this is the cheap way for any screen to say "the corpus is ready"
/// without a second 2.7 MB decode.
final FutureProvider<MutashabihatSeedReport> mutashabihatSeedProvider =
    FutureProvider<MutashabihatSeedReport>((Ref ref) async {
  debugPrint('[graph] seeding the similarity corpus');
  try {
    final MutashabihatRepository repository =
        await ref.watch(mutashabihatRepositoryProvider.future);
    final MutashabihatSeedReport report = await repository.seedIfNeeded();
    // debugPrint, not the file probe: this line is development evidence and
    // release builds drop it (`print` never reached logcat on the emulators here).
    debugPrint('[graph] seed ok nodes=${report.nodes} links=${report.targets} '
        'already=${report.alreadySeeded} ms=${report.elapsed.inMilliseconds}');
    return report;
  } catch (error) {
    debugPrint('[graph] seed failed: $error');
    rethrow;
  }
});

/// الكسائي's documented verses — the layer over the graph.
///
/// Loaded from its own 26 KB asset rather than from Isar: it is a citation list
/// that never changes with the corpus, so there is nothing to seed.
final FutureProvider<KisaiLayer> kisaiLayerProvider = FutureProvider<KisaiLayer>(
  (Ref ref) => KisaiLayerRepositoryImpl(KisaiLayerDataSource()).layer(),
);

/// Every ayah id the corpus knows about — the reader tints those verses.
///
/// One scan of the rows per session, cached by the data source, and it waits for
/// the seed so a fresh install does not answer "no similarities anywhere".
final FutureProvider<Set<int>> mutashabihatInvolvedIdsProvider =
    FutureProvider<Set<int>>((Ref ref) async {
  await ref.watch(mutashabihatSeedProvider.future);
  final MutashabihatRepository repository =
      await ref.watch(mutashabihatRepositoryProvider.future);
  return repository.involvedAyahIds();
});

/// The graph for one ayah — a primary-key lookup, cached per ayah id.
final FutureProviderFamily<MutashabihNodeEntry?, int> similaritiesProvider =
    FutureProvider.family<MutashabihNodeEntry?, int>((Ref ref, int absoluteAyahId) async {
  // The corpus must exist before the lookup can mean anything: on a fresh
  // install the query would otherwise come back empty and the screen would
  // report "nothing recorded for this ayah" for an ayah it simply has not read
  // yet.
  await ref.watch(mutashabihatSeedProvider.future);

  final MutashabihatRepository repository =
      await ref.watch(mutashabihatRepositoryProvider.future);
  return repository.similaritiesFor(absoluteAyahId);
});

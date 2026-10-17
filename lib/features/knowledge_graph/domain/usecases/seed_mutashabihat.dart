import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/domain/repositories/mutashabihat_repository.dart';

/// Fills the graph database from the bundled corpus if it is empty.
class SeedMutashabihat {
  const SeedMutashabihat(this._repository);

  final MutashabihatRepository _repository;

  Future<MutashabihatSeedReport> call() => _repository.seedIfNeeded();
}

import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/domain/repositories/mutashabihat_repository.dart';

/// The graph for one ayah.
class GetSimilaritiesForAyah {
  const GetSimilaritiesForAyah(this._repository);

  final MutashabihatRepository _repository;

  Future<MutashabihNodeEntry?> call(int absoluteAyahId) =>
      _repository.similaritiesFor(absoluteAyahId);
}

import 'package:awan/features/knowledge_graph/data/datasources/kisai_layer_datasource.dart';
import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';
import 'package:awan/features/knowledge_graph/domain/repositories/kisai_layer_repository.dart';

class KisaiLayerRepositoryImpl implements KisaiLayerRepository {
  const KisaiLayerRepositoryImpl(this._source);

  final KisaiLayerDataSource _source;

  @override
  Future<KisaiLayer> layer() => _source.load();
}

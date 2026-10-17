import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';

/// الكسائي's documented verses, as a layer over the similarity graph.
abstract class KisaiLayerRepository {
  Future<KisaiLayer> layer();
}

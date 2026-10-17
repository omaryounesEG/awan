import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';

/// Reads الكسائي's list once per process.
///
/// The whole asset is 26 KB, so it is decoded where it is read — the 2.7 MB
/// corpus is the one that needs an isolate, not this.
class KisaiLayerDataSource {
  KisaiLayerDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  KisaiLayer? _cache;

  Future<KisaiLayer> load() async {
    final KisaiLayer? cached = _cache;
    if (cached != null) return cached;
    final String raw = await _bundle.loadString(AppConstants.kisaiLayerAsset);
    final KisaiLayer layer =
        KisaiLayer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache = layer;
    return layer;
  }
}

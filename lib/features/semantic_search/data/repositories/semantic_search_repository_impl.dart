import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/domain/repositories/quran_repository.dart';
import 'package:awan/features/semantic_search/data/datasources/embedding_encoder.dart';
import 'package:awan/features/semantic_search/data/datasources/semantic_index.dart';
import 'package:awan/features/semantic_search/data/datasources/sentencepiece_unigram.dart';
import 'package:awan/features/semantic_search/domain/entities/semantic_entities.dart';
import 'package:awan/features/semantic_search/domain/usecases/fuse_rankings.dart';

/// The offline search engine: words on one side, meaning on the other.
///
/// Nothing here touches the network. The only variable is the model file, which
/// the build either bundles or the app downloads once; when it is missing the
/// engine degrades to the lexical half instead of failing.
class SemanticSearchRepositoryImpl {
  SemanticSearchRepositoryImpl({
    required QuranRepository quran,
    EmbeddingEncoder encoder = const EmbeddingEncoder(),
    AssetBundle? bundle,
  })  : _quran = quran,
        _encoder = encoder,
        _bundle = bundle ?? rootBundle;

  static const String vectorAsset = 'assets/semantic/quran_vecs.i8';
  static const String scaleAsset = 'assets/semantic/quran_scales.f32';
  static const String manifestAsset = 'assets/semantic/quran_index.json';
  static const String tokenizerAsset = 'assets/semantic/tokenizer.json';

  final QuranRepository _quran;
  final EmbeddingEncoder _encoder;
  final AssetBundle _bundle;

  static const FuseRankings _fuse = FuseRankings();

  SemanticIndex? _index;
  SentencePieceUnigram? _tokenizer;
  QuranText? _text;
  bool _modelReady = false;
  String? _modelError;

  bool get isReady => _index != null && _tokenizer != null && _modelReady;

  /// Loads the index and the model once; safe to call on every search.
  Future<SemanticStatus> ensureReady() async {
    if (_index == null) {
      try {
        final ByteData vectors = await _bundle.load(vectorAsset);
        final ByteData scales = await _bundle.load(scaleAsset);
        final String manifest = await _bundle.loadString(manifestAsset);
        _index = SemanticIndex.fromBytes(
          vectors: vectors.buffer.asUint8List(),
          scales: scales.buffer.asUint8List(),
          manifestJson: manifest,
        );
      } catch (error) {
        _modelError = 'index: $error';
      }
    }
    if (_tokenizer == null) {
      try {
        _tokenizer = SentencePieceUnigram.fromJson(
          jsonDecode(await _bundle.loadString(tokenizerAsset))
              as Map<String, dynamic>,
        );
      } catch (error) {
        _modelError = 'tokenizer: $error';
      }
    }
    if (!_modelReady) {
      final ({bool ready, int bytes, String? error}) state =
          await _encoder.status();
      if (state.ready) {
        _modelReady = true;
      } else {
        final ({bool ready, int bytes, String? error}) prepared =
            await _encoder.prepare();
        _modelReady = prepared.ready;
        if (!prepared.ready) _modelError = prepared.error;
      }
    }

    return SemanticStatus(
      ready: isReady,
      indexLoaded: _index != null,
      modelBytes: 0,
      error: _modelError,
    );
  }

  /// Hybrid search: lexical hits and vector hits, fused by rank.
  Future<List<SemanticHit>> search(String query, {int limit = 30}) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return const <SemanticHit>[];

    final QuranText text = _text ??= await _quran.text();
    final List<QuranSearchHit> lexical =
        await _quran.search(trimmed, limit: limit * 2);

    List<ScoredRow> semanticRows = const <ScoredRow>[];
    final SemanticIndex? index = _index;
    final SentencePieceUnigram? tokenizer = _tokenizer;
    if (_modelReady && index != null && tokenizer != null) {
      // E5 is trained with asymmetric prefixes: passages carry "passage: " (in
      // the index) and questions carry "query: ". Dropping it costs about half
      // the retrieval quality.
      final ({List<int> ids, List<int> mask}) encoded =
          tokenizer.encodeForEncoder('query: ${normalizeArabic(trimmed)}');
      final Float64List? vector = await _encoder.encode(encoded.ids, encoded.mask);
      if (vector != null) {
        semanticRows = index.search(vector, limit: limit * 2);
      }
    }

    final List<String> semanticKeys = <String>[
      for (final ScoredRow row in semanticRows)
        '${index!.row(row.index).surah}:${index.row(row.index).ayah}',
    ];
    final List<String> lexicalKeys = <String>[
      for (final QuranSearchHit hit in lexical) '${hit.surah}:${hit.ayah}',
    ];

    final List<FusedKey> fused =
        _fuse(semanticKeys: semanticKeys, lexicalKeys: lexicalKeys, limit: limit);

    final Map<String, double> similarity = <String, double>{
      for (final ScoredRow row in semanticRows)
        '${index!.row(row.index).surah}:${index.row(row.index).ayah}': row.score,
    };

    return <SemanticHit>[
      for (final FusedKey key in fused)
        if (text.ayah(key.surah, key.ayah) != null)
          SemanticHit(
            surah: key.surah,
            ayah: key.ayah,
            surahName: text.surah(key.surah).nameAr,
            text: text.ayah(key.surah, key.ayah)!.text,
            score: key.score,
            lexicalRank: key.lexicalRank,
            semanticRank: key.semanticRank,
            similarity: similarity[key.key],
          ),
    ];
  }
}

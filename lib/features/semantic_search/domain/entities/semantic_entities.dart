import 'package:equatable/equatable.dart';

/// One verse, found either by its words or by its meaning.
///
/// The two ranks are kept instead of a single blended number: the UI shows
/// «مطابقة بالمعنى» only when the verse came from the vector half, and the same
/// verse can legitimately arrive from both.
class SemanticHit extends Equatable {
  const SemanticHit({
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.text,
    required this.score,
    this.lexicalRank,
    this.semanticRank,
    this.similarity,
  });

  final int surah;
  final int ayah;
  final String surahName;
  final String text;

  /// Reciprocal-rank-fusion score; only meaningful for ordering.
  final double score;

  /// 1-based rank in the lexical list, null when the words did not match.
  final int? lexicalRank;

  /// 1-based rank in the vector list, null when the meaning did not match.
  final int? semanticRank;

  /// Cosine similarity from the vector half, for the UI's confidence hint.
  final double? similarity;

  bool get matchedByMeaning => semanticRank != null;
  bool get matchedByWords => lexicalRank != null;

  String get key => '$surah:$ayah';

  @override
  List<Object?> get props =>
      <Object?>[surah, ayah, score, lexicalRank, semanticRank, similarity];
}

/// What the engine is currently able to do, surfaced so the screen can say
/// «البحث بالمعنى جاهز» instead of silently falling back to words.
class SemanticStatus extends Equatable {
  const SemanticStatus({
    required this.ready,
    required this.indexLoaded,
    this.modelBytes = 0,
    this.error,
  });

  const SemanticStatus.offline({this.error})
      : ready = false,
        indexLoaded = false,
        modelBytes = 0;

  final bool ready;
  final bool indexLoaded;
  final int modelBytes;
  final String? error;

  @override
  List<Object?> get props => <Object?>[ready, indexLoaded, modelBytes, error];
}

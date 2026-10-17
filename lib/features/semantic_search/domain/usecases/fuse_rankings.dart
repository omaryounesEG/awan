/// Reciprocal Rank Fusion over the two halves of the search.
///
/// Word matching and meaning matching rank differently and their raw scores are
/// not comparable — a substring hit has no score at all. RRF only looks at
/// *positions*, so both lists can be fused without pretending a cosine of 0.62
/// and a lexical hit at index 3 are the same kind of number.
///
///     score(verse) = Σ 1 / (k + rank)
///
/// `k = 60` is the value from the original TREC formulation: it flattens the very
/// top of each list so the second list still contributes.
class FuseRankings {
  const FuseRankings();

  static const int defaultK = 60;

  List<FusedKey> call({
    required List<String> semanticKeys,
    required List<String> lexicalKeys,
    int k = defaultK,
    int limit = 40,
  }) {
    final Map<String, FusedKey> fused = <String, FusedKey>{};

    for (int i = 0; i < semanticKeys.length; i++) {
      final String key = semanticKeys[i];
      final FusedKey? existing = fused[key];
      fused[key] = FusedKey(
        key: key,
        score: (existing?.score ?? 0) + 1 / (k + i + 1),
        semanticRank: i + 1,
        lexicalRank: existing?.lexicalRank,
      );
    }

    for (int i = 0; i < lexicalKeys.length; i++) {
      final String key = lexicalKeys[i];
      final FusedKey? existing = fused[key];
      fused[key] = FusedKey(
        key: key,
        score: (existing?.score ?? 0) + 1 / (k + i + 1),
        semanticRank: existing?.semanticRank,
        lexicalRank: i + 1,
      );
    }

    final List<FusedKey> ranked = fused.values.toList()
      ..sort((FusedKey a, FusedKey b) {
        final int byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        // Deterministic tie-break: mushaf order, which is also the order the
        // index was written in.
        return _compareKeys(a.key, b.key);
      });

    return ranked.length > limit ? ranked.sublist(0, limit) : ranked;
  }

  static int _compareKeys(String a, String b) {
    final List<String> left = a.split(':');
    final List<String> right = b.split(':');
    final int surah = int.parse(left.first).compareTo(int.parse(right.first));
    if (surah != 0) return surah;
    return int.parse(left.last).compareTo(int.parse(right.last));
  }
}

class FusedKey {
  const FusedKey({
    required this.key,
    required this.score,
    this.semanticRank,
    this.lexicalRank,
  });

  final String key;
  final double score;
  final int? semanticRank;
  final int? lexicalRank;

  int get surah => int.parse(key.split(':').first);
  int get ayah => int.parse(key.split(':').last);

  @override
  String toString() => '$key (${score.toStringAsFixed(4)})';
}

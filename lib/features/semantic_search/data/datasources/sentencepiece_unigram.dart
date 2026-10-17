import 'dart:convert';
import 'dart:math' as math;

/// SentencePiece **unigram** tokenizer, in Dart.
///
/// The query encoder is `paraphrase-multilingual-MiniLM-L12-v2`, whose tokenizer
/// is an XLM-R SentencePiece model — not WordPiece. There is no reliable Dart
/// binding for it, so the vocabulary and the per-piece log-probabilities are
/// exported once by `tools/semantic/build_index.py` and the Viterbi decode runs
/// here: same pieces, same scores, same segmentation as the Python side that
/// built the index.
///
/// The text is expected to be normalised already (see `normalizeArabic`): both
/// sides fold the input the same way, so a query tokenises exactly like the
/// verse it is looking for.
class SentencePieceUnigram {
  SentencePieceUnigram._({
    required this.unkId,
    required this.padId,
    required Map<String, int> pieces,
    required List<double> scores,
  })  : _pieces = pieces,
        _scores = scores,
        _minScore = scores.isEmpty
            ? -20.0
            : scores.reduce((double a, double b) => a < b ? a : b),
        _maxPieceLength = pieces.keys.fold<int>(1, (int longest, String piece) {
          final int length = piece.runes.length;
          return length > longest ? length : longest;
        });

  factory SentencePieceUnigram.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPieces = json['pieces'] as List<dynamic>;
    final List<dynamic> rawScores = json['scores'] as List<dynamic>;
    final Map<String, int> pieces = <String, int>{};
    final List<double> scores = List<double>.filled(rawPieces.length, 0);
    for (int i = 0; i < rawPieces.length; i++) {
      pieces[rawPieces[i] as String] = i;
      scores[i] = (rawScores[i] as num).toDouble();
    }
    return SentencePieceUnigram._(
      unkId: (json['unk_id'] as num?)?.toInt() ?? 3,
      padId: 1,
      pieces: pieces,
      scores: scores,
    );
  }

  static const String _space = '\u2581'; // ▁
  static const int _unknownPenalty = 10;

  final int unkId;
  final int padId;
  final Map<String, int> _pieces;
  final List<double> _scores;
  final double _minScore;
  final int _maxPieceLength;

  int get vocabularySize => _scores.length;

  /// Pieces for [text], without the leading `<s>` / trailing `</s>` — the
  /// exported graph does not use them and the mean-pooling ignores them anyway.
  List<int> encode(String text) {
    // SentencePiece marks a word boundary with U+2581, not with a space: the
    // vocabulary has «▁عند» and never « عند». Missing this makes every word
    // after the first one tokenise as unknown characters.
    final String normalised =
        text.replaceAll('\u2581', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final String padded = _space + normalised.replaceAll(' ', _space);

    final List<int> runes = padded.runes.toList();
    final int length = runes.length;
    if (length == 0) return const <int>[];

    final List<double> best = List<double>.filled(length + 1, double.negativeInfinity);
    final List<int> bestPiece = List<int>.filled(length + 1, -1);
    final List<int> bestLength = List<int>.filled(length + 1, 0);
    best[0] = 0;

    for (int i = 0; i < length; i++) {
      if (best[i] == double.negativeInfinity) continue;
      final int maxLength = math.min(_maxPieceLength, length - i);
      for (int span = 1; span <= maxLength; span++) {
        final String surface = String.fromCharCodes(runes.sublist(i, i + span));
        final int? id = _pieces[surface];
        double score;
        if (id != null) {
          score = _scores[id];
        } else if (span == 1) {
          // An unknown character still costs *something*; otherwise a string of
          // emoji would win the Viterbi by paying no score at all.
          score = _minScore - _unknownPenalty;
          final double candidate = best[i] + score;
          if (candidate > best[i + 1]) {
            best[i + 1] = candidate;
            bestPiece[i + 1] = unkId;
            bestLength[i + 1] = 1;
          }
          continue;
        } else {
          // A missing 2-character piece says nothing about the 3-character one,
          // so the scan must not stop here.
          continue;
        }
        final double candidate = best[i] + score;
        if (candidate > best[i + span]) {
          best[i + span] = candidate;
          bestPiece[i + span] = id;
          bestLength[i + span] = span;
        }
      }
    }

    final List<int> ids = <int>[];
    int cursor = length;
    while (cursor > 0) {
      final int span = bestLength[cursor];
      if (span == 0) break;
      ids.add(bestPiece[cursor]);
      cursor -= span;
    }
    return ids.reversed.toList(growable: false);
  }

  /// `[1, maxLength]` int64 ids and an attention mask, ready for the graph.
  ({List<int> ids, List<int> mask}) encodeForEncoder(String text, {int maxLength = 128}) {
    final List<int> pieces = encode(text);
    final int kept = pieces.length > maxLength - 1 ? maxLength - 1 : pieces.length;
    final List<int> ids = List<int>.filled(maxLength, padId);
    final List<int> mask = List<int>.filled(maxLength, 0);
    // `<s>` at the front keeps the sequence shape the model was trained on.
    ids[0] = 0;
    mask[0] = 1;
    for (int i = 0; i < kept; i++) {
      ids[i + 1] = pieces[i];
      mask[i + 1] = 1;
    }
    return (ids: ids, mask: mask);
  }
}

/// The vocabulary lives next to the vectors, as a plain JSON asset.
Future<SentencePieceUnigram> loadSentencePieceJson(
  Future<String> Function(String key) assetReader,
) async {
  final String raw = await assetReader('assets/semantic/tokenizer.json');
  return SentencePieceUnigram.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

import 'dart:math' as math;

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/quran_text.dart';

/// Compares what was heard with what the mushaf expects, and says which word
/// the reciter is on.
///
/// The recogniser never sees the mushaf, so its output is aligned to the verse
/// rather than compared index by index: a dropped word, a repeated word, or a
/// segment that begins mid-ayah must not shift every colour by one. The
/// alignment is a semi-global edit distance — skipping words of the verse
/// *before* the first match is free (the reciter may start anywhere), skipping
/// after it costs, and insertions are kept as "heard, not in the verse".
///
/// Pure Dart on purpose: the brain of the feature is testable with strings, and
/// a failing test here is a bug in the checker rather than in a microphone.
class AlignRecitation {
  const AlignRecitation({
    this.acceptSimilarity = 0.55,
    this.lookBehind = 2,
    this.gapPenalty = 0.55,
  });

  /// How close two skeletons must be before the word counts as *the same word*
  /// rather than a different one. Below this, a pairing is still recorded — that
  /// is how a wrong word gets named instead of silently skipped — but the
  /// verdict is [WordVerdict.word].
  final double acceptSimilarity;

  /// Below this, the two words are too different to be the same word at all;
  /// the expected word stays pending and the heard word becomes an extra.
  static const double floorSimilarity = 0.25;

  /// How far back the alignment may start, so repeating the previous word is
  /// not mistaken for a new one.
  final int lookBehind;

  final double gapPenalty;

  AyahAlignment call({
    required AyahAlignment session,
    required List<String> heard,
  }) {
    final List<String> tokens = heard
        .map((String w) => w.trim())
        .where((String w) => w.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return session;

    final int start = math.max(0, session.cursor - lookBehind);
    final List<RecitationWord> expected = session.words.sublist(start);
    if (expected.isEmpty) return session;

    final List<List<double>> score = List<List<double>>.generate(
      tokens.length + 1,
      (_) => List<double>.filled(expected.length + 1, 0),
      growable: false,
    );
    // Free to skip any number of expected words first: the reciter may open
    // the verse from anywhere, and that is not a mistake.
    for (int j = 0; j <= expected.length; j++) {
      score[0][j] = 0;
    }
    for (int i = 1; i <= tokens.length; i++) {
      score[i][0] = score[i - 1][0] - gapPenalty;
    }

    for (int i = 1; i <= tokens.length; i++) {
      final String heardSkeleton = QuranText.skeleton(tokens[i - 1]);
      for (int j = 1; j <= expected.length; j++) {
        final RecitationWord word = expected[j - 1];
        final double similarity = QuranText.similarity(heardSkeleton, word.consonants);
        final double pair = similarity >= acceptSimilarity
            ? 0.6 + 0.4 * similarity
            : -0.3;

        final double diagonal = score[i - 1][j - 1] + pair;
        final double up = score[i - 1][j] - gapPenalty; // heard, not expected
        final double left = score[i][j - 1] - (i == 1 ? 0 : gapPenalty);

        score[i][j] = math.max(diagonal, math.max(up, left));
      }
    }

    int bestColumn = 0;
    double bestScore = double.negativeInfinity;
    for (int j = 0; j <= expected.length; j++) {
      if (score[tokens.length][j] > bestScore) {
        bestScore = score[tokens.length][j];
        bestColumn = j;
      }
    }

    // Walk back: diagonal cells are pairs, "up" cells are words heard that the
    // verse does not contain, "left" cells are expected words not yet reached.
    final Map<int, int> matched = <int, int>{}; // expected index -> heard index
    final List<String> extras = <String>[];
    int i = tokens.length;
    int j = bestColumn;
    while (i > 0 && j > 0) {
      final double here = score[i][j];
      final double diagonal = score[i - 1][j - 1];
      final String heardSkeleton = QuranText.skeleton(tokens[i - 1]);
      final double similarity =
          QuranText.similarity(heardSkeleton, expected[j - 1].consonants);
      final double pair = similarity >= acceptSimilarity
          ? 0.6 + 0.4 * similarity
          : -0.3;

      if ((here - (diagonal + pair)).abs() < 1e-9) {
        // Record the pairing even when it is a bad one: a word said wrongly
        // must be reported, not mistaken for silence.
        if (similarity >= floorSimilarity) matched[j - 1] = i - 1;
        i--;
        j--;
      } else if ((here - (score[i - 1][j] - gapPenalty)).abs() < 1e-9) {
        extras.insert(0, tokens[i - 1]);
        i--;
      } else {
        j--;
      }
    }
    while (i > 0) {
      extras.insert(0, tokens[i - 1]);
      i--;
    }

    final List<RecitationWord> updated = List<RecitationWord>.of(session.words);
    int lastMatched = -1;

    matched.forEach((int expectedIndex, int heardIndex) {
      final int absolute = start + expectedIndex;
      final RecitationWord word = updated[absolute];
      final String spoken = tokens[heardIndex];
      final String heardSkeleton = QuranText.skeleton(spoken);
      // A reciter joining an ayah to the one before it says «و…», and a segment
      // that begins at a seam can start mid-word. Both are the same word for
      // the purposes of *which* word was said; the vowel check still runs.
      final bool sameLetters = heardSkeleton == word.consonants ||
          heardSkeleton == 'و${word.consonants}' ||
          heardSkeleton == 'ف${word.consonants}';

      if (!sameLetters) {
        if (kRecitationDebug) {
          // ignore: avoid_print
          print('[AwanRecitation] word error: expected=${word.consonants} '
              'heard=$heardSkeleton raw=$spoken');
        }
        updated[absolute] = word.copyWith(
          verdict: WordVerdict.word,
          spoken: spoken,
          timesWrong: word.timesWrong + 1,
        );
      } else {
        final _MarkDiff? diff = _compareMarks(word, spoken);
        updated[absolute] = word.copyWith(
          verdict: diff == null ? WordVerdict.correct : WordVerdict.diacritic,
          spoken: spoken,
          markLetter: diff?.letter,
          expectedMark: diff?.expected,
          heardMark: diff?.heard,
          timesWrong: diff == null ? 0 : word.timesWrong + 1,
        );
      }
      if (absolute > lastMatched) lastMatched = absolute;
    });

    // The cursor only moves forward: repeating a word to fix it must not send
    // the highlight back to where the reciter already was.
    final int cursor = math.max(session.cursor, lastMatched + 1);

    return AyahAlignment(
      surah: session.surah,
      ayah: session.ayah,
      words: updated,
      cursor: cursor.clamp(0, updated.length),
      extras: <String>[...session.extras, ...extras],
    );
  }

  /// Finds the first letter whose vowel disagrees, ignoring letters the
  /// recogniser left bare (a missing mark is not a wrong mark) and ignoring the
  /// dagger alef, which recognisers never emit.
  _MarkDiff? _compareMarks(RecitationWord word, String spoken) {
    if (!QuranText.hasVowels(spoken)) return null;

    final List<String> heardMarks = QuranText.marks(spoken);
    final int limit = math.min(heardMarks.length, word.marks.length);
    for (int i = 0; i < limit; i++) {
      final String expected = _normaliseMark(word.marks[i]);
      final String heard = _normaliseMark(heardMarks[i]);
      if (heard.isEmpty || expected.isEmpty) continue;
      if (expected != heard) {
        return _MarkDiff(i, expected, heard);
      }
    }
    return null;
  }

  /// Fatha/damma/kasra are what matter; a shadda written before or after the
  /// vowel is the same sound, and a dagger alef is silence in the comparison.
  String _normaliseMark(String mark) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in mark.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == 'A' || ch == '^') continue;
      buffer.write(ch);
    }
    final String cleaned = buffer.toString();
    // Long vowels spelled with a following letter are already in the skeleton.
    return cleaned;
  }
}

/// Turned on with `--dart-define=AWAN_RECITATION_DEBUG=true`: prints the exact
/// pair the checker compared, which is the fastest way to tell a modelling
/// mistake from a checking mistake on a device.
const bool kRecitationDebug = bool.fromEnvironment('AWAN_RECITATION_DEBUG');

class _MarkDiff {
  const _MarkDiff(this.letter, this.expected, this.heard);
  final int letter;
  final String expected;
  final String heard;
}

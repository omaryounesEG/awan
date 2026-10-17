import 'package:equatable/equatable.dart';

/// What the checker thinks of one word of the ayah being recited.
///
/// The three states come straight from the architecture note: a word can be
/// *right*, *right but mis-vocalised*, or *not the word at all*. They are not
/// cosmetic — each one drives a different reaction, because "you said a
/// different word" and "you said the right word with the wrong vowel" are
/// different mistakes and deserve different advice.
enum WordVerdict {
  /// The reciter has not reached this word yet.
  pending,

  /// Letters and vowel marks both match the mushaf.
  correct,

  /// The consonants match but a vowel mark does not — the classic i'rab slip.
  diacritic,

  /// A different word was heard where this one was expected.
  word,
}

/// One word of an ayah, as the mushaf writes it and as the checker sees it.
class RecitationWord extends Equatable {
  const RecitationWord({
    required this.index,
    required this.uthmani,
    required this.consonants,
    required this.marks,
    this.verdict = WordVerdict.pending,
    this.spoken,
    this.markLetter,
    this.expectedMark,
    this.heardMark,
    this.timesWrong = 0,
  });

  /// Zero-based position inside the ayah.
  final int index;

  /// The word exactly as the mushaf prints it, diacritics and all.
  final String uthmani;

  /// The word with the marks stripped and the letters folded — what a speech
  /// recogniser *can* be compared against.
  final String consonants;

  /// One entry per consonant: the vowel mark that belongs to that letter,
  /// written as a stable key (`a`, `u`, `i`, `0` for sukun, `~a` for a doubled
  /// fatha, `A` for the dagger alef). Empty means the letter carries nothing.
  final List<String> marks;

  final WordVerdict verdict;

  /// What the recogniser actually heard, for the honest "you said" line.
  final String? spoken;

  /// Which letter of this word carries the wrong mark (when [verdict] is
  /// [WordVerdict.diacritic]).
  final int? markLetter;
  final String? expectedMark;
  final String? heardMark;

  /// How many times this word has already been flagged this session — the
  /// third time is when the app stops nagging and offers the word aloud.
  final int timesWrong;

  bool get isWrong =>
      verdict == WordVerdict.word || verdict == WordVerdict.diacritic;

  RecitationWord copyWith({
    WordVerdict? verdict,
    String? spoken,
    int? markLetter,
    String? expectedMark,
    String? heardMark,
    int? timesWrong,
  }) {
    return RecitationWord(
      index: index,
      uthmani: uthmani,
      consonants: consonants,
      marks: marks,
      verdict: verdict ?? this.verdict,
      spoken: spoken ?? this.spoken,
      markLetter: markLetter ?? this.markLetter,
      expectedMark: expectedMark ?? this.expectedMark,
      heardMark: heardMark ?? this.heardMark,
      timesWrong: timesWrong ?? this.timesWrong,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        index,
        uthmani,
        consonants,
        marks,
        verdict,
        spoken,
        markLetter,
        expectedMark,
        heardMark,
        timesWrong,
      ];
}

/// The state of one ayah while it is being recited.
class AyahAlignment extends Equatable {
  const AyahAlignment({
    required this.surah,
    required this.ayah,
    required this.words,
    this.cursor = 0,
    this.extras = const <String>[],
  });

  final int surah;
  final int ayah;
  final List<RecitationWord> words;

  /// The word the reciter should be saying next — the app keeps this, not the
  /// recogniser, so a dropped segment never rewinds the session.
  final int cursor;

  /// Words heard that match nothing in the ayah (a mistake, a cough, a
  /// repetition). Kept for the "what was heard" panel, never coloured.
  final List<String> extras;

  bool get isComplete => cursor >= words.length;

  int get wrongCount => words.where((RecitationWord w) => w.isWrong).length;

  RecitationWord? get currentWord =>
      cursor < words.length ? words[cursor] : null;

  AyahAlignment copyWith({
    List<RecitationWord>? words,
    int? cursor,
    List<String>? extras,
  }) {
    return AyahAlignment(
      surah: surah,
      ayah: ayah,
      words: words ?? this.words,
      cursor: cursor ?? this.cursor,
      extras: extras ?? this.extras,
    );
  }

  @override
  List<Object?> get props => <Object?>[surah, ayah, words, cursor, extras];
}

/// A finished audio segment, ready for the recogniser.
class SpeechSegment {
  const SpeechSegment({
    required this.samples,
    required this.startedAt,
    required this.endedAt,
  });

  /// 16 kHz mono, float32 in [-1, 1] — exactly what Whisper was trained on.
  final List<double> samples;
  final Duration startedAt;
  final Duration endedAt;

  double get seconds => samples.length / 16000.0;
}

/// A recognised transcript, with the timing the UI needs to feel live.
class RecitationHypothesis extends Equatable {
  const RecitationHypothesis({
    required this.text,
    required this.words,
    required this.segment,
    required this.latency,
  });

  /// The raw text as the recogniser wrote it (Uthmani, with marks).
  final String text;

  /// The same text split into words, trimmed and non-empty.
  final List<String> words;

  final SpeechSegment segment;

  /// How long the whole segment took, from last sample to hypothesis. Shown in
  /// the debug strip and asserted in the performance test.
  final Duration latency;

  @override
  List<Object?> get props => <Object?>[text, words, latency];
}

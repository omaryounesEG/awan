import 'package:flutter/foundation.dart';

/// What the reader is measuring.
///
/// The unit is deliberately explicit: «عدد الحروف» and «عدد الكلمات» are
/// different answers to what sounds like the same question, and a lab that
/// guesses is a lab nobody trusts.
enum MidadUnit { letter, word, ayahLength, fasila }

/// Where the measurement happens — the whole mushaf or a slice of it.
enum MidadScope { mushaf, surah, juz, page, hizb, meccan, medinan }

/// One count request: scope + unit + probe + the two conventions that change
/// every number on the screen.
@immutable
class MidadQuery {
  const MidadQuery({
    this.scope = MidadScope.mushaf,
    this.scopeValue,
    this.unit = MidadUnit.letter,
    this.probe = 'ا',
    this.includeBasmala = false,
    this.simpleScript = true,
    this.wordInside = false,
  });

  final MidadScope scope;

  /// Surah number, juz, page or hizb — ignored for [MidadScope.mushaf],
  /// [MidadScope.meccan] and [MidadScope.medinan].
  final int? scopeValue;

  final MidadUnit unit;

  /// A letter, a word, or the rhyme letter of the verse — depends on [unit].
  final String probe;

  /// Whether the basmala of the 112 surahs that open with one is counted.
  /// It is never an ayah there, so it adds letters and words but not verses.
  final bool includeBasmala;

  /// Fold `ٱ أ إ آ` into a bare alef. Off means "as the mushaf writes it".
  final bool simpleScript;

  /// Count a word inside longer words too. «الله» alone is 2,153 tokens; with
  /// «والله» and «بالله» it is far more — and the famous figure for the divine
  /// name adds «لله» as well. The mode is the reader's call, not ours.
  final bool wordInside;

  MidadQuery copyWith({
    MidadScope? scope,
    int? scopeValue,
    bool clearScopeValue = false,
    MidadUnit? unit,
    String? probe,
    bool? includeBasmala,
    bool? simpleScript,
    bool? wordInside,
  }) =>
      MidadQuery(
        scope: scope ?? this.scope,
        scopeValue:
            clearScopeValue ? null : (scopeValue ?? this.scopeValue),
        unit: unit ?? this.unit,
        probe: probe ?? this.probe,
        includeBasmala: includeBasmala ?? this.includeBasmala,
        simpleScript: simpleScript ?? this.simpleScript,
        wordInside: wordInside ?? this.wordInside,
      );
}

/// One verse, already prepared for counting.
///
/// Two normalised forms are kept because the convention is a filter, not a
/// rebuild: [plain] preserves the written letters, [simple] folds the alef
/// family. Both have their diacritics and pause marks removed.
class MidadAyah {
  const MidadAyah({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.meccan,
    required this.plain,
    required this.simple,
  });

  final int surah;
  final int ayah;
  final int page;
  final int juz;
  final int hizb;
  final bool meccan;
  final String plain;
  final String simple;

  String get key => '$surah:$ayah';

  String letters(bool simpleScript) => simpleScript ? simple : plain;
}

/// A verse that matched, for the "where is it concentrated" list.
@immutable
class MidadVerseHit {
  const MidadVerseHit({
    required this.surah,
    required this.ayah,
    required this.count,
    required this.text,
  });

  final int surah;
  final int ayah;
  final int count;
  final String text;
}

/// The answer to one [MidadQuery].
@immutable
class MidadResult {
  const MidadResult({
    required this.total,
    required this.letters,
    required this.words,
    required this.ayahs,
    required this.bySurah,
    required this.top,
    this.averageLength = 0,
    this.longest,
    this.shortest,
  });

  /// The headline number, in the unit that was asked for.
  final int total;

  /// Denominators for the same scope, so a ratio is never invented.
  final int letters;
  final int words;
  final int ayahs;

  /// Per-surah counts — the heat map, and the tappable drill-down.
  final Map<int, int> bySurah;
  final List<MidadVerseHit> top;

  /// Only meaningful for [MidadUnit.ayahLength].
  final double averageLength;
  final MidadVerseHit? longest;
  final MidadVerseHit? shortest;

  double get shareOfLetters => letters == 0 ? 0 : total / letters;
}

/// Facts that hold for the whole mushaf and are computed once.
@immutable
class MidadInsights {
  const MidadInsights({
    required this.totalLetters,
    required this.totalWords,
    required this.topLetter,
    required this.topLetterCount,
    required this.hapaxWords,
    required this.hapaxSamples,
    required this.rarestLetter,
    required this.rarestLetterSurahs,
    required this.longestAyah,
    required this.shortestAyah,
  });

  final int totalLetters;
  final int totalWords;
  final String topLetter;
  final int topLetterCount;

  /// Words that occur exactly once in the whole mushaf.
  final int hapaxWords;
  final List<String> hapaxSamples;

  /// The letter that appears in the fewest surahs.
  final String rarestLetter;
  final int rarestLetterSurahs;

  final MidadVerseHit longestAyah;
  final MidadVerseHit shortestAyah;
}

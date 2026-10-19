import 'dart:isolate';

import 'package:awan/features/midad/domain/entities/midad_entities.dart';

/// Counting the Qur'an is a matter of convention before it is a matter of code:
/// the letter count changes with the script, the basmala, and how the hamza is
/// written. This file makes every convention an explicit, visible choice and
/// then keeps the arithmetic boring.
///
/// Everything here is pure and isolate-safe: the index is built once off the UI
/// thread, and a query is a single pass over 6 236 short strings.

/// Marks that are not letters: harakat, tanween, shadda, sukun, the small high
/// signs, the waqf (pause) marks, and tatweel.
final RegExp _marks = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640\u08F0-\u08FF]',
);

/// Anything that is not an Arabic letter becomes a word separator.
final RegExp _notLetter = RegExp(
  '[^\u0621-\u063A\u0641-\u064A\u0671-\u06D3\u06D5]',
);

final RegExp _alefFamily = RegExp('[\u0623\u0625\u0622\u0671]');
final RegExp _spaces = RegExp(' +');

/// The written letters, with words still separated by one space.
String midadNormalise(String raw) {
  final String withoutMarks = raw.replaceAll(_marks, '');
  final String letters = withoutMarks.replaceAll(_notLetter, ' ');
  return letters.replaceAll(_spaces, ' ').trim();
}

/// The simplified script folds the alef family into a bare alef.
String midadSimplify(String plain) => plain.replaceAll(_alefFamily, '\u0627');

const String _alef = '\u0627';

/// A single letter or word, normalised the same way as the text it is compared
/// against — otherwise «أ» never matches «ا» and the reader sees zero.
String midadNormaliseProbe(String probe, {required bool simpleScript}) {
  final String plain = midadNormalise(probe).replaceAll(' ', '');
  return simpleScript ? midadSimplify(plain) : plain;
}

int _lettersIn(String text) {
  int n = 0;
  for (int i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) != 0x20) n++;
  }
  return n;
}

/// The index: every verse prepared once, plus the facts that hold for the whole
/// mushaf (those never depend on the query).
class MidadIndex {
  MidadIndex({
    required this.ayahs,
    required this.insights,
    required this.byId,
    required this.byKey,
    required this.basmalaPlain,
    required this.basmalaSimple,
  });

  final List<MidadAyah> ayahs;
  final MidadInsights insights;
  final Map<int, MidadAyah> byId;

  /// Al-Fatihah 1 — the text of the basmala as the mushaf writes it, kept so
  /// the «عدّ البسملة» switch counts the real thing and not an estimate.
  final String basmalaPlain;
  final String basmalaSimple;

  /// `surah:ayah` → verse, so a heat-map tap can open the exact place.
  final Map<String, MidadAyah> byKey;
}

/// Input for the isolate. Plain maps only: no Flutter types cross the boundary.
Map<String, Object?> midadPayload({
  required Map<int, List<String>> ayahs,
  required Map<int, List<List<int>>> positions,
  required Set<int> meccan,
}) =>
    <String, Object?>{
      'ayahs': ayahs,
      'positions': positions,
      'meccan': meccan.toList(),
    };

/// Builds the index away from the frame budget (~1.6 M characters to normalise).
Future<MidadIndex> buildMidadIndexAsync(Map<String, Object?> payload) =>
    Isolate.run(() => buildMidadIndex(payload));

/// Synchronous builder — also the body of the isolate.
MidadIndex buildMidadIndex(Map<String, Object?> payload) {
  final Map<dynamic, dynamic> ayahs = payload['ayahs']! as Map<dynamic, dynamic>;
  final Map<dynamic, dynamic> positions =
      payload['positions']! as Map<dynamic, dynamic>;
  final Set<int> meccan = (payload['meccan']! as List<dynamic>).cast<int>().toSet();

  final List<MidadAyah> verses = <MidadAyah>[];
  final Map<String, MidadAyah> byKey = <String, MidadAyah>{};
  final Map<String, int> wordFrequency = <String, int>{};
  final Map<int, int> letterFrequency = <int, int>{};
  final Map<int, Set<int>> letterSurahs = <int, Set<int>>{};

  (MidadVerseHit?, MidadVerseHit?) longestShortest(
    MidadVerseHit? longest,
    MidadVerseHit? shortest,
    MidadVerseHit candidate,
  ) {
    final MidadVerseHit l =
        longest == null || candidate.count > longest.count ? candidate : longest;
    final MidadVerseHit s =
        shortest == null || candidate.count < shortest.count ? candidate : shortest;
    return (l, s);
  }

  int totalLetters = 0;
  int totalWords = 0;
  MidadVerseHit? longest;
  MidadVerseHit? shortest;

  for (final dynamic surahKey in ayahs.keys) {
    final int surah = surahKey as int;
    final List<String> texts = (ayahs[surahKey]! as List<dynamic>).cast<String>();
    final List<dynamic> pos =
        (positions[surahKey] as List<dynamic>?) ?? const <dynamic>[];
    final bool isMeccan = meccan.contains(surah);

    final Set<int> seenLetters = letterSurahs.putIfAbsent(surah, () => <int>{});

    for (int i = 0; i < texts.length; i++) {
      final String plain = midadNormalise(texts[i]);
      if (plain.isEmpty) continue;
      final List<int> p = i < pos.length
          ? (pos[i] as List<dynamic>).cast<int>()
          : const <int>[0, 0, 0, 0];
      final MidadAyah ayah = MidadAyah(
        surah: surah,
        ayah: i + 1,
        page: p.isNotEmpty ? p[0] : 0,
        juz: p.length > 1 ? p[1] : 0,
        hizb: p.length > 2 ? p[2] : 0,
        meccan: isMeccan,
        plain: plain,
        simple: midadSimplify(plain),
      );
      verses.add(ayah);
      byKey[ayah.key] = ayah;

      final int letters = _lettersIn(plain);
      totalLetters += letters;
      final MidadVerseHit hit = MidadVerseHit(
        surah: surah,
        ayah: ayah.ayah,
        count: letters,
        text: plain,
      );
      final (MidadVerseHit?, MidadVerseHit?) bounds =
          longestShortest(longest, shortest, hit);
      longest = bounds.$1;
      shortest = bounds.$2;

      // Letter presence per surah — answered from the simplified form so the
      // alef family is one letter, which is what a reader means by «الألف».
      for (final int unit in ayah.simple.runes) {
        if (unit == 0x20) continue;
        seenLetters.add(unit);
        letterFrequency[unit] = (letterFrequency[unit] ?? 0) + 1;
      }

      for (final String word in plain.split(' ')) {
        if (word.isEmpty) continue;
        totalWords++;
        final String key = midadSimplify(word);
        wordFrequency[key] = (wordFrequency[key] ?? 0) + 1;
      }
    }
  }

  if (verses.isEmpty) {
    throw StateError('the Qur\u2019an text did not load');
  }

  // Most frequent letter overall.
  int bestUnit = _alef.codeUnitAt(0);
  int bestCount = 0;
  letterFrequency.forEach((int unit, int count) {
    if (count > bestCount) {
      bestCount = count;
      bestUnit = unit;
    }
  });

  // The letter spread over the fewest surahs — a fact, not a claim.
  int rarestUnit = bestUnit;
  int rarestSurahs = 114;
  for (final int unit in letterFrequency.keys) {
    int count = 0;
    for (final Set<int> set in letterSurahs.values) {
      if (set.contains(unit)) count++;
    }
    if (count < rarestSurahs) {
      rarestSurahs = count;
      rarestUnit = unit;
    }
  }

  final List<MapEntry<String, int>> hapax = wordFrequency.entries
      .where((MapEntry<String, int> e) => e.value == 1)
      .toList(growable: false);

  final MidadAyah? fatiha = byKey['1:1'];

  return MidadIndex(
    ayahs: verses,
    basmalaPlain: fatiha?.plain ?? '',
    basmalaSimple: fatiha?.simple ?? '',
    byId: <int, MidadAyah>{
      for (final MidadAyah a in verses) a.surah * 1000 + a.ayah: a,
    },
    byKey: byKey,
    insights: MidadInsights(
      totalLetters: totalLetters,
      totalWords: totalWords,
      topLetter: String.fromCharCode(bestUnit),
      topLetterCount: bestCount,
      hapaxWords: hapax.length,
      hapaxSamples: hapax
          .take(3)
          .map((MapEntry<String, int> e) => e.key)
          .toList(growable: false),
      rarestLetter: String.fromCharCode(rarestUnit),
      rarestLetterSurahs: rarestSurahs,
      longestAyah: longest!,
      shortestAyah: shortest!,
    ),
  );
}

bool _inScope(MidadAyah a, MidadQuery q) {
  switch (q.scope) {
    case MidadScope.mushaf:
      return true;
    case MidadScope.surah:
      return q.scopeValue == null || a.surah == q.scopeValue;
    case MidadScope.juz:
      return q.scopeValue == null || a.juz == q.scopeValue;
    case MidadScope.page:
      return q.scopeValue == null || a.page == q.scopeValue;
    case MidadScope.hizb:
      return q.scopeValue == null || a.hizb == q.scopeValue;
    case MidadScope.meccan:
      return a.meccan;
    case MidadScope.medinan:
      return !a.meccan;
  }
}

/// Runs one query. Every number it returns is derived from [index] alone, so
/// two readers with the same settings cannot get two different answers.
MidadResult runMidadQuery(MidadIndex index, MidadQuery query) {
  final bool simple = query.simpleScript;
  final String probe = midadNormaliseProbe(query.probe, simpleScript: simple);

  final Map<int, int> bySurah = <int, int>{};
  int total = 0;
  int letters = 0;
  int wordCount = 0;
  int ayahCount = 0;
  double lengthSum = 0;
  final List<MidadVerseHit> hits = <MidadVerseHit>[];
  final Set<int> surahsInScope = <int>{};
  MidadVerseHit? longest;
  MidadVerseHit? shortest;

  // An empty probe is a question without a subject: zeros, not a crash.
  final bool askable = probe.isNotEmpty;

  for (final MidadAyah ayah in index.ayahs) {
    if (!_inScope(ayah, query)) continue;
    final String text = ayah.letters(simple);
    if (text.isEmpty) continue;
    ayahCount++;
    surahsInScope.add(ayah.surah);

    final List<String> tokens = text.split(' ');
    wordCount += tokens.where((String t) => t.isNotEmpty).length;

    int lettersHere = 0;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) != 0x20) lettersHere++;
    }
    letters += lettersHere;
    lengthSum += lettersHere;

    if (query.unit == MidadUnit.ayahLength) {
      bySurah[ayah.surah] = (bySurah[ayah.surah] ?? 0) + lettersHere;
      if (longest == null || lettersHere > longest.count) {
        longest = MidadVerseHit(
          surah: ayah.surah,
          ayah: ayah.ayah,
          count: lettersHere,
          text: text,
        );
      }
      if (shortest == null || lettersHere < shortest.count) {
        shortest = MidadVerseHit(
          surah: ayah.surah,
          ayah: ayah.ayah,
          count: lettersHere,
          text: text,
        );
      }
      continue;
    }

    if (query.unit == MidadUnit.fasila) {
      // The rhyme letter is the last written letter of the verse.
      if (askable && text.endsWith(probe)) {
        total++;
        bySurah[ayah.surah] = (bySurah[ayah.surah] ?? 0) + 1;
      }
      continue;
    }

    int here = 0;
    if (askable && query.unit == MidadUnit.letter) {
      for (int i = 0; i < text.length; i++) {
        if (text.codeUnitAt(i) == probe.codeUnitAt(0)) here++;
      }
    } else if (askable && query.wordInside) {
      // Inside mode: «الله» also lives inside «والله» and «بالله». Counting it
      // is legitimate; hiding which rule was used is not.
      for (final String token in tokens) {
        int at = token.indexOf(probe);
        while (at >= 0) {
          here++;
          at = token.indexOf(probe, at + probe.length);
        }
      }
    } else if (askable) {
      // Whole-token mode — «الله» is not counted inside «بالله».
      for (final String token in tokens) {
        if (token == probe) here++;
      }
    }

    total += here;
    if (here == 0) continue;
    bySurah[ayah.surah] = (bySurah[ayah.surah] ?? 0) + here;
    hits.add(MidadVerseHit(
      surah: ayah.surah,
      ayah: ayah.ayah,
      count: here,
      text: text,
    ));
  }

  // The basmala is not a verse outside Al-Fatihah, so the switch adds letters
  // and words (and the share they create) but never a verse.
  if (query.includeBasmala &&
      (query.unit == MidadUnit.letter || query.unit == MidadUnit.word)) {
    final String basmala = simple ? index.basmalaSimple : index.basmalaPlain;
    if (basmala.isNotEmpty) {
      int openings = 0;
      for (final int surah in surahsInScope) {
        if (surah != 1 && surah != 9) openings++;
      }
      if (openings > 0) {
        final List<String> tokens = basmala.split(' ');
        letters += _lettersIn(basmala) * openings;
        wordCount += tokens.length * openings;
        int perOpening = 0;
        if (askable) {
          if (query.unit == MidadUnit.letter) {
            for (int i = 0; i < basmala.length; i++) {
              if (basmala.codeUnitAt(i) == probe.codeUnitAt(0)) perOpening++;
            }
          } else if (query.wordInside) {
            for (final String token in tokens) {
              int at = token.indexOf(probe);
              while (at >= 0) {
                perOpening++;
                at = token.indexOf(probe, at + probe.length);
              }
            }
          } else {
            for (final String token in tokens) {
              if (token == probe) perOpening++;
            }
          }
        }
        total += perOpening * openings;
        if (perOpening > 0) {
          for (final int surah in surahsInScope) {
            if (surah == 1 || surah == 9) continue;
            bySurah[surah] = (bySurah[surah] ?? 0) + perOpening;
          }
        }
      }
    }
  }

  hits.sort((MidadVerseHit a, MidadVerseHit b) => b.count.compareTo(a.count));

  return MidadResult(
    total: query.unit == MidadUnit.ayahLength ? letters : total,
    letters: letters,
    words: wordCount,
    ayahs: ayahCount,
    bySurah: bySurah,
    top: query.unit == MidadUnit.fasila
        ? const <MidadVerseHit>[]
        : hits.take(5).toList(growable: false),
    averageLength: ayahCount == 0 ? 0 : lengthSum / ayahCount,
    longest: query.unit == MidadUnit.ayahLength ? longest : null,
    shortest: query.unit == MidadUnit.ayahLength ? shortest : null,
  );
}

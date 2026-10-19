import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/midad/data/midad_engine.dart';
import 'package:awan/features/midad/domain/entities/midad_entities.dart';

/// The lab is only worth trusting if its arithmetic is checkable. These tests
/// pin the count on a known, tiny mushaf, and pin the conventions that change
/// the answer — script, basmala, and where a verse ends.
void main() {
  Map<String, Object?> payload() => <String, Object?>{
        'ayahs': <int, List<String>>{
          1: <String>[
            '\u0628\u0650\u0633\u0652\u0645\u0650 \u0671\u0644\u0644\u064e\u0651\u0647\u0650 \u0671\u0644\u0631\u064e\u0651\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0671\u0644\u0631\u064e\u0651\u062d\u0650\u064a\u0645\u0650',
            '\u0671\u0644\u0652\u062d\u064e\u0645\u0652\u062f\u064f \u0644\u0650\u0644\u064e\u0651\u0647\u0650 \u0631\u064e\u0628\u0650\u0651 \u0671\u0644\u0652\u0639\u064e\u0670\u0644\u064e\u0645\u0650\u064a\u0646\u064e',
          ],
          2: <String>[
            '\u0627\u0644\u0653\u0645\u0653',
            '\u0630\u064e\u0670\u0644\u0650\u0643\u064e \u0671\u0644\u0652\u0643\u0650\u062a\u064e\u0670\u0628\u064f',
          ],
        },
        'positions': <int, List<List<int>>>{
          1: <List<int>>[
            <int>[1, 1, 1, 0],
            <int>[1, 1, 1, 0],
          ],
          2: <List<int>>[
            <int>[2, 1, 1, 0],
            <int>[2, 1, 2, 0],
          ],
        },
        'meccan': <int>[1],
      };

  late MidadIndex index;

  setUpAll(() {
    index = buildMidadIndex(payload());
  });

  group('normalisation', () {
    test('drops harakat and pause marks but keeps the written letters', () {
      final String plain = midadNormalise('\u0628\u0650\u0633\u0652\u0645\u0650 \u0671\u0644\u0644\u064e\u0651\u0647\u0650');
      expect(plain, '\u0628\u0633\u0645 \u0671\u0644\u0644\u0647');
    });

    test('the simplified script folds the alef family', () {
      expect(midadSimplify('\u0671\u0644\u0644\u0647'), '\u0627\u0644\u0644\u0647');
      expect(midadSimplify('\u0623\u0645\u0646'), '\u0627\u0645\u0646');
    });
  });

  group('counting', () {
    test('letters are counted in the chosen script and the walls of a surah '
        'really are walls', () {
      final MidadResult all = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0627', scope: MidadScope.mushaf),
      );
      final MidadResult fatiha = runMidadQuery(
        index,
        const MidadQuery(
          probe: '\u0627',
          scope: MidadScope.surah,
          scopeValue: 1,
        ),
      );
      expect(fatiha.total, greaterThan(0));
      expect(fatiha.total, lessThan(all.total));
      expect(all.ayahs, 4);
      expect(all.letters, greaterThan(0));
    });

    test('words are whole tokens: «الله» is not inside «بالله»', () {
      final MidadResult r = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0627\u0644\u0644\u0647', unit: MidadUnit.word),
      );
      expect(r.total, 1, reason: 'one «الله» across the two test surahs');
    });

    test('inside-word mode is explicit, not a silent widening', () {
      const String lamAllah = '\u0644\u0644\u0647';
      final MidadResult exact = runMidadQuery(
        index,
        const MidadQuery(probe: lamAllah, unit: MidadUnit.word),
      );
      final MidadResult inside = runMidadQuery(
        index,
        const MidadQuery(probe: lamAllah, unit: MidadUnit.word, wordInside: true),
      );
      expect(exact.total, 1, reason: 'the word «لله» appears once as a token');
      expect(inside.total, 2, reason: 'inside it also matches «الله»');
    });

    test('an empty probe asks nothing and gets zero, not a crash', () {
      final MidadResult r = runMidadQuery(
        index,
        const MidadQuery(probe: '', unit: MidadUnit.word),
      );
      expect(r.total, 0);
      expect(r.ayahs, 4);
    });

    test('the rhyme letter counts verses, not letters', () {
      final MidadResult r = runMidadQuery(
        index,
        const MidadQuery(
          probe: '\u0645',
          unit: MidadUnit.fasila,
          scope: MidadScope.surah,
          scopeValue: 1,
        ),
      );
      expect(r.total, 1);
      expect(r.ayahs, 2);
    });

    test('verse length averages over the scope', () {
      final MidadResult r = runMidadQuery(
        index,
        const MidadQuery(unit: MidadUnit.ayahLength),
      );
      expect(r.averageLength, closeTo(r.letters / r.ayahs, 0.001));
      expect(r.longest, isNotNull);
      expect(r.shortest, isNotNull);
      expect(r.longest!.count, greaterThanOrEqualTo(r.shortest!.count));
    });
  });

  group('scope', () {
    test('a page narrows the count to the verses printed on it', () {
      final MidadResult page2 = runMidadQuery(
        index,
        const MidadQuery(scope: MidadScope.page, scopeValue: 2),
      );
      expect(page2.ayahs, 2);
      expect(page2.bySurah.keys, <int>[2]);
    });

    test('meccan and medinan are a real split', () {
      final MidadResult meccan = runMidadQuery(
        index,
        const MidadQuery(scope: MidadScope.meccan),
      );
      final MidadResult medinan = runMidadQuery(
        index,
        const MidadQuery(scope: MidadScope.medinan),
      );
      expect(meccan.ayahs, 2);
      expect(medinan.ayahs, 2);
      expect(meccan.ayahs + medinan.ayahs, index.ayahs.length);
    });
  });

  group('conventions', () {
    test('the basmala switch adds its letters and words to the share, never a '
        'verse', () {
      final MidadResult off = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0627'),
      );
      final MidadResult on = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0627', includeBasmala: true),
      );
      expect(on.total, greaterThan(off.total));
      expect(on.letters, greaterThan(off.letters));
      expect(on.ayahs, off.ayahs);
      // The second surah is the one that gets an opening basmala.
      expect(on.bySurah[2], greaterThan(off.bySurah[2] ?? 0));
    });

    test('the written script and the simplified one disagree — and both are '
        'reported as they are', () {
      final MidadResult written = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0671', simpleScript: false),
      );
      final MidadResult folded = runMidadQuery(
        index,
        const MidadQuery(probe: '\u0627', simpleScript: true),
      );
      expect(written.total, greaterThan(0));
      expect(folded.total, greaterThanOrEqualTo(written.total));
    });
  });

  test('the insights are facts about the whole text', () {
    expect(index.insights.totalLetters, greaterThan(0));
    expect(index.insights.totalWords, greaterThan(0));
    expect(index.insights.topLetter, isNotEmpty);
    expect(index.insights.longestAyah.count,
        greaterThanOrEqualTo(index.insights.shortestAyah.count));
  });
}

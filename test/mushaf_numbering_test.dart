import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';

/// A surah table with the counts of a tiny Mushaf, for the arithmetic.
List<Surah> _toySurahs(List<int> counts) => <Surah>[
      for (int i = 0; i < counts.length; i++)
        Surah(
          id: i + 1,
          nameAr: 'س${i + 1}',
          nameEn: 'S${i + 1}',
          translatedName: 'S${i + 1}',
          place: 'makkah',
          ayahCount: counts[i],
          bismillahPre: i != 0,
        ),
    ];

void main() {
  group('MushafNumbering', () {
    test('numbers ayat the way the corpus does, from the surah table', () {
      final MushafNumbering numbering = MushafNumbering.fromSurahs(
        _toySurahs(<int>[7, 3, 5]),
      );

      expect(numbering.isReady, isTrue);
      expect(numbering.idOf(1, 1), 1);
      expect(numbering.idOf(1, 7), 7);
      expect(numbering.idOf(2, 1), 8);
      expect(numbering.idOf(3, 5), 15);
      expect(numbering.totalAyahs, 15);
    });

    test('locates an absolute id back to surah and ayah', () {
      final MushafNumbering numbering = MushafNumbering.fromSurahs(
        _toySurahs(<int>[7, 3, 5]),
      );

      expect(numbering.locate(1), (surah: 1, ayah: 1));
      expect(numbering.locate(8), (surah: 2, ayah: 1));
      expect(numbering.locate(15), (surah: 3, ayah: 5));
      expect(numbering.locate(16), isNull);
      expect(numbering.ayahCountOf(3), 5);
      expect(numbering.ayahCountOf(9), 0);
    });

    test('an empty table answers without throwing', () {
      final MushafNumbering numbering = MushafNumbering.empty();

      expect(numbering.isReady, isFalse);
      expect(numbering.idOf(2, 2), 0);
      expect(numbering.locate(9), isNull);
      expect(numbering.totalAyahs, 0);
    });

    // The real check, against the data the app ships: the numbering the corpus
    // uses must be the numbering the app's own surah table produces, or a tinted
    // verse in the reader would be the wrong verse.
    test('agrees with every reference in the bundled corpus', () {
      final File quran = File('assets/data/quran_uthmani.json');
      final File corpus = File('assets/data/mutashabihat_data_normalized.json');
      if (!quran.existsSync() || !corpus.existsSync()) {
        markTestSkipped('assets are not next to the test runner');
        return;
      }

      final Map<String, dynamic> rawQuran =
          jsonDecode(quran.readAsStringSync()) as Map<String, dynamic>;
      final List<Surah> surahs = <Surah>[
        for (final dynamic entry in rawQuran['surahs'] as List<dynamic>)
          Surah(
            id: ((entry as Map<String, dynamic>)['id'] as num).toInt(),
            nameAr: (entry['name_ar'] as String?) ?? '',
            nameEn: (entry['name_en'] as String?) ?? '',
            translatedName: (entry['translated_name'] as String?) ?? '',
            place: (entry['place'] as String?) ?? 'makkah',
            ayahCount: (entry['ayah_count'] as num).toInt(),
            bismillahPre: true,
          ),
      ];
      final MushafNumbering numbering = MushafNumbering.fromSurahs(surahs);
      expect(numbering.totalAyahs, 6236);

      final List<dynamic> nodes = jsonDecode(corpus.readAsStringSync()) as List<dynamic>;
      int checked = 0;
      int mismatched = 0;
      for (final dynamic node in nodes) {
        final Map<String, dynamic> source = node as Map<String, dynamic>;
        final int surah = (source['source_surah_number'] as num).toInt();
        final int ayah = (source['source_ayah_number'] as num).toInt();
        final int expected = (source['source_absolute_id'] as num).toInt();
        checked++;
        if (numbering.idOf(surah, ayah) != expected) {
          mismatched++;
        }
        for (final dynamic target in (source['targets'] as List<dynamic>)) {
          final Map<String, dynamic> t = target as Map<String, dynamic>;
          checked++;
          if (numbering.idOf(
                (t['target_surah_number'] as num).toInt(),
                (t['target_ayah_number'] as num).toInt(),
              ) !=
              (t['target_absolute_id'] as num).toInt()) {
            mismatched++;
          }
        }
      }

      // A floor rather than an exact count: the corpus is rebuilt as books and
      // rules are added, and this test's job is the numbering, not the total.
      expect(checked, greaterThan(3000));
      expect(mismatched, 0);
    });
  });
}

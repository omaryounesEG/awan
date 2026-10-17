import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';

void main() {
  group('KisaiLayer.fromJson', () {
    test('reads both lists and cleans the counterpart wording', () {
      final KisaiLayer layer = KisaiLayer.fromJson(<String, dynamic>{
        'source': 'الكتاب',
        'similar': <dynamic>[
          <String, dynamic>{
            'absolute_id': 28,
            'surah': 2,
            'ayah': 21,
            'quoted': ': اتقوا ربكم (1).',
            'book_text': '[فيها]: يا أيها الناس اعبدوا ربكم (21)',
          },
        ],
        'unique': <dynamic>[
          <String, dynamic>{
            'absolute_id': 107,
            'surah': 2,
            'ayah': 100,
            'book_text': 'وفيها: بل أكثرهم لا يؤمنون (100) ليس في القرآن مثله.',
          },
        ],
      });

      expect(layer.similar.single.quoted, 'اتقوا ربكم (1).');
      expect(layer.similar.single.absoluteAyahId, 28);
      expect(layer.unique.single.absoluteAyahId, 107);
      expect(layer.isEmpty, isFalse);
    });

    test('accepts the bare ids an older asset shipped', () {
      final KisaiLayer layer = KisaiLayer.fromJson(<String, dynamic>{
        'similar': <dynamic>[],
        'unique': <dynamic>[107, 108],
      });
      expect(layer.unique.length, 2);
      expect(layer.unique.first.bookText, isEmpty);
    });
  });

  group('KisaiLayer.filter', () {
    final List<KisaiVerse> verses = <KisaiVerse>[
      const KisaiVerse(
        absoluteAyahId: 28,
        surah: 2,
        ayah: 21,
        quoted: 'اتقوا ربكم (1)',
        bookText: 'وفيها: يا أيها الناس اعبدوا ربكم (21)',
      ),
      const KisaiVerse(
        absoluteAyahId: 4914,
        surah: 55,
        ayah: 13,
        quoted: 'فبأي آلاء ربكما تكذبان',
        bookText: 'وفيها: فبأي آلاء ربكما تكذبان',
      ),
    ];
    String nameOf(int surah) => surah == 2 ? 'البقرة' : 'الرحمن';

    test('matches the book wording without diacritics', () {
      expect(
        KisaiLayer.empty.filter(verses, 'يا ايها الناس', nameOf: nameOf).length,
        1,
        reason: 'the reader types plain text; the book is diacritised',
      );
    });

    test('matches a surah by name', () {
      expect(KisaiLayer.empty.filter(verses, 'الرحمن', nameOf: nameOf).single.surah, 55);
    });

    test('an empty query keeps everything', () {
      expect(KisaiLayer.empty.filter(verses, '   ', nameOf: nameOf).length, 2);
    });
  });

  group('the shipped layer', () {
    test('holds the book lists with Mushaf ids', () {
      final File asset = File('assets/data/kisai_mutashabihat.json');
      if (!asset.existsSync()) {
        markTestSkipped('the layer asset is not next to the test runner');
        return;
      }
      final KisaiLayer layer =
          KisaiLayer.fromJson(jsonDecode(asset.readAsStringSync()) as Map<String, dynamic>);

      expect(layer.source, contains('الكسائي'));
      expect(layer.similar.length, greaterThan(50));
      expect(layer.unique.length, greaterThan(30));
      for (final KisaiVerse verse in <KisaiVerse>[...layer.similar, ...layer.unique]) {
        expect(verse.absoluteAyahId, inInclusiveRange(1, 6236));
      }
      expect(
        layer.similar.map((KisaiVerse v) => v.surah).toSet().length,
        greaterThan(10),
        reason: 'the book walks the whole Mushaf, not one surah',
      );
    });
  });
}

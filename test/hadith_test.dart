import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';

/// A three-hadith corpus with one deliberate match across two books.
HadithCorpus tinyCorpus() {
  const List<HadithBook> books = <HadithBook>[
    HadithBook(key: 'one', ar: 'الكتاب الأول', en: 'One', count: 2, chapters: <HadithChapter>[
      HadithChapter(id: 1, ar: 'باب النية'),
    ]),
    HadithBook(key: 'two', ar: 'الكتاب الثاني', en: 'Two', count: 1, chapters: <HadithChapter>[
      HadithChapter(id: 1, ar: 'باب الإيمان'),
    ]),
  ];
  const List<Hadith> hadiths = <Hadith>[
    Hadith(
      index: 0,
      book: 0,
      number: 1,
      chapterId: 1,
      text: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      grade: 0,
      related: <int>[1],
    ),
    Hadith(
      index: 1,
      book: 1,
      number: 1,
      chapterId: 1,
      text: 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى',
      grade: 0,
      related: <int>[0],
    ),
    Hadith(
      index: 2,
      book: 1,
      number: 2,
      chapterId: 1,
      text: 'بُنِيَ الإِسْلَامُ عَلَى خَمْسٍ',
      grade: 2,
      related: <int>[],
    ),
  ];
  return HadithCorpus(
    books: books,
    hadiths: hadiths,
    search: <String>[for (final Hadith h in hadiths) normalizeArabic(h.text)],
    gradeLabels: const <String>['صحيح', 'حسن', 'حسن صحيح', 'ضعيف', 'غير مبيّن'],
  );
}

ProviderContainer container() {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      hadithCorpusProvider.overrideWith((Ref ref) async => tinyCorpus()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('normalizeArabic', () {
    test('drops the diacritics that a reader never types', () {
      expect(normalizeArabic('إِنَّمَا الأَعْمَالُ'), 'انما الاعمال');
    });

    test('unifies alef, ya and ta marbuta', () {
      expect(normalizeArabic('إبراهيم'), 'ابراهيم');
      expect(normalizeArabic('مُصْطَفَى'), 'مصطفي');
      expect(normalizeArabic('صلاة'), 'صلاه');
    });

    test('punctuation becomes a space, not a deletion', () {
      expect(normalizeArabic('قال: «لا»'), 'قال لا');
    });
  });

  group('search', () {
    test('finds a hadith without diacritics or hamza', () async {
      final ProviderContainer c = container();
      await c.read(hadithCorpusProvider.future);
      c.read(hadithFilterProvider.notifier).setQuery('الاعمال بالنيات');
      final HadithResults? results = c.read(hadithResultsProvider);
      expect(results, isNotNull);
      expect(results!.total, 2);
      // Both match at the first letter, so the shorter text wins the tie — the
      // isnad-heavy one is the second row.
      expect(results.items.first.text.length,
          lessThanOrEqualTo(results.items.last.text.length));
    });

    test('a book filter narrows the same query', () async {
      final ProviderContainer c = container();
      await c.read(hadithCorpusProvider.future);
      c.read(hadithFilterProvider.notifier).setQuery('الاعمال');
      c.read(hadithFilterProvider.notifier).toggleBook(1);
      final HadithResults results = c.read(hadithResultsProvider)!;
      expect(results.total, 1);
      expect(results.items.single.book, 1);
    });

    test('a grade filter keeps only that grade', () async {
      final ProviderContainer c = container();
      await c.read(hadithCorpusProvider.future);
      c.read(hadithFilterProvider.notifier).toggleGrade(2);
      final HadithResults results = c.read(hadithResultsProvider)!;
      expect(results.total, 1);
      expect(results.items.single.number, 2);
    });

    test('an idle filter browses from the first hadith', () async {
      final ProviderContainer c = container();
      await c.read(hadithCorpusProvider.future);
      final HadithResults results = c.read(hadithResultsProvider)!;
      expect(results.total, 3);
      expect(results.items.first.index, 0);
    });

    test('a query that matches nothing returns nothing, not everything', () async {
      final ProviderContainer c = container();
      await c.read(hadithCorpusProvider.future);
      c.read(hadithFilterProvider.notifier).setQuery('زززز');
      expect(c.read(hadithResultsProvider)!.total, 0);
    });
  });

  group('bundled corpus', () {
    test('seven books, 36,038 hadiths, every text non-empty', () {
      final File file = File('assets/hadith/hadith_v2.json.gz');
      expect(file.existsSync(), isTrue);
      final Map<String, dynamic> doc = jsonDecode(
        utf8.decode(gzip.decode(file.readAsBytesSync())),
      ) as Map<String, dynamic>;
      final List<dynamic> books = doc['books'] as List<dynamic>;
      final List<dynamic> hadiths = doc['hadiths'] as List<dynamic>;
      expect(books.length, 7);
      expect(hadiths.length, 36038);
      expect((books.first as Map)['key'], 'bukhari');
      expect(
        (books as List<dynamic>).map((dynamic b) => (b as Map)['key']).toList(),
        containsAll(<String>['nasai', 'ibnmajah', 'malik']),
      );

      int empty = 0;
      int linked = 0;
      for (final dynamic raw in hadiths) {
        final Map<String, dynamic> h = (raw as Map).cast<String, dynamic>();
        if ('${h['t']}'.trim().isEmpty) empty++;
        if ((h['r'] as List<dynamic>?)?.isNotEmpty ?? false) linked++;
      }
      expect(empty, 0);
      expect(linked, greaterThan(2000), reason: 'cross-book links exist');
    });
  });
}

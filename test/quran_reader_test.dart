import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/quran_tafseer/data/datasources/quran_asset_datasource.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/domain/usecases/search_quran.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/ayah_ornament.dart';

/// Serves the **real shipped assets** from disk.
///
/// The point is that these tests run against the same 6,236 verses and 604 pages the
/// app bundles — not a hand-written fixture that can silently drift from the data the
/// reader actually sees. A missing or malformed asset fails here, in CI, instead of
/// on a phone.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final File file = File('${Directory.current.path}/$key');
    if (!file.existsSync()) {
      throw StateError('asset not found on disk: $key');
    }
    final Uint8List bytes = await file.readAsBytes();
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  final QuranLocalDataSource source = QuranLocalDataSource(bundle: _DiskBundle());

  group('the bundled text', () {
    test('is the whole Quran', () async {
      final QuranText text = await source.load();
      expect(text.surahs.length, 114);
      int total = 0;
      for (final Surah surah in text.surahs) {
        expect(text.ayahsOf(surah.id).length, surah.ayahCount,
            reason: 'surah ${surah.id} count must match its metadata');
        total += surah.ayahCount;
      }
      expect(total, 6236);
    });

    test('opens with the basmala and ends with mankind', () async {
      final QuranText text = await source.load();
      expect(text.ayah(1, 1)!.text, startsWith('بِسْمِ'));
      expect(text.surah(114).nameAr, 'الناس');
      expect(text.ayah(114, 6), isNotNull);
    });
  });

  group('the Mushaf page map', () {
    test('covers every page of the printed Mushaf', () async {
      final MushafIndex index = await source.loadIndex();
      expect(index.totalPages, 604);
      expect(index.pageCount, 604);
      for (int page = 1; page <= 604; page++) {
        expect(index.pageRefs(page), isNotEmpty, reason: 'page $page must carry text');
      }
    });

    test('starts on page 1 and ends on page 604', () async {
      final MushafIndex index = await source.loadIndex();
      expect(index.pageOf(1, 1), 1);
      expect(index.pageOf(114, 6), 604);
      expect(index.firstRefOfPage(1), const AyahRef(1, 1));
    });

    test('groups a page in Mushaf order', () async {
      final MushafIndex index = await source.loadIndex();
      final List<AyahRef> first = index.pageRefs(1);
      expect(first.length, 7);
      expect(first.first, const AyahRef(1, 1));
      expect(first.last, const AyahRef(1, 7));

      final List<AyahRef> last = index.pageRefs(604);
      expect(last.first.surah, greaterThanOrEqualTo(112));
      expect(last.last, const AyahRef(114, 6));
    });

    test('knows the fourteen prostration verses', () async {
      final MushafIndex index = await source.loadIndex();
      int sajda = 0;
      for (final List<AyahPosition> positions in index.bySurah.values) {
        sajda += positions.where((AyahPosition p) => p.isSajda).length;
      }
      expect(sajda, 14);
    });

    test('every ayah has a juz between 1 and 30', () async {
      final MushafIndex index = await source.loadIndex();
      for (final List<AyahPosition> positions in index.bySurah.values) {
        for (final AyahPosition position in positions) {
          expect(position.juz, inInclusiveRange(1, 30));
          expect(position.page, inInclusiveRange(1, 604));
        }
      }
    });
  });

  group('the bundled tafsir', () {
    test('comments every verse', () async {
      final TafsirText tafsir = await source.loadTafsir(AppConstants.tafsirMuyassarId);
      expect(tafsir.count, 6236);
      expect(tafsir.textFor(1, 1), isNotNull);
      expect(tafsir.textFor(1, 1)!, isNotEmpty);
      expect(tafsir.name, isNotEmpty);
    });

    test('has a commentary for the last verse too', () async {
      final TafsirText tafsir = await source.loadTafsir(AppConstants.tafsirMuyassarId);
      expect(tafsir.textFor(114, 6), isNotNull);
    });
  });

  group('searching without diacritics', () {
    late QuranHaystack haystack;

    setUpAll(() async {
      haystack = QuranHaystack(await source.load());
    });

    test('indexes every verse', () {
      expect(haystack.length, 6236);
    });

    test('finds a plain word inside a fully vocalised verse', () {
      final List<QuranSearchHit> hits = haystack.search('الرحمن');
      expect(hits, isNotEmpty);
      expect(hits.any((QuranSearchHit hit) => hit.surah == 1), isTrue,
          reason: 'Al-Fatiha calls Allah «ٱلرَّحْمَـٰنِ»');
    });

    test('a query with diacritics gives the same answer as one without', () {
      final List<QuranSearchHit> plain = haystack.search('الحمد لله');
      final List<QuranSearchHit> vocalised = haystack.search('ٱلْحَمْدُ لِلَّهِ');
      expect(plain.map((QuranSearchHit h) => '${h.surah}:${h.ayah}'),
          containsAll(vocalised.map((QuranSearchHit h) => '${h.surah}:${h.ayah}')));
      expect(plain, isNotEmpty);
    });

    test('ignores tatweel and hamza decoration', () {
      // «اللــه» with a tatweel must match «اللَّه» — a keyboard that stretches a
      // word is not a different word.
      expect(haystack.search('اللــه').isNotEmpty, isTrue);
      expect(haystack.search('إسماعيل').isNotEmpty || haystack.search('اسماعيل').isNotEmpty,
          isTrue);
      expect(
        haystack.search('اسماعيل').map((QuranSearchHit h) => '${h.surah}:${h.ayah}'),
        haystack.search('إسماعيل').map((QuranSearchHit h) => '${h.surah}:${h.ayah}'),
      );
    });

    test('refuses a one-letter query', () {
      expect(haystack.search('ا'), isEmpty);
      expect(haystack.search(''), isEmpty);
    });

    test('honours the limit', () {
      expect(haystack.search('الله', limit: 5).length, 5);
    });
  });

  group('the Mushaf ornaments', () {
    test('writes numbers in Arabic-Indic digits', () {
      expect(arabicDigits(7), '٧');
      expect(arabicDigits(114), '١١٤');
      expect(arabicDigits(6236), '٦٢٣٦');
    });

    test('writes the number that goes inside the medallion', () {
      expect(AyahOrnament.digits(3), '٣');
      expect(AyahOrnament.digits(154), '١٥٤');
      expect(AyahOrnament.digits(604), '٦٠٤');
    });

    // The bug this guards: U+06DD typeset with Arabic-Indic digits rendered as an
    // empty black disc on the device, because placing the digits inside the rosette
    // needs a font-level substitution that silently does not fire when the digits are
    // drawn by a fallback font. The mark is painted instead, so the number is asserted
    // to be *on screen*, not merely in the string.
    testWidgets('the painted medallion always shows its number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: AyahOrnament(
            ayah: 154,
            palette: QuranPalette.paper,
            fontFamily: 'UthmanicHafs',
            diameter: 40,
          ),
        ),
      );
      expect(find.text('١٥٤'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('the reading surfaces', () {
    test('every palette is readable on its own background', () {
      for (final QuranPalette palette in QuranPalette.values) {
        expect(palette.markWash.opacity, greaterThan(0));
        expect(palette.text, isNot(palette.background));
        expect(palette.accent, isNot(palette.background));
      }
    });

    test('the palette key survives a bad value', () {
      expect(QuranPaletteStyle.fromKey('oled'), QuranPalette.oled);
      expect(QuranPaletteStyle.fromKey('nonsense'), QuranPalette.paper);
    });

    test('an unknown font falls back to the Mushaf script', () {
      expect(quranFontOf('amiri').family, 'AmiriQuran');
      expect(quranFontOf('nope').family, kQuranFonts.first.family);
    });

    test('the marker matches the page it sits on', () {
      final MushafIndex index = MushafIndex(
        bySurah: <int, List<AyahPosition>>{
          2: <AyahPosition>[
            const AyahPosition(page: 2, juz: 1, hizb: 1),
            const AyahPosition(page: 2, juz: 1, hizb: 1),
            const AyahPosition(page: 3, juz: 1, hizb: 1),
          ],
        },
        totalPages: 604,
      );
      expect(isMarkedPage(const AyahRef(2, 2), index, 2), isTrue);
      expect(isMarkedPage(const AyahRef(2, 3), index, 2), isFalse);
      expect(isMarkedPage(null, index, 2), isFalse);
    });
  });
}

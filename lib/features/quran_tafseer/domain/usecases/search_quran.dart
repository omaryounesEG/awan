import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';

/// One verse plus the two forms it is searched in.
///
/// `dropped` treats the Uthmani superscript alef as silent, `folded` treats it as a
/// real alef. One of them matches whatever spelling a person types.
typedef QuranNeedle = ({
  int surah,
  int ayah,
  String dropped,
  String folded,
});

/// The searchable copy of the Quran.
///
/// Searching the Uthmani text as written finds almost nothing: the Mushaf writes
/// «ٱلرَّحْمَـٰنِ» and a person types «الرحمن». So the corpus is normalised once
/// (diacritics dropped, alef/hamza forms unified — see `normalizeArabic`), kept in
/// memory, and every query is normalised the same way before the scan.
///
/// This lives in the domain on purpose: it is pure, has no I/O and no Isar, so the
/// rule "a query without diacritics matches text with diacritics" is covered by a
/// test instead of by a device screen.
class QuranHaystack {
  QuranHaystack(this.text)
      : needles = <QuranNeedle>[
          for (final Surah surah in text.surahs)
            for (int index = 0; index < text.ayahsOf(surah.id).length; index++)
              (
                surah: surah.id,
                ayah: index + 1,
                dropped: normalizeArabic(text.ayahsOf(surah.id)[index]),
                folded: normalizeArabic(
                  text.ayahsOf(surah.id)[index],
                  foldSuperscriptAlef: true,
                ),
              ),
        ];

  final QuranText text;
  final List<QuranNeedle> needles;

  int get length => needles.length;

  /// The shortest query worth scanning for. One letter matches thousands of verses
  /// and helps nobody.
  static const int minimumQueryLength = 2;

  List<QuranSearchHit> search(String query, {int limit = 60}) {
    final String needle = normalizeArabic(query).trim();
    if (needle.length < minimumQueryLength) return const <QuranSearchHit>[];

    final List<QuranSearchHit> hits = <QuranSearchHit>[];
    for (final QuranNeedle hay in needles) {
      if (hay.dropped.contains(needle) || hay.folded.contains(needle)) {
        hits.add(QuranSearchHit(
          surah: hay.surah,
          surahName: text.surah(hay.surah).nameAr,
          ayah: hay.ayah,
          text: text.ayah(hay.surah, hay.ayah)?.text ?? '',
        ));
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }
}

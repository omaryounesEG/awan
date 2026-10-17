/// Domain entities of the Quran module.
library;

class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.translatedName,
    required this.place,
    required this.ayahCount,
    required this.bismillahPre,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String translatedName;
  final String place; // 'makkah' | 'madinah'
  final int ayahCount;
  final bool bismillahPre;

  bool get isMeccan => place == 'makkah';
}

class Ayah {
  const Ayah({
    required this.surah,
    required this.number,
    required this.text,
  });

  final int surah;
  final int number;
  final String text;

  String get key => '$surah:$number';
}

class QuranSearchHit {
  const QuranSearchHit({
    required this.surah,
    required this.surahName,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final String surahName;
  final int ayah;
  final String text;
}

class BookmarkedAyah {
  const BookmarkedAyah({
    required this.id,
    required this.surah,
    required this.surahName,
    required this.ayah,
    required this.text,
    required this.createdAt,
    this.note,
  });

  final int id;
  final int surah;
  final String surahName;
  final int ayah;
  final String text;
  final DateTime createdAt;
  final String? note;
}

/// Where one ayah sits in the printed Mushaf.
///
/// Independent of the text: `quran_uthmani.json` stores only words, and a reader
/// that pages like a Mushaf (604 pages) or remembers a *page* marker cannot derive
/// this from the words. It comes from `assets/data/quran_index.json`.
class AyahPosition {
  const AyahPosition({
    required this.page,
    required this.juz,
    required this.hizb,
    this.sajda = 0,
  });

  final int page;
  final int juz;
  final int hizb;

  /// Non-zero on the 14 prostration verses (0 = not a sajda ayah).
  final int sajda;

  bool get isSajda => sajda > 0;
}

/// A pointer to one verse, without its text.
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  String get key => '$surah:$ayah';

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => key;
}

/// The page/juz map of the whole Mushaf, plus the reverse lookup a paged reader
/// needs (`page 12 → which verses?`).
class MushafIndex {
  MushafIndex({required this.bySurah, required this.totalPages});

  /// surah number -> position of each ayah (index 0 == ayah 1).
  final Map<int, List<AyahPosition>> bySurah;
  final int totalPages;

  /// A shared empty map — what the reader draws before the asset finishes parsing.
  static final MushafIndex empty = MushafIndex(
    bySurah: const <int, List<AyahPosition>>{},
    totalPages: 0,
  );

  List<AyahPosition> _positions(int surah) =>
      bySurah[surah] ?? const <AyahPosition>[];

  /// The printed position of one ayah, or null when the index does not cover it.
  AyahPosition? positionOf(int surah, int ayah) {
    final List<AyahPosition> list = _positions(surah);
    if (ayah < 1 || ayah > list.length) return null;
    return list[ayah - 1];
  }

  int? pageOf(int surah, int ayah) => positionOf(surah, ayah)?.page;

  /// Every verse printed on [page], in Mushaf order.
  List<AyahRef> pageRefs(int page) {
    final List<AyahRef> refs = <AyahRef>[];
    for (final MapEntry<int, List<AyahPosition>> entry in bySurah.entries) {
      final List<AyahPosition> positions = entry.value;
      for (int i = 0; i < positions.length; i++) {
        if (positions[i].page == page) refs.add(AyahRef(entry.key, i + 1));
      }
    }
    return refs;
  }

  /// The first verse of [page] — what a page marker should point at.
  AyahRef? firstRefOfPage(int page) {
    final List<AyahRef> refs = pageRefs(page);
    return refs.isEmpty ? null : refs.first;
  }

  /// Number of Mushaf pages that actually carry text.
  int get pageCount {
    int max = 0;
    for (final List<AyahPosition> positions in bySurah.values) {
      for (final AyahPosition position in positions) {
        if (position.page > max) max = position.page;
      }
    }
    return max == 0 ? totalPages : max;
  }
}

/// One tafsir edition held on the device (`assets/addons/tafsir_*.json`).
class TafsirText {
  const TafsirText({
    required this.id,
    required this.name,
    required this.author,
    required this.source,
    required this.ayahs,
  });

  final int id;
  final String name;
  final String author;
  final String source;

  /// `'2:255'` -> the commentary text.
  final Map<String, String> ayahs;

  String? textFor(int surah, int ayah) => ayahs['$surah:$ayah'];

  int get count => ayahs.length;

  static const TafsirText empty = TafsirText(
    id: 0,
    name: '',
    author: '',
    source: '',
    ayahs: <String, String>{},
  );
}

/// The full Quran held in memory (≈1.4 MB of text) — parsed once from the
/// bundled asset inside an isolate.
class QuranText {
  const QuranText({required this.surahs, required this.ayahs});

  final List<Surah> surahs;

  /// surah number -> list of ayah texts (index 0 == ayah 1).
  final Map<int, List<String>> ayahs;

  Surah surah(int number) => surahs[number - 1];

  List<String> ayahsOf(int surah) => ayahs[surah] ?? const <String>[];

  Ayah? ayah(int surah, int number) {
    final List<String> list = ayahsOf(surah);
    if (number < 1 || number > list.length) return null;
    return Ayah(surah: surah, number: number, text: list[number - 1]);
  }
}

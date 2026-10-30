import 'package:flutter/foundation.dart';

/// One hadith, as the reader meets it: a book, a number, a chapter, the Arabic
/// text, a grade, and the other books that carry the same matn.
@immutable
class Hadith {
  const Hadith({
    required this.index,
    required this.book,
    required this.number,
    required this.chapterId,
    required this.text,
    required this.grade,
    required this.related,
  });

  final int index;
  final int book;
  final int number;
  final int chapterId;
  final String text;

  /// Index into [HadithCorpus.gradeLabels].
  final int grade;
  final List<int> related;

  static Hadith fromJson(int index, Map<String, Object?> raw) => Hadith(
        index: index,
        book: (raw['b'] as num?)?.toInt() ?? 0,
        number: (raw['n'] as num?)?.toInt() ?? 0,
        chapterId: (raw['c'] as num?)?.toInt() ?? 0,
        text: '${raw['t'] ?? ''}',
        grade: (raw['g'] as num?)?.toInt() ?? 0,
        related: <int>[
          for (final Object? id in (raw['r'] as List<Object?>?) ?? const <Object?>[])
            if (id is num) id.toInt(),
        ],
      );
}

@immutable
class HadithChapter {
  const HadithChapter({required this.id, required this.ar});

  final int id;
  final String ar;

  static HadithChapter fromJson(Map<String, Object?> raw) => HadithChapter(
        id: (raw['id'] as num?)?.toInt() ?? 0,
        ar: '${raw['ar'] ?? ''}',
      );
}

@immutable
class HadithBook {
  const HadithBook({
    required this.key,
    required this.ar,
    required this.en,
    required this.count,
    required this.chapters,
  });

  final String key;
  final String ar;
  final String en;
  final int count;
  final List<HadithChapter> chapters;

  String titleFor(String locale) => locale == 'en' && en.isNotEmpty ? en : ar;

  HadithChapter? chapter(int id) {
    for (final HadithChapter chapter in chapters) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  static HadithBook fromJson(Map<String, Object?> raw) => HadithBook(
        key: '${raw['key'] ?? ''}',
        ar: '${raw['ar'] ?? ''}',
        en: '${raw['en'] ?? ''}',
        count: (raw['count'] as num?)?.toInt() ?? 0,
        chapters: <HadithChapter>[
          for (final Object? row in (raw['chapters'] as List<Object?>?) ?? const <Object?>[])
            if (row is Map) HadithChapter.fromJson(row.cast<String, Object?>()),
        ],
      );
}

/// The four books, in one list, plus the normalised copy of every text that the
/// search runs against.
///
/// Normalisation happens once, in the isolate that parses the asset: twenty-four
/// thousand strings is cheap to do at load and expensive to redo on every
/// keystroke.
@immutable
class HadithCorpus {
  const HadithCorpus({
    required this.books,
    required this.hadiths,
    required this.search,
    required this.gradeLabels,
  });

  final List<HadithBook> books;
  final List<Hadith> hadiths;
  final List<String> search;
  final List<String> gradeLabels;

  int get total => hadiths.length;

  HadithBook bookOf(Hadith hadith) => books[hadith.book.clamp(0, books.length - 1)];

  String chapterOf(Hadith hadith) =>
      bookOf(hadith).chapter(hadith.chapterId)?.ar ?? '';

  List<Hadith> relatedTo(Hadith hadith) => <Hadith>[
        for (final int index in hadith.related)
          if (index >= 0 && index < hadiths.length) hadiths[index],
      ];
}

/// Arabic search normalisation: diacritics off, alef/ya/ta-marbuta unified, and
/// punctuation turned into spaces — the same shape the asset was built with.
String normalizeArabic(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int code in input.codeUnits) {
    // Harakat, tatweel and Quranic marks carry no meaning for a search.
    if (code >= 0x0610 && code <= 0x061A) continue;
    if (code >= 0x064B && code <= 0x065F) continue;
    if (code == 0x0670 || code == 0x0640) continue;
    if (code >= 0x06D6 && code <= 0x06ED) continue;
    int out = code;
    if (out == 0x0623 || out == 0x0625 || out == 0x0622) out = 0x0627; // أ إ آ
    if (out == 0x0649) out = 0x064A; // ى
    if (out == 0x0629) out = 0x0647; // ة
    if (out == 0x0624) out = 0x0648; // ؤ
    if (out == 0x0626) out = 0x064A; // ئ
    final bool word = (out >= 0x0621 && out <= 0x064A) || (out >= 0x0660 && out <= 0x0669);
    buffer.writeCharCode(word ? out : 0x20);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

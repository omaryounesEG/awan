import 'package:awan/core/utils/arabic_text.dart';

/// A verse الكسائي (ت 189هـ) names in «مشتبهات القرآن».
///
/// The book never gives a verse number for the counterpart, only its wording —
/// «وسائر القرآن: اتقوا ربكم (1)» — so the counterpart is carried as text and the
/// verse itself as a Mushaf reference. That is the honest shape of the source:
/// it documents *that* two passages look alike, and leaves pinpointing to the
/// reader.
class KisaiVerse {
  const KisaiVerse({
    required this.absoluteAyahId,
    required this.surah,
    required this.ayah,
    required this.quoted,
    required this.bookText,
  });

  /// Mushaf numbering (1..6236), so the graph can be opened straight from it.
  final int absoluteAyahId;
  final int surah;
  final int ayah;

  /// The counterpart as the book words it, cleaned of the «:» lead-in.
  final String quoted;

  /// The whole sentence from the book, kept so the source can be shown as written.
  final String bookText;

  static String _clean(String raw) {
    String value = raw.trim();
    while (value.startsWith(':') || value.startsWith('\u060C') || value.startsWith('-')) {
      value = value.substring(1).trim();
    }
    return value;
  }

  factory KisaiVerse.fromJson(Map<String, dynamic> json) => KisaiVerse(
        absoluteAyahId: (json['absolute_id'] as num).toInt(),
        surah: (json['surah'] as num).toInt(),
        ayah: (json['ayah'] as num).toInt(),
        quoted: _clean((json['quoted'] as String?) ?? ''),
        bookText: (json['book_text'] as String?)?.trim() ?? '',
      );
}

/// The two lists the book yields: verses with a counterpart, and verses the
/// author states have none («ليس مثله»).
class KisaiLayer {
  const KisaiLayer({
    required this.source,
    required this.similar,
    required this.unique,
  });

  final String source;
  final List<KisaiVerse> similar;
  final List<KisaiVerse> unique;

  static const KisaiLayer empty = KisaiLayer(
    source: '',
    similar: <KisaiVerse>[],
    unique: <KisaiVerse>[],
  );

  bool get isEmpty => similar.isEmpty && unique.isEmpty;

  factory KisaiLayer.fromJson(Map<String, dynamic> json) => KisaiLayer(
        source: (json['source'] as String?) ?? '',
        similar: <KisaiVerse>[
          for (final dynamic item in (json['similar'] as List<dynamic>? ?? <dynamic>[]))
            KisaiVerse.fromJson(item as Map<String, dynamic>),
        ],
        unique: <KisaiVerse>[
          // Older asset revisions shipped bare ids; accept both shapes so a
          // stale asset degrades to «no book text» instead of throwing.
          for (final dynamic item in (json['unique'] as List<dynamic>? ?? <dynamic>[]))
            item is num
                ? KisaiVerse.fromJson(<String, dynamic>{'absolute_id': item, 'surah': 0, 'ayah': 0})
                : KisaiVerse.fromJson(item as Map<String, dynamic>),
        ],
      );

  /// Narrows a list to what a person typed.
  ///
  /// The match runs on the normalised forms, so «لعلكم تتقون» finds «لَعَلَّكُمْ
  /// تَتَّقُونَ» in the book's wording, and a surah name finds its verses without
  /// the reader knowing the number.
  List<KisaiVerse> filter(
    List<KisaiVerse> verses,
    String query, {
    required String Function(int surah) nameOf,
  }) {
    final String needle = normalizeArabic(query).trim();
    if (needle.isEmpty) return verses;
    final Map<int, String> names = <int, String>{};
    for (final KisaiVerse verse in verses) {
      names[verse.surah] ??= normalizeArabic(nameOf(verse.surah));
    }
    return <KisaiVerse>[
      for (final KisaiVerse verse in verses)
        if (normalizeArabic(verse.quoted).contains(needle) ||
            normalizeArabic(verse.bookText).contains(needle) ||
            (names[verse.surah] ?? '').contains(needle))
          verse,
    ];
  }
}

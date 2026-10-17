import 'package:flutter/material.dart';

import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';

/// The reading surface — deliberately independent of the app theme.
///
/// Twenty minutes of reading is a different task from glancing at a dashboard, so
/// the reader owns its colours: a warm paper, a sepia for daylight, a soft night,
/// and a true black for OLED panels (where black pixels are simply off, which is
/// both easier on the eyes at night and cheaper on battery).
enum QuranPalette { paper, sepia, dark, oled }

extension QuranPaletteStyle on QuranPalette {
  String get key => name;

  bool get isDark => this == QuranPalette.dark || this == QuranPalette.oled;

  static QuranPalette fromKey(String key) => QuranPalette.values.firstWhere(
        (QuranPalette palette) => palette.name == key,
        orElse: () => QuranPalette.paper,
      );

  /// The page itself.
  Color get background => switch (this) {
        QuranPalette.paper => const Color(0xFFFBF7EE),
        QuranPalette.sepia => const Color(0xFFF2E4CB),
        QuranPalette.dark => const Color(0xFF15171A),
        QuranPalette.oled => const Color(0xFF000000),
      };

  /// Cards, sheets and bars sitting on top of [background].
  Color get surface => switch (this) {
        QuranPalette.paper => const Color(0xFFFFFFFF),
        QuranPalette.sepia => const Color(0xFFFBF0DC),
        QuranPalette.dark => const Color(0xFF1F2226),
        QuranPalette.oled => const Color(0xFF0A0A0A),
      };

  /// The ayah text: near-black brown on paper, warm off-white on dark.
  Color get text => switch (this) {
        QuranPalette.paper => const Color(0xFF2A241C),
        QuranPalette.sepia => const Color(0xFF3A2E1E),
        QuranPalette.dark => const Color(0xFFF0EAE0),
        QuranPalette.oled => const Color(0xFFF5F5F5),
      };

  /// Tafsir, secondary labels.
  Color get dim => switch (this) {
        QuranPalette.paper => const Color(0xFF5C5347),
        QuranPalette.sepia => const Color(0xFF6B5A42),
        QuranPalette.dark => const Color(0xFFA9A49B),
        QuranPalette.oled => const Color(0xFF9E9E9E),
      };

  /// Surah headers, the ayah ornament, the stop ribbon — the house green.
  Color get accent => switch (this) {
        QuranPalette.paper || QuranPalette.sepia => const Color(0xFF2F6A4F),
        QuranPalette.dark || QuranPalette.oled => const Color(0xFF7FC0A0),
      };

  /// A translucent wash behind the verse the reader stopped on.
  Color get markWash => accent.withOpacity(this == QuranPalette.oled ? 0.16 : 0.12);

  Color get divider => dim.withOpacity(this == QuranPalette.oled ? 0.22 : 0.18);
}

/// One shipped Mushaf typeface.
///
/// All three carry the full Quranic mark set (the QPC Hafs is the script of the
/// Madinah Mushaf itself). [sizeFactor] compensates for how differently the three
/// draw at the same point size, so switching font never feels like the reader
/// changed the size — only the lettering.
class QuranFont {
  const QuranFont({
    required this.key,
    required this.family,
    required this.labelAr,
    required this.labelEn,
    required this.sizeFactor,
  });

  final String key;
  final String family;
  final String labelAr;
  final String labelEn;
  final double sizeFactor;
}

/// The reading fonts, best first.
///
/// «أميري قرآن» leads for a measured reason, not a taste one. The Mus'haf text carries
/// the annotation marks — above all «۟» (U+06DF, the silent-alef mark, **3,988 of them
/// in 2,240 verses**). Measured in the font files:
///
/// | font | U+06DF glyph | height | baseline offset |
/// | --- | --- | --- | --- |
/// | Amiri Quran | small mark | 0.18em | **+0.83em** (raised) |
/// | Scheherazade | small mark | 0.20em | +0.71em (raised) |
/// | Uthmanic Hafs (this build) | disc | **0.61em** | −0.10em (on the baseline) |
///
/// So with Hafs the mark prints as a black disc sitting in the line — every other word.
/// Hafs stays available because it is the KFGQPC Mushaf face and its letters are the
/// real thing; it is simply not the one to *start* the reader on.
const List<QuranFont> kQuranFonts = <QuranFont>[
  QuranFont(
    key: 'amiri',
    family: 'AmiriQuran',
    labelAr: 'أميري قرآن',
    labelEn: 'Amiri Quran',
    sizeFactor: 0.92,
  ),
  QuranFont(
    key: 'scheherazade',
    family: 'ScheherazadeNew',
    labelAr: 'شهرزاد',
    labelEn: 'Scheherazade',
    sizeFactor: 0.94,
  ),
  QuranFont(
    key: 'uthmani',
    family: 'UthmanicHafs1Ver18',
    labelAr: 'خط المصحف (حفص)',
    labelEn: 'Mushaf (Hafs)',
    sizeFactor: 1.0,
  ),
];

/// Quranic fonts for glyphs the chosen one does not draw. Without this, a missing mark
/// is fetched from the system's Arabic font — which is how a dotted disc ended up in the
/// middle of a verse instead of the proper Mus'haf mark.
const List<String> kQuranFallback = <String>[
  'AmiriQuran',
  'ScheherazadeNew',
  'UthmanicHafs1Ver18',
];

QuranFont quranFontOf(String key) => kQuranFonts.firstWhere(
      (QuranFont font) => font.key == key,
      orElse: () => kQuranFonts.first,
    );

/// Everything the reader draws with, resolved once per rebuild.
class QuranAppearance {
  const QuranAppearance({
    required this.font,
    required this.ayahSize,
    required this.tafsirSize,
    required this.palette,
  });

  final QuranFont font;
  final double ayahSize;
  final double tafsirSize;
  final QuranPalette palette;

  double get lineHeight => 1.95;
}

/// `7` → `٧` — the digits a Mushaf uses.
String arabicDigits(int value) {
  const List<String> digits = <String>['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value
      .toString()
      .split('')
      .map((String ch) => int.tryParse(ch) == null ? ch : digits[int.parse(ch)])
      .join();
}

/// The verse text with its end-of-ayah sign and Mushaf digits.
///
// The ayah-end mark is painted, not typeset: see
// `widgets/ayah_ornament.dart` for why U+06DD was not good enough here.

/// Whether [ref] is on the page whose first verse is [marker].
bool isMarkedPage(AyahRef? marker, MushafIndex index, int page) {
  if (marker == null) return false;
  return index.pageOf(marker.surah, marker.ayah) == page;
}

/// Arabic text utilities used by Quran search and by the library parser.
///
/// Search in the Quran must be diacritic-insensitive: the Uthmani text carries
/// a harakah on almost every letter, so a user typing "الرحمن" would otherwise
/// never match "ٱلرَّحْمَٰنِ".
library;

const String _tashkeelRanges = '\u0610-\u061A\u064B-\u065F\u0670'
    '\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640';

final RegExp _tashkeel = RegExp('[$_tashkeelRanges]');
final RegExp _tatweel = RegExp('\u0640');

/// Removes harakat, Quranic annotation marks and tatweel.
String stripTashkeel(String input) =>
    input.replaceAll(_tashkeel, '').replaceAll(_tatweel, '');

/// Full normalisation for search: tashkeel + letter folding + whitespace.
///
/// Uthmani orthography writes a long ā that is **not** a real alef: «إِسْمَٰعِيلَ»
/// carries a superscript (dagger) alef U+0670 where a normal text would print a full
/// one. That single character is the whole reason Arabic search is fiddly: drop it and
/// «الرحمن» finds «ٱلرَّحْمَٰنِ», but «اسماعيل» no longer finds «إسمٰعيل»; fold it into a
/// real alef and it is the other way round. So this function takes the choice, and the
/// Quran search indexes **both** readings (see `QuranHaystack`).
String normalizeArabic(String input, {bool foldSuperscriptAlef = false}) {
  final String prepared = foldSuperscriptAlef
      ? input.replaceAll('\u0670', 'ا')
      : input;
  final String cleared = stripTashkeel(prepared).toLowerCase();
  final StringBuffer out = StringBuffer();
  for (final int rune in cleared.runes) {
    switch (rune) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0627: // ا
      case 0x0671: // ٱ (wasla)
        out.write('ا');
        break;
      case 0x0649: // ى
      case 0x064A: // ي
      case 0x0626: // ئ
        out.write('ي');
        break;
      case 0x0624: // ؤ
        out.write('و');
        break;
      case 0x0629: // ة
        out.write('ه');
        break;
      case 0x200F: // RLM
      case 0x200E: // LRM
      case 0x200B: // ZWSP
        break;
      default:
        out.writeCharCode(rune);
    }
  }
  return out
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// A light check used by the library importer to decide whether a file is
/// Arabic (and therefore whether to flip its default direction).
/// Turns Arabic-Indic digits into ASCII, so «٢:٢٥٥» parses like «2:255».
///
/// Both the standard block (٠-٩) and the extended one (۰-۹, used by Persian and
/// some Arabic keyboards) are folded, because a reader's keyboard decides which
/// one they type.
String toAsciiDigits(String input) {
  final StringBuffer out = StringBuffer();
  for (final int rune in input.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(0x30 + (rune - 0x0660));
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      out.writeCharCode(0x30 + (rune - 0x06F0));
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

bool looksArabic(String text) {
  final int sample = text.length > 400 ? 400 : text.length;
  int arabic = 0;
  for (int i = 0; i < sample; i++) {
    final int code = text.codeUnitAt(i);
    if (code >= 0x0600 && code <= 0x06FF) arabic++;
  }
  return sample > 0 && arabic / sample > 0.3;
}

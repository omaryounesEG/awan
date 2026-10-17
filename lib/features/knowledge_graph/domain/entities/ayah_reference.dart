import 'package:awan/core/utils/arabic_text.dart';

/// «2:255» as a person types it.
///
/// The picker makes a reader choose a surah from 114 rows and then an ayah from
/// up to 286 — fine for browsing, slow for someone who already knows the verse.
/// This turns what they type into the same reference, so «٢:٢٥٥» and «البقرة ٢٥٥»
/// both land on the ayah the dropdowns would have reached.
class AyahReference {
  const AyahReference(this.surah, this.ayah);

  final int surah;
  final int ayah;

  /// Digits, separators and surah names, in Arabic-Indic or ASCII.
  ///
  /// [surahIdOfName] is how a name becomes a number; the caller owns it because
  /// only the Mushaf index knows the names.
  static AyahReference? parse(
    String raw, {
    int? Function(String name)? surahIdOfName,
  }) {
    final String text = toAsciiDigits(raw).trim();
    if (text.isEmpty) return null;

    final RegExpMatch? pair =
        RegExp(r'^(\d{1,3})\s*[:/\-.,،\s]\s*(\d{1,3})$').firstMatch(text);
    if (pair != null) {
      final int surah = int.parse(pair.group(1)!);
      final int ayah = int.parse(pair.group(2)!);
      return (surah >= 1 && surah <= 114 && ayah >= 1) ? AyahReference(surah, ayah) : null;
    }

    // «البقرة ٢٥٥» — a name followed by the ayah number.
    final RegExpMatch? named = RegExp(r'^(.+?)\s+(\d{1,3})$').firstMatch(text);
    if (named != null && surahIdOfName != null) {
      final int? surah = surahIdOfName(normalizeArabic(named.group(1)!));
      final int ayah = int.parse(named.group(2)!);
      if (surah != null && ayah >= 1) return AyahReference(surah, ayah);
    }
    return null;
  }
}

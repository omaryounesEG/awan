/// The two-level reading of Arabic the checker needs, and nothing else.
///
/// Whisper does not return the mushaf's text. It returns its own spelling of
/// what it heard: a plain alef where the mushaf printed `ٱ`, a `ه` where the
/// mushaf printed `ة`, no dagger alef, and — on a good day — the vowel marks.
/// Comparing the two strings directly would report an error on every second
/// word. So the text is read twice:
///
/// * **level 1 — the skeleton**: letters only, folded to one canonical form.
///   This is what decides *which word* was said.
/// * **level 2 — the vowels**: one mark key per consonant, in order. This is
///   what decides *whether it was said correctly*.
///
/// Both levels are pure functions. No model, no database, no I/O — which is why
/// the whole checker can be tested without a microphone.
class QuranText {
  const QuranText._();

  /// Every mark that is not a vowel we compare, plus the Quranic annotation
  /// signs (`ۖ ۗ ۘ ۙ ۚ ۛ ۜ ۝ …`) that carry recitation rules but no sound.
  static final RegExp _anyMark = RegExp(
    '[\\u064B-\\u065F\\u0670\\u06D6-\\u06ED\\u08D4-\\u08FF\\u0610-\\u061A]',
  );
  static final RegExp _tatweel = RegExp('\\u0640');
  static final RegExp _space = RegExp(r'\s+');

  /// The consonant skeleton: letters only, folded.
  ///
  /// Folding choices and why:
  /// * all alef forms → `ا` (`ٱ آ أ إ ٲ ٳ`) — the mushaf's `ٱ` is a reading
  ///   mark, not a different letter, and no recogniser ever returns it;
  /// * `ى` → `ي` and `ة` → `ه` — the two spellings recognisers most often
  ///   disagree with the mushaf about, and never the source of a real mistake;
  /// * `ء` is kept: a dropped hamza *is* a mistake worth reporting.
  static String skeleton(String text) {
    final StringBuffer out = StringBuffer();
    for (final int rune in text.runes) {
      final String ch = String.fromCharCode(rune);
      if (_anyMark.hasMatch(ch) || _tatweel.hasMatch(ch)) continue;
      if (ch == ' ' || ch == '\u00A0') continue;
      final String folded = _fold(ch);
      // Keep Arabic letters only. A recogniser decorates its output with
      // commas, quotes, zero-width joiners and bidi marks, and none of them is
      // part of the word: comparing them would report a mistake on a correct
      // recitation.
      final int code = folded.runes.first;
      if (code < 0x0621 || code > 0x064A) continue;
      out.write(folded);
    }
    return out.toString();
  }

  static String _fold(String ch) {
    switch (ch) {
      case 'ٱ':
      case 'آ':
      case 'أ':
      case 'إ':
      case 'ٲ':
      case 'ٳ':
      case 'ٵ':
        return 'ا';
      case 'ى':
      case 'ئ':
        return 'ي';
      case 'ة':
        return 'ه';
      case 'ؤ':
        return 'و';
      default:
        return ch;
    }
  }

  /// One mark key per consonant, in the same order as [skeleton].
  ///
  /// Keys: `a u i` short vowels, `an un in` tanween, `0` sukun, `~` shadda
  /// (written before the vowel, `~a`), `A` the dagger alef, `^` madda.
  static List<String> marks(String text) {
    final List<String> out = <String>[];
    final StringBuffer pending = StringBuffer();

    for (final int rune in text.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == ' ' || ch == '\u00A0') continue;
      if (_tatweel.hasMatch(ch)) continue;

      final String? key = _markKey(ch);
      if (key != null) {
        pending.write(key);
        continue;
      }
      if (_anyMark.hasMatch(ch)) continue; // a recitation sign, not a vowel

      // A consonant: close the previous letter with whatever marks preceded it.
      if (out.isNotEmpty) out[out.length - 1] = out.last + _canonical(pending.toString());
      pending.clear();
      out.add('');
    }
    if (out.isNotEmpty) out[out.length - 1] = out.last + _canonical(pending.toString());
    return out;
  }

  /// Order matters when two marks share a letter, and the two spellings
  /// (`رَبِّ` with kasra first, `رَبِّ` with shadda first) are the same sound.
  /// Canonical form: doubling first, then the vowel.
  static String _canonical(String marks) {
    if (marks.length < 2) return marks;
    final StringBuffer doubling = StringBuffer();
    final StringBuffer vowels = StringBuffer();
    for (final int rune in marks.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == '~' || ch == '^') {
        doubling.write(ch);
      } else {
        vowels.write(ch);
      }
    }
    return doubling.toString() + vowels.toString();
  }

  static String? _markKey(String ch) {
    switch (ch) {
      case '\u064E':
        return 'a';
      case '\u064F':
        return 'u';
      case '\u0650':
        return 'i';
      case '\u064B':
        return 'an';
      case '\u064C':
        return 'un';
      case '\u064D':
        return 'in';
      case '\u0652':
        return '0';
      case '\u0651':
        return '~';
      case '\u0670':
        return 'A';
      case '\u0653':
        return '^';
      default:
        return null;
    }
  }

  /// Splits a verse into displayable words, keeping the marks.
  static List<String> words(String ayah) => ayah
      .split(_space)
      .map((String w) => w.trim())
      .where((String w) => w.isNotEmpty)
      .toList();

  /// Whether a recognised word carries any vowel at all. Whisper sometimes
  /// returns bare consonants; a checker that then reports a vowel error would
  /// be inventing one.
  static bool hasVowels(String text) => marks(text).any((String m) => m.isNotEmpty);

  /// The last letter's vowel, the one an i'rab mistake lands on.
  static String? finalVowel(List<String> marks) {
    if (marks.isEmpty) return null;
    final String last = marks.last;
    final StringBuffer vowels = StringBuffer();
    for (final int rune in last.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == '~' || ch == 'A' || ch == '^') continue;
      vowels.write(ch);
    }
    return vowels.isEmpty ? null : vowels.toString();
  }

  /// A word pair's letter similarity in [0, 1] — 1 means identical skeletons.
  ///
  /// Used only to decide *whether* two words are the same word heard badly, so
  /// it can be crude; the verdict itself is decided by exact equality.
  static double similarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final int distance = levenshtein(a, b);
    return 1 - distance / (a.length > b.length ? a.length : b.length);
  }

  /// Plain Levenshtein distance over code points.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final List<int> ra = a.runes.toList();
    final List<int> rb = b.runes.toList();
    List<int> previous = List<int>.generate(rb.length + 1, (int i) => i);
    List<int> current = List<int>.filled(rb.length + 1, 0);

    for (int i = 0; i < ra.length; i++) {
      current[0] = i + 1;
      for (int j = 0; j < rb.length; j++) {
        final int cost = ra[i] == rb[j] ? 0 : 1;
        final int deletion = previous[j + 1] + 1;
        final int insertion = current[j] + 1;
        final int substitution = previous[j] + cost;
        int best = deletion < insertion ? deletion : insertion;
        if (substitution < best) best = substitution;
        current[j + 1] = best;
      }
      final List<int> swap = previous;
      previous = current;
      current = swap;
    }
    return previous[rb.length];
  }
}

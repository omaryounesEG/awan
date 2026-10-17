import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';

/// Maps between `سورة:آية` and the app-wide Mushaf number (1..6236).
///
/// The Mutashabihat corpus addresses ayat by that number — `2:2` is 9, `55:13` is
/// 4914 — and the app's own surah table (each `Surah` carries its `ayahCount`)
/// reproduces the numbering exactly: checked against all 5,003 references in the
/// bundled corpus, zero disagreements. That check is what makes it safe to tint a
/// verse in the reader from a corpus id.
class MushafNumbering {
  MushafNumbering._(this._offsets, this._starts, this._counts, this._total);

  /// `_total` is the number of ayat the table covers: 6236 for the full Quran.
  final int _total;

  /// Builds the table from the surah list the Quran asset already carries.
  factory MushafNumbering.fromSurahs(List<Surah> surahs) {
    final Map<int, int> offsets = <int, int>{};
    final List<int> starts = <int>[0]; // index 0 is unused: surah ids are 1-based
    final List<int> counts = <int>[0];
    int running = 0;
    for (final Surah surah in surahs) {
      offsets[surah.id] = running;
      starts.add(running + 1); // this surah's first absolute id
      counts.add(surah.ayahCount);
      running += surah.ayahCount;
    }
    return MushafNumbering._(offsets, starts, counts, running);
  }

  /// An empty table, for the frames before the Quran asset has loaded.
  factory MushafNumbering.empty() =>
      MushafNumbering._(const <int, int>{}, const <int>[0], const <int>[0], 0);

  final Map<int, int> _offsets;

  /// `_starts[i]` is the first absolute id of surah `i + 1`.
  final List<int> _starts;

  /// `_counts[i]` is the ayah count of surah `i + 1`.
  final List<int> _counts;

  bool get isReady => _counts.length > 1;

  /// The absolute id of `surah:ayah`, or 0 when the surah is unknown.
  int idOf(int surah, int ayah) {
    final int? offset = _offsets[surah];
    if (offset == null) {
      return 0;
    }
    return offset + ayah;
  }

  /// The `(surah, ayah)` an absolute id points at, or `null` outside 1..6236.
  ({int surah, int ayah})? locate(int absoluteId) {
    if (absoluteId < 1 || _counts.length < 2) {
      return null;
    }
    for (int surah = 1; surah < _counts.length; surah++) {
      final int first = _starts[surah];
      final int count = _counts[surah];
      if (absoluteId >= first && absoluteId < first + count) {
        return (surah: surah, ayah: absoluteId - first + 1);
      }
    }
    return null;
  }

  /// The ayah count of a surah, or 0 when unknown.
  int ayahCountOf(int surah) =>
      (surah >= 1 && surah < _counts.length) ? _counts[surah] : 0;

  /// How many ayat the table covers (6236 on the full Quran asset).
  int get totalAyahs => _total;
}

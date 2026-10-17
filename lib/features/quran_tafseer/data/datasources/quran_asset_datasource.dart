import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
/// Reads the bundled Uthmani text.
///
/// The JSON asset is decoded **inside an isolate** (≈1.4 MB of UTF-8 with heavy
/// diacritics would otherwise cost a frame or two on a cold start) and then
/// kept in memory for the life of the process.
class QuranLocalDataSource {
  QuranLocalDataSource({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  QuranText? _cache;
  MushafIndex? _indexCache;
  final Map<int, TafsirText> _tafsirCache = <int, TafsirText>{};

  QuranText? get cached => _cache;

  Future<QuranText> load() async {
    final QuranText? cached = _cache;
    if (cached != null) return cached;

    final String raw = await _bundle.loadString(AppConstants.quranAsset);
    final QuranText parsed = await Isolate.run(() => _parse(raw));
    _cache = parsed;
    return parsed;
  }

  /// The page/juz map (≈84 KB). Loaded on demand: the surah list does not need it,
  /// only the paged reader and the page marker do.
  Future<MushafIndex> loadIndex() async {
    final MushafIndex? cached = _indexCache;
    if (cached != null) return cached;

    final String raw = await _bundle.loadString(AppConstants.quranIndexAsset);
    final MushafIndex parsed = await Isolate.run(() => _parseIndex(raw));
    _indexCache = parsed;
    return parsed;
  }

  /// One tafsir edition. The bundled Muyassar is the default; downloadable add-ons
  /// land in the same shape and are read through this same path.
  Future<TafsirText> loadTafsir(int id) async {
    final TafsirText? cached = _tafsirCache[id];
    if (cached != null) return cached;

    final String raw = await _bundle.loadString(
      id == AppConstants.tafsirMuyassarId
          ? AppConstants.bundledTafsirAsset
          : AppConstants.tafsirAddonAsset(id),
    );
    final TafsirText parsed = await Isolate.run(() => _parseTafsir(raw, id));
    _tafsirCache[id] = parsed;
    return parsed;
  }

  static MushafIndex _parseIndex(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic> rows = json['index'] as Map<String, dynamic>;
    final Map<int, List<AyahPosition>> bySurah = <int, List<AyahPosition>>{
      for (final MapEntry<String, dynamic> entry in rows.entries)
        int.parse(entry.key): <AyahPosition>[
          for (final Object? row in entry.value as List<dynamic>)
            AyahPosition(
              page: (row as List<dynamic>)[0] as int,
              juz: row[1] as int,
              hizb: row[2] as int,
              sajda: row[3] as int,
            ),
        ],
    };
    return MushafIndex(
      bySurah: bySurah,
      totalPages: json['pages'] as int? ?? 604,
    );
  }

  static TafsirText _parseTafsir(String raw, int fallbackId) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic> rows = json['ayahs'] as Map<String, dynamic>;
    return TafsirText(
      id: (json['id'] as int?) ?? fallbackId,
      name: json['name'] as String? ?? '',
      author: json['author'] as String? ?? '',
      source: json['source'] as String? ?? '',
      ayahs: <String, String>{
        for (final MapEntry<String, dynamic> entry in rows.entries)
          entry.key: entry.value as String,
      },
    );
  }

  static QuranText _parse(String raw) {
    final Map<String, dynamic> json =
        jsonDecode(raw) as Map<String, dynamic>;

    final List<Surah> surahs = <Surah>[
      for (final Object? item in json['surahs'] as List<dynamic>)
        Surah(
          id: (item as Map<String, dynamic>)['id'] as int,
          nameAr: item['name_ar'] as String,
          nameEn: item['name_en'] as String,
          translatedName: item['translated_en'] as String? ?? '',
          place: item['place'] as String? ?? 'makkah',
          ayahCount: item['ayah_count'] as int,
          bismillahPre: item['bismillah_pre'] as bool? ?? false,
        ),
    ];

    final Map<String, dynamic> rawAyahs =
        json['ayahs'] as Map<String, dynamic>;
    final Map<int, List<String>> ayahs = <int, List<String>>{
      for (final MapEntry<String, dynamic> entry in rawAyahs.entries)
        int.parse(entry.key):
            (entry.value as List<dynamic>).map((Object? e) => e as String).toList(),
    };

    return QuranText(surahs: surahs, ayahs: ayahs);
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/quran_text.dart';

/// The mushaf, read straight from the asset the app already ships.
///
/// The word tables in SQLite are the long-term home for this (see
/// [QuranWordDatabase]), but building 78,000 rows takes minutes on a slow
/// phone — and nobody should watch a spinner before their first ayah. So the
/// session reads the verse from the JSON in memory (one parse, ~100 ms) and the
/// database is filled in the background for the features that need to search it.
///
/// This is the same text, split the same way: `QuranText.words` is the single
/// definition of "a word" in the whole feature.
class MushafSource {
  MushafSource();

  Map<String, dynamic>? _ayat;
  List<SurahMeta>? _surahs;

  Future<void> _load() async {
    if (_ayat != null) return;
    final String raw = await rootBundle.loadString('assets/data/quran_uthmani.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    _ayat = data['ayahs'] as Map<String, dynamic>;
    _surahs = <SurahMeta>[
      for (final dynamic entry in (data['surahs'] as List<dynamic>? ?? <dynamic>[]))
        SurahMeta(
          id: (entry as Map<String, dynamic>)['id'] as int,
          nameAr: entry['name_ar'] as String? ?? '',
          nameEn: entry['name_en'] as String? ?? '',
          ayahCount: entry['ayah_count'] as int? ?? 0,
        ),
    ];
  }

  Future<List<SurahMeta>> surahs() async {
    await _load();
    return _surahs!;
  }

  Future<String?> ayahText(int surah, int ayah) async {
    await _load();
    final List<dynamic>? list = _ayat!['$surah'] as List<dynamic>?;
    if (list == null || ayah < 1 || ayah > list.length) return null;
    return (list[ayah - 1] as String).trim();
  }

  Future<List<RecitationWord>> words(int surah, int ayah) async {
    final String? text = await ayahText(surah, ayah);
    if (text == null) return <RecitationWord>[];
    final List<String> display = QuranText.words(text);
    return <RecitationWord>[
      for (int i = 0; i < display.length; i++)
        RecitationWord(
          index: i,
          uthmani: display[i],
          consonants: QuranText.skeleton(display[i]),
          marks: QuranText.marks(display[i]),
        ),
    ];
  }

  /// The previous ayah's text — the `initial_prompt` material.
  Future<String?> contextBefore(int surah, int ayah) async {
    if (ayah > 1) return ayahText(surah, ayah - 1);
    if (surah <= 1) return null;
    final List<SurahMeta> all = await surahs();
    final SurahMeta previous = all.firstWhere(
      (SurahMeta s) => s.id == surah - 1,
      orElse: () => all.first,
    );
    return ayahText(previous.id, previous.ayahCount);
  }
}

class SurahMeta {
  const SurahMeta({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahCount,
  });
  final int id;
  final String nameAr;
  final String nameEn;
  final int ayahCount;
}

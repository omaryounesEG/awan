import 'package:flutter/foundation.dart';

/// Which half of the day a dhikr belongs to. The same chapter holds both; the
/// reader works through one at a time, and the two are tracked separately
/// because «أذكار الصباح» finished is not «أذكار المساء» finished.
enum AdhkarSession { morning, evening }

/// One dhikr, with its own voice.
///
/// `repeat` is how many times the page itself asks for it (three, seven, a
/// hundred). The counter in the UI counts up to it and stops: a task with a
/// known end is a task that can be finished.
@immutable
class AdhkarItem {
  const AdhkarItem({
    required this.id,
    required this.repeat,
    required this.audioUrl,
    required this.ar,
    required this.en,
  });

  final int id;
  final int repeat;
  final String audioUrl;
  final String ar;
  final String en;

  String textFor(String localeCode) =>
      localeCode == 'en' ? (en.isEmpty ? ar : en) : ar;

  /// A rough spoken length, used only to pre-size the audio progress bar.
  static const Duration unknownLength = Duration.zero;

  static AdhkarItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    if (id is! num) return null;
    return AdhkarItem(
      id: id.toInt(),
      repeat: (raw['repeat'] as num?)?.toInt().clamp(1, 1000) ?? 1,
      audioUrl: '${raw['audio'] ?? ''}',
      ar: '${raw['ar'] ?? ''}'.trim(),
      en: '${raw['en'] ?? ''}'.trim(),
    );
  }
}

/// The bundled chapter, read once.
@immutable
class AdhkarChapter {
  const AdhkarChapter({
    required this.titleAr,
    required this.titleEn,
    required this.items,
  });

  final String titleAr;
  final String titleEn;
  final List<AdhkarItem> items;

  String titleFor(String localeCode) => localeCode == 'en' ? titleEn : titleAr;
}

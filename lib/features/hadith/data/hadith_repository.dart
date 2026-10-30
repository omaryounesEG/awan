import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:awan/features/hadith/domain/entities/hadith.dart';

/// The four books, read once from the compressed asset.
///
/// The asset is a gzip of a 27 MB JSON and unpacks to 24,065 hadiths; parsing
/// and normalising that on the UI isolate would stall the first frame, so both
/// happen in [compute] and the finished corpus is handed back.
class HadithRepository {
  static const String assetPath = 'assets/hadith/hadith_v1.json.gz';

  HadithCorpus? _corpus;

  Future<HadithCorpus> load() async {
    final HadithCorpus? cached = _corpus;
    if (cached != null) return cached;
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final HadithCorpus parsed = await compute(_parse, bytes);
    _corpus = parsed;
    return parsed;
  }

  /// Overwrites the in-memory copy — used by tests that build a tiny corpus.
  @visibleForTesting
  set corpus(HadithCorpus value) => _corpus = value;
}

HadithCorpus _parse(Uint8List bytes) {
  final String raw = utf8.decode(GZipCodec().decode(bytes));
  final Object? decoded = jsonDecode(raw);
  final Map<String, Object?> doc =
      decoded is Map ? decoded.cast<String, Object?>() : const <String, Object?>{};

  final List<HadithBook> books = <HadithBook>[
    for (final Object? row in (doc['books'] as List<Object?>?) ?? const <Object?>[])
      if (row is Map) HadithBook.fromJson(row.cast<String, Object?>()),
  ];
  final List<Object?> rows =
      (doc['hadiths'] as List<Object?>?) ?? const <Object?>[];
  final List<Hadith> hadiths = <Hadith>[
    for (int i = 0; i < rows.length; i++)
      if (rows[i] is Map)
        Hadith.fromJson(i, (rows[i] as Map).cast<String, Object?>()),
  ];
  final List<String> search = <String>[
    for (final Hadith hadith in hadiths) normalizeArabic(hadith.text),
  ];

  return HadithCorpus(
    books: books,
    hadiths: hadiths,
    search: search,
    gradeLabels: <String>[
      for (final Object? label in (doc['gradeLabels'] as List<Object?>?) ?? const <Object?>[])
        '${label ?? ''}',
    ],
  );
}

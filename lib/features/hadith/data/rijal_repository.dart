import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/domain/entities/narrator.dart';

/// The narrator index, parsed once in an isolate.
///
/// Twenty-three thousand names normalised at load: cheap to do once, too
/// expensive to redo on every keystroke.
class RijalRepository {
  RijalIndex? _index;

  Future<RijalIndex> load() async {
    final RijalIndex? cached = _index;
    if (cached != null) return cached;
    final ByteData raw = await rootBundle.load('assets/hadith/rijal_v1.json.gz');
    final RijalIndex parsed = await compute(_parse, raw.buffer.asUint8List());
    _index = parsed;
    return parsed;
  }
}

RijalIndex _parse(Uint8List bytes) {
  final Map<String, dynamic> doc =
      jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  final List<Object?> rows = (doc['narrators'] as List<Object?>?) ?? const <Object?>[];
  final List<Narrator> narrators = <Narrator>[
    for (final Object? row in rows)
      if (row is List) Narrator.fromJson(row),
  ];
  return RijalIndex(
    categories: <String>[
      for (final Object? label in (doc['categories'] as List<Object?>?) ?? const <Object?>[])
        '$label',
    ],
    narrators: narrators,
    search: <String>[for (final Narrator n in narrators) normalizeArabic(n.name)],
    note: '${doc['note'] ?? ''}',
  );
}

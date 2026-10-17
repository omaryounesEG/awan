import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/semantic_search/data/datasources/semantic_index.dart';
import 'package:awan/features/semantic_search/data/datasources/sentencepiece_unigram.dart';
import 'package:awan/features/semantic_search/domain/usecases/fuse_rankings.dart';

/// The Dart tokenizer must produce the *same ids* as the SentencePiece model
/// that built the index. If it drifts, queries embed into a different space and
/// the search silently returns noise — so the fixture is generated from Python
/// (`tools/semantic/_gen_fixture.py`) and compared id by id.
void main() {
  late SentencePieceUnigram tokenizer;

  setUpAll(() {
    final Map<String, dynamic> vocabulary = jsonDecode(
      File('assets/semantic/tokenizer.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    tokenizer = SentencePieceUnigram.fromJson(vocabulary);
  });

  test('tokenises Arabic exactly like SentencePiece', () {
    final Map<String, dynamic> fixture = jsonDecode(
      File('test/fixtures/sentencepiece_samples.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    for (final dynamic raw in fixture['samples'] as List<dynamic>) {
      final Map<String, dynamic> sample = raw as Map<String, dynamic>;
      final List<int> expected =
          (sample['ids'] as List<dynamic>).map((dynamic v) => v as int).toList();
      expect(
        tokenizer.encode(sample['text'] as String),
        expected,
        reason: 'tokens for «${sample['text']}»',
      );
    }
  });

  test('the encoder buffer always has the shape the graph expects', () {
    final ({List<int> ids, List<int> mask}) encoded =
        tokenizer.encodeForEncoder('الصبر عند فقدان العمل', maxLength: 128);
    expect(encoded.ids.length, 128);
    expect(encoded.mask.length, 128);
    expect(encoded.ids.first, 0, reason: 'a <s> token opens the sequence');
    expect(encoded.mask.first, 1);
    expect(encoded.mask.where((int v) => v == 1).length, greaterThan(2));
  });

  group('reciprocal rank fusion', () {
    const FuseRankings fuse = FuseRankings();

    test('a verse found by both halves outranks one found by either', () {
      final List<FusedKey> fused = fuse(
        semanticKeys: <String>['2:1', '3:7'],
        lexicalKeys: <String>['2:1', '4:5'],
      );
      expect(fused.first.key, '2:1');
      expect(fused.first.semanticRank, 1);
      expect(fused.first.lexicalRank, 1);
    });

    test('the score is the sum of both reciprocal ranks', () {
      final List<FusedKey> fused = fuse(
        semanticKeys: <String>['2:1'],
        lexicalKeys: <String>['2:1'],
        k: 60,
      );
      expect(fused.single.score, closeTo(2 / 61, 1e-9));
    });

    test('ties fall back to mushaf order, not to list order', () {
      final List<FusedKey> fused = fuse(
        semanticKeys: <String>['9:5'],
        lexicalKeys: <String>['18:1'],
      );
      // 9:5 scores 1/61 and 18:1 scores 1/61 as well; the earlier surah wins.
      expect(fused.first.key, '9:5');
      expect(fused[1].key, '18:1');
    });
  });

  group('the vector index', () {
    test('finds the row that points the same way, and only that one', () {
      // Three rows of two dimensions: only row 1 is close to (1, 0).
      final SemanticIndex index = SemanticIndex.fromBytes(
        vectors: Uint8List.fromList(<int>[127, 0, 0, 127, -127, 0]),
        scales: _floatBytes(<double>[1 / 127, 1 / 127, 1 / 127]),
        manifestJson: jsonEncode(<String, dynamic>{
          'dim': 2,
          'count': 3,
          'rows': <Map<String, int>>[
            <String, int>{'s': 1, 'a': 1},
            <String, int>{'s': 2, 'a': 1},
            <String, int>{'s': 3, 'a': 1},
          ],
        }),
      );

      final List<ScoredRow> best =
          index.search(Float64List.fromList(<double>[1, 0]), limit: 1);

      expect(best.single.index, 0);
      expect(best.single.score, closeTo(1, 1e-6));
      expect(index.row(best.single.index).surah, 1);
    });
  });

  test('the real index answers a real query vector with real verses', () {
    final Map<String, dynamic> fixture = jsonDecode(
      File('test/fixtures/query_vectors.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final SemanticIndex index = SemanticIndex.fromBytes(
      vectors: File('assets/semantic/quran_vecs.i8').readAsBytesSync(),
      scales: File('assets/semantic/quran_scales.f32').readAsBytesSync(),
      manifestJson: File('assets/semantic/quran_index.json').readAsStringSync(),
    );

    List<String> top(String query, {int limit = 10}) {
      final List<double> raw = (fixture[query] as List<dynamic>)
          .map((dynamic v) => (v as num).toDouble())
          .toList();
      return <String>[
        for (final ScoredRow row
            in index.search(Float64List.fromList(raw), limit: limit))
          '${index.row(row.index).surah}:${index.row(row.index).ayah}',
      ];
    }

    // «الصبر عند فقدان العمل» → the patience verses.
    final List<String> patience = top('الصبر عند فقدان العمل');
    expect(
      patience
          .where((String key) =>
              <String>['2:153', '2:155', '2:156', '103:3', '94:5', '94:6']
                  .contains(key))
          .length,
      greaterThanOrEqualTo(2),
      reason: 'top 10 was $patience',
    );

    // «أجر من ينفق على الفقراء» → the spending verses.
    final List<String> spending = top('أجر من ينفق على الفقراء');
    expect(
      spending
          .where((String key) =>
              <String>['2:261', '2:274', '2:273', '9:60', '76:8'].contains(key))
          .length,
      greaterThanOrEqualTo(2),
      reason: 'top 10 was $spending',
    );

    // A different question must not return the same first verse.
    expect(top('دعاء عند القلق والخوف').first, isNot(patience.first));
  });
}

Uint8List _floatBytes(List<double> values) {
  final Float32List floats = Float32List.fromList(values);
  return floats.buffer.asUint8List();
}

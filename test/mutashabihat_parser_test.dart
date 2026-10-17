import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/knowledge_graph/data/datasources/mutashabihat_json_parser.dart';
import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';

/// The corpus is a generated file the app cannot validate at build time, so the
/// parser's tolerance is a feature and is tested as one.
void main() {
  test('parses the generated shape into nodes with embedded targets', () {
    const String json = """
[
  {
    "source_absolute_id": 9,
    "source_surah_number": 2,
    "source_ayah_number": 2,
    "source_text": "ذَٰلِكَ ٱلْكِتَـٰبُ",
    "targets": [
      {
        "target_absolute_id": 183,
        "target_surah_number": 2,
        "target_ayah_number": 176,
        "target_text": "ذَٰلِكَ بِأَنَّ ٱللَّهَ",
        "rule_text": "موضع التشابه: ذلك | (بداية الآية)"
      }
    ]
  }
]
""";

    final List<MutashabihNode> nodes = parseMutashabihatCorpus(json);

    expect(nodes, hasLength(1));
    final MutashabihNode node = nodes.single;
    expect(node.sourceAbsoluteId, 9);
    expect(node.id, 9, reason: 'the ayah id is the Isar id, which is what makes get() O(1)');
    expect(node.sourceSurahNumber, 2);
    expect(node.sourceAyahNumber, 2);
    expect(node.targets, hasLength(1));
    expect(node.targets.single.targetAbsoluteId, 183);
    expect(node.targets.single.ruleText, contains('موضع التشابه'));
  });

  test('accepts a node with no targets and keeps it on the graph as a leaf', () {
    const String json = '[{"source_absolute_id": 12, "source_surah_number": 2, '
        '"source_ayah_number": 5, "source_text": "x", "targets": []}]';
    final List<MutashabihNode> nodes = parseMutashabihatCorpus(json);
    expect(nodes, hasLength(1));
    expect(nodes.single.targets, isEmpty);
  });

  test('skips entries with no usable id, and drops targets that have none', () {
    const String json = """
[
  {"source_surah_number": 2, "source_ayah_number": 2, "source_text": "no id", "targets": []},
  {"source_absolute_id": 0, "source_surah_number": 2, "targets": []},
  {"source_absolute_id": 15, "source_surah_number": 3, "source_ayah_number": 1,
   "source_text": "kept", "targets": [
      {"target_surah_number": 3, "target_ayah_number": 2, "target_text": "no id"},
      {"target_absolute_id": 16, "target_surah_number": 3, "target_ayah_number": 2,
       "target_text": "kept", "rule_text": "r"}
   ]}
]
""";
    final List<MutashabihNode> nodes = parseMutashabihatCorpus(json);
    expect(nodes, hasLength(1));
    expect(nodes.single.sourceAbsoluteId, 15);
    expect(nodes.single.sourceText, 'kept');
    expect(nodes.single.targets, hasLength(1));
    expect(nodes.single.targets.single.targetAbsoluteId, 16);
  });

  test('keeps the first occurrence of a duplicate id', () {
    const String json = """
[
  {"source_absolute_id": 20, "source_surah_number": 2, "source_ayah_number": 1,
   "source_text": "first", "targets": []},
  {"source_absolute_id": 20, "source_surah_number": 2, "source_ayah_number": 1,
   "source_text": "second", "targets": []}
]
""";
    final List<MutashabihNode> nodes = parseMutashabihatCorpus(json);
    expect(nodes, hasLength(1));
    expect(nodes.single.sourceText, 'first');
  });

  test('fills missing numbers with 0 instead of throwing', () {
    const String json = '[{"source_absolute_id": 30, "source_text": "only the id", "targets": []}]';
    final List<MutashabihNode> nodes = parseMutashabihatCorpus(json);
    expect(nodes.single.sourceSurahNumber, 0);
    expect(nodes.single.sourceAyahNumber, 0);
  });

  test('rejects a payload that is not a list', () {
    expect(() => parseMutashabihatCorpus('{"nodes": []}'), throwsFormatException);
  });
}

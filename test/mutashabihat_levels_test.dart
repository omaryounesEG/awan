import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';

MutashabihTargetEntry _target(int id, String rule) => MutashabihTargetEntry(
      targetAbsoluteId: id,
      targetSurahNumber: 2,
      targetAyahNumber: id,
      targetText: 'نص',
      ruleText: rule,
    );

MutashabihNodeEntry _node(List<MutashabihTargetEntry> targets) =>
    MutashabihNodeEntry(
      sourceAbsoluteId: 9,
      sourceSurahNumber: 2,
      sourceAyahNumber: 2,
      sourceText: 'نص المصدر',
      targets: targets,
    );

void main() {
  group('sharedPhrase', () {
    test('lifts the wording out of the rule', () {
      expect(
        _target(1, 'موضع التشابه: ذلك | (بداية الآية)').sharedPhrase,
        'ذلك',
      );
      expect(
        _target(1, 'تطابق 31 اية | موضع التشابه: فبأي الاء ربكما تكذبان | (بداية الآية)')
            .sharedPhrase,
        'فبأي الاء ربكما تكذبان',
      );
    });

    test('takes the first of two positions in one rule', () {
      expect(
        _target(
          1,
          'موضع التشابه: واتقوا يوما | (بداية الآية) ؛ موضع التشابه: ولا هم ينصرون | (نهاية الآية)',
        ).sharedPhrase,
        'واتقوا يوما',
      );
    });

    test('falls back to the whole rule when there is no position marker', () {
      expect(_target(1, 'الضابط: تكرار').sharedPhrase, 'الضابط: تكرار');
    });
  });

  group('orderedTargets', () {
    final MutashabihNodeEntry node = _node(<MutashabihTargetEntry>[
      _target(30, 'موضع التشابه: ذلك | (بداية الآية)'), // 3
      _target(12, 'موضع التشابه: ولا هم ينصرون | (نهاية الآية)'), // 15
      _target(12 + 1, 'موضع التشابه: ولا هم ينصرون | (نهاية الآية)'), // 15, tie
    ]);

    test('puts the longest shared phrase first, ties in Mushaf order', () {
      final List<MutashabihTargetEntry> ordered = node.orderedTargets();
      expect(
        ordered.map((MutashabihTargetEntry t) => t.targetAbsoluteId).toList(),
        <int>[12, 13, 30],
      );
    });

    test('a level cuts the list to its strongest matches', () {
      final List<MutashabihTargetEntry> two = node.orderedTargets(limit: 2);
      expect(two.length, 2);
      expect(two.first.targetAbsoluteId, 12);
    });

    test('a level larger than the node keeps everything', () {
      expect(node.orderedTargets(limit: 10).length, 3);
      expect(node.orderedTargets(limit: 0).length, 0);
    });

    test('withTargets keeps the source and swaps the list', () {
      final MutashabihNodeEntry cut = node.withTargets(node.orderedTargets(limit: 1));
      expect(cut.sourceAbsoluteId, 9);
      expect(cut.sourceText, 'نص المصدر');
      expect(cut.targetCount, 1);
      expect(node.targetCount, 3, reason: 'the original node is untouched');
    });
  });

  // The corpus in the app is what the levels sort; a phrase that came back empty
  // would silently sort every target equally.
  test('every rule in the shipped corpus yields a phrase and a strength', () {
    final File corpus = File('assets/data/mutashabihat_data_normalized.json');
    if (!corpus.existsSync()) {
      markTestSkipped('the corpus asset is not next to the test runner');
      return;
    }

    final List<dynamic> nodes = jsonDecode(corpus.readAsStringSync()) as List<dynamic>;
    int rules = 0;
    final List<String> empty = <String>[];
    for (final dynamic raw in nodes) {
      for (final dynamic t in ((raw as Map<String, dynamic>)['targets'] as List<dynamic>)) {
        final MutashabihTargetEntry entry = MutashabihTargetEntry(
          targetAbsoluteId: ((t as Map<String, dynamic>)['target_absolute_id'] as num).toInt(),
          targetSurahNumber: (t['target_surah_number'] as num).toInt(),
          targetAyahNumber: (t['target_ayah_number'] as num).toInt(),
          targetText: (t['target_text'] as String?) ?? '',
          ruleText: (t['rule_text'] as String?) ?? '',
        );
        rules++;
        if (entry.sharedPhrase.isEmpty || entry.matchStrength == 0) {
          empty.add(entry.ruleText);
        }
      }
    }

    // Not an exact count: الكسائي's «مشتبهات القرآن» prunes the links that rest
    // on one or two shared words, so the total moves with the corpus on purpose.
    expect(rules, greaterThan(2000));
    expect(empty, isEmpty);
  });
}

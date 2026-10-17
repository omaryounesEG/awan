import 'dart:convert';

import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';

/// Turns the bundled Mutashabihat corpus into Isar rows.
///
/// Deliberately a **top-level** function so it can be handed to `compute`: the
/// corpus is 2.7 MB of Uthmani text, and decoding it on the UI isolate costs
/// visible frames on the first launch. The function owns no state and touches no
/// database — the caller writes the rows, because Isar takes one writer.
///
/// It is tolerant by design (the file is generated, and a generator that changes
/// a key should not white-screen the app): an entry without an id or with no
/// text is skipped, an entry with no targets is kept, and an unknown extra key is
/// ignored. Duplicate ids keep the **first** occurrence, so the corpus' own order
/// wins rather than whichever write landed last.
List<MutashabihNode> parseMutashabihatCorpus(String rawJson) {
  final dynamic decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    throw const FormatException('Mutashabihat corpus must be a JSON list of nodes');
  }

  final Map<int, MutashabihNode> byId = <int, MutashabihNode>{};

  for (final dynamic entry in decoded) {
    if (entry is! Map) continue;

    final int? id = _asInt(entry['source_absolute_id']);
    if (id == null || id <= 0) continue;

    final List<MutashabihTarget> targets = <MutashabihTarget>[];
    final dynamic rawTargets = entry['targets'];
    if (rawTargets is List) {
      for (final dynamic rawTarget in rawTargets) {
        if (rawTarget is! Map) continue;
        final int? targetId = _asInt(rawTarget['target_absolute_id']);
        if (targetId == null || targetId <= 0) continue;
        targets.add(
          MutashabihTarget()
            ..targetAbsoluteId = targetId
            ..targetSurahNumber = _asInt(rawTarget['target_surah_number']) ?? 0
            ..targetAyahNumber = _asInt(rawTarget['target_ayah_number']) ?? 0
            ..targetText = _asString(rawTarget['target_text'])
            ..ruleText = _asString(rawTarget['rule_text']),
        );
      }
    }

    byId.putIfAbsent(
      id,
      () => MutashabihNode()
        ..sourceAbsoluteId = id
        ..sourceSurahNumber = _asInt(entry['source_surah_number']) ?? 0
        ..sourceAyahNumber = _asInt(entry['source_ayah_number']) ?? 0
        ..sourceText = _asString(entry['source_text'])
        ..targets = targets,
    );
  }

  return byId.values.toList(growable: false);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _asString(dynamic value) => value is String ? value : '';

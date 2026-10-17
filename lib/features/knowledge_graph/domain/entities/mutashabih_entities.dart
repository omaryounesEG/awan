/// Graph nodes and edges of the Mutashabihat corpus, as the rest of the app
/// sees them (no Isar, no JSON).
///
/// The corpus is *directed and shallow*: every node is one ayah, and its edges
/// point at the other ayat that share a wording with it. Whoever generated it
/// has already decided which side is the "source" and recorded the shared
/// position in `ruleText` (الضابط) — so this layer carries the rule as data
/// rather than trying to re-derive it.
library;

/// One similar ayah, plus the rule that ties it to the source.
class MutashabihTargetEntry {
  const MutashabihTargetEntry({
    required this.targetAbsoluteId,
    required this.targetSurahNumber,
    required this.targetAyahNumber,
    required this.targetText,
    required this.ruleText,
  });

  /// The ayah's id in the app-wide Mushaf numbering (1..6236), which is also
  /// this node's id if the graph is opened on it.
  final int targetAbsoluteId;
  final int targetSurahNumber;
  final int targetAyahNumber;

  /// The Uthmani text of the similar ayah.
  final String targetText;

  /// Why the two ayat are considered similar — e.g.
  /// `موضع التشابه: ذلك | (بداية الآية)`.
  final String ruleText;

  /// The wording the two ayat share, lifted out of [ruleText] — «ذلك» in the
  /// example above.
  ///
  /// The corpus records the reason as prose, not as a score, so callers that
  /// want to rank or group targets read it from here instead of re-parsing it.
  ///
  /// A rule may describe more than one position — `… | (بداية الآية) ؛ موضع
  /// التشابه: …` — so this takes the *first* position: the earliest of the `|`
  /// and `؛` separators ends it. 64 of the 3,705 rules in the shipped corpus are
  /// of that two-position kind.
  String get sharedPhrase {
    const String marker = 'موضع التشابه:';
    final int at = ruleText.indexOf(marker);
    if (at < 0) {
      return ruleText.trim();
    }
    final String rest = ruleText.substring(at + marker.length);
    final int bar = rest.indexOf('|');
    final int semicolon = rest.indexOf('؛');
    final int end = <int>[bar, semicolon].where((int i) => i >= 0).fold(
          rest.length,
          (int acc, int i) => i < acc ? i : acc,
        );
    return rest.substring(0, end).trim();
  }

  /// How strong the match is, measured by the data itself: the longer the shared
  /// phrase, the more wording the two ayat actually have in common.
  ///
  /// This is an *ordering* key for the graph, never a claim of degree — the
  /// corpus has no numeric score to report.
  int get matchStrength => sharedPhrase.runes.length;
}

/// One ayah and everything that resembles it.
class MutashabihNodeEntry {
  const MutashabihNodeEntry({
    required this.sourceAbsoluteId,
    required this.sourceSurahNumber,
    required this.sourceAyahNumber,
    required this.sourceText,
    required this.targets,
  });

  final int sourceAbsoluteId;
  final int sourceSurahNumber;
  final int sourceAyahNumber;
  final String sourceText;
  final List<MutashabihTargetEntry> targets;

  int get targetCount => targets.length;

  /// The same node with a shorter list of targets — what the graph screen hands
  /// to the diagram once a display level is chosen.
  MutashabihNodeEntry withTargets(List<MutashabihTargetEntry> subset) =>
      MutashabihNodeEntry(
        sourceAbsoluteId: sourceAbsoluteId,
        sourceSurahNumber: sourceSurahNumber,
        sourceAyahNumber: sourceAyahNumber,
        sourceText: sourceText,
        targets: subset,
      );

  /// The targets ordered strongest match first, then by Mushaf order, cut to
  /// [limit] when one is given.
  ///
  /// The graph screen shows a few at a time and more on demand — 30 spokes
  /// cannot all carry a readable label at once — and a stable order means
  /// switching level adds verses instead of rearranging the diagram.
  List<MutashabihTargetEntry> orderedTargets({int? limit}) {
    final List<MutashabihTargetEntry> ordered = List<MutashabihTargetEntry>.of(targets)
      ..sort((MutashabihTargetEntry a, MutashabihTargetEntry b) {
        final int byStrength = b.matchStrength.compareTo(a.matchStrength);
        if (byStrength != 0) {
          return byStrength;
        }
        return a.targetAbsoluteId.compareTo(b.targetAbsoluteId);
      });
    if (limit == null || limit >= ordered.length) {
      return List<MutashabihTargetEntry>.unmodifiable(ordered);
    }
    return List<MutashabihTargetEntry>.unmodifiable(ordered.sublist(0, limit));
  }
}

/// What a seeding pass actually did — so the UI can say a number instead of
/// guessing, and so a slow device is visible in the logs rather than felt.
class MutashabihatSeedReport {
  const MutashabihatSeedReport({
    required this.nodes,
    required this.targets,
    required this.elapsed,
    required this.alreadySeeded,
  });

  const MutashabihatSeedReport.skipped(int nodes, int targets)
      : this(
          nodes: nodes,
          targets: targets,
          elapsed: Duration.zero,
          alreadySeeded: true,
        );

  final int nodes;
  final int targets;
  final Duration elapsed;

  /// True when the collection was already populated and nothing was parsed.
  final bool alreadySeeded;
}

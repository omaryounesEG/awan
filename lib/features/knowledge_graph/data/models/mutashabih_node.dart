import 'package:isar/isar.dart';

part 'mutashabih_node.g.dart';

/// One ayah of the Mutashabihat corpus.
///
/// The ayah id **is** the Isar id (both are the app-wide Mushaf numbering), so
/// looking a node up is a primary-key hit rather than a scan — that is the
/// whole point of keeping the two in step.
@collection
class MutashabihNode {
  Id get id => sourceAbsoluteId;

  late int sourceAbsoluteId;
  late int sourceSurahNumber;
  late int sourceAyahNumber;
  late String sourceText;
  late List<MutashabihTarget> targets;
}

/// An edge: a similar ayah and the rule (الضابط) that says why.
@embedded
class MutashabihTarget {
  late int targetAbsoluteId;
  late int targetSurahNumber;
  late int targetAyahNumber;
  late String targetText;
  late String ruleText;
}

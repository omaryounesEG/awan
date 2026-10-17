import 'package:isar/isar.dart';

part 'quran_mark.g.dart';

/// A saved verse marker, or the single "last read" pointer.
@collection
class QuranMark {
  Id id = Isar.autoIncrement;

  @Index()
  late int surah;

  late int ayah;
  String? note;

  /// 'bookmark' | 'lastRead'
  @Index()
  late String kind;

  late DateTime createdAt;
}

/// Where the reader should resume, one row per surah.
@collection
class ReadingPosition {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int surah;

  late int ayah;
  late DateTime updatedAt;
}

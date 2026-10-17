import 'package:isar/isar.dart';

part 'tafsir_package_entry.g.dart';

/// An installable tafsir package (bundled or downloaded on demand).
///
/// Data model of `quran_tafseer`: the verse text ships with the app, the
/// tafsir is an add-on the user opts into, exactly as the architecture
/// requires (small first download, depth on demand).
@collection
class TafsirPackageEntry {
  Id id = Isar.autoIncrement;

  /// Resource id at the tafsir provider — the app's stable handle.
  @Index(unique: true, replace: true)
  late int tafsirId;

  late String slug;
  late String name;
  late String author;

  bool bundled = false;

  @Index()
  bool installed = false;

  int sizeKb = 0;
  String? filePath;
  DateTime? installedAt;
}

import 'package:flutter/foundation.dart';

/// One narrator, as the rijal index knows them: a name, the source's category,
/// a death year (hijri) and a place. Nothing here is our verdict.
@immutable
class Narrator {
  const Narrator({
    required this.name,
    required this.category,
    required this.deathYear,
    required this.place,
  });

  final String name;

  /// Index into [RijalIndex.categories].
  final int category;
  final int deathYear;
  final String place;

  static Narrator fromJson(List<Object?> row) => Narrator(
        name: '${row[0]}',
        category: (row[1] as num?)?.toInt() ?? 0,
        deathYear: (row[2] as num?)?.toInt() ?? 0,
        place: row.length > 3 ? '${row[3]}' : '',
      );
}

/// The whole narrator index, with a normalised name used for search.
@immutable
class RijalIndex {
  const RijalIndex({
    required this.categories,
    required this.narrators,
    required this.search,
    required this.note,
  });

  final List<String> categories;
  final List<Narrator> narrators;
  final List<String> search;
  final String note;

  String categoryOf(Narrator narrator) =>
      narrator.category >= 0 && narrator.category < categories.length
          ? categories[narrator.category]
          : '';
}

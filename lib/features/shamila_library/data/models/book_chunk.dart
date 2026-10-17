import 'package:isar/isar.dart';

part 'book_chunk.g.dart';

/// The text of an installed book, one row per reading chunk.
///
/// Separate from [LibraryBook] on purpose: the catalogue is small and always
/// present, the text is large and only present for books the reader installed.
/// Dropping a book's text is then one indexed delete, not a field reset.
@collection
class BookChunkRow {
  Id id = Isar.autoIncrement;

  /// Indexed on its own so `where().bookIdEqualTo(...)` narrows the read to one
  /// book — the reader's hot path, and the delete path when a book is removed.
  ///
  /// Isar 3 generates no where-clause for the leading field of a *composite*
  /// index, so the pair below is two plain indexes and the window is expressed as
  /// `bookId = ? AND chapter >= ?` sorted by chapter.
  @Index()
  late String bookId;

  @Index()
  late int chapter;

  /// Section heading this chunk starts under, when the corpus has one.
  String? title;

  /// Printed page number this chunk starts on, when the corpus has one.
  String? page;

  late String text;
}

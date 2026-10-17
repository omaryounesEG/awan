import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// Turns the published `library_index.json` into entities.
///
/// Pure on purpose: the shape of the index is a contract with whatever builds the
/// CDN (`tools/build_library_cdn.py`), and keeping the parsing testable without a
/// server is how that contract stays honest.
class LibraryIndexParser {
  const LibraryIndexParser._();

  /// [baseUrl] decides where the archives come from, because that is what the
  /// «مصدر المكتبة» setting means. The `url` a row carries is only used when no
  /// source is configured: the bundled index was written by whoever built the
  /// CDN, and that host is not necessarily the one the reader can reach.
  static List<BookEntry> parse(Object? json, {required String baseUrl}) {
    if (json is! Map) return const <BookEntry>[];
    final Object? books = json['books'];
    if (books is! List) return const <BookEntry>[];

    final String root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final List<BookEntry> entries = <BookEntry>[];
    for (final Object? raw in books) {
      if (raw is! Map) continue;
      final String id = _text(raw['id']).trim();
      if (id.isEmpty) continue;

      final String title = _text(raw['title']).trim();
      final String category = _text(raw['category']).trim();
      final String published = _text(raw['url']).trim();
      final String archive = _text(raw['archive']).trim();
      final String resolved = root.isNotEmpty
          ? (archive.isEmpty ? '$root/books/$id.sqlite.zip' : '$root/$archive')
          : published;
      entries.add(
        BookEntry(
          id: id,
          title: title.isEmpty ? id : title,
          author: _text(raw['author']).trim(),
          category: category.isEmpty ? 'عام' : category,
          url: resolved,
          authorDied: _int(raw['author_died']),
          source: _text(raw['source']).trim().isEmpty
              ? 'openiti'
              : _text(raw['source']).trim(),
          version: _text(raw['version']).trim(),
          chapters: _int(raw['chapters']) ?? 0,
          chars: _int(raw['chars']) ?? 0,
          sizeBytes: _int(raw['file_size']) ?? 0,
        ),
      );
    }
    return entries;
  }

  /// What the local search matches on: title + author + category, folded.
  ///
  /// Folding here (once per book, at sync time) rather than per keystroke is what
  /// makes search feel instant on a catalogue of tens of thousands of rows.
  static String searchKey(BookEntry entry) => normalizeArabic(
        '${entry.title} ${entry.author} ${entry.category}',
        foldSuperscriptAlef: true,
      ).replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _text(Object? value) => value == null ? '' : '$value';

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

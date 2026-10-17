import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/shamila_library/data/datasources/library_index_parser.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// The index is a contract with the tool that builds the CDN
/// (`tools/build_library_cdn.py`), so these cases are the real shapes that tool
/// writes — including the rows where an author's death year is unknown and where
/// the builder publishes no explicit `url`.
void main() {
  const String base = 'https://cdn.example.com/awan/library/';

  group('LibraryIndexParser', () {
    test('reads the published row shape', () {
      final List<BookEntry> entries = LibraryIndexParser.parse(
        <String, Object?>{
          'schema': 1,
          'count': 1,
          'books': <Object?>[
            <String, Object?>{
              'id': '0238.IbnHabibQurtubi.MukhtasarFiTibb',
              'title': '(مختصر في الطب)',
              'author': 'عبد الملك بن حبيب',
              'author_died': 238,
              'category': 'علوم أخرى',
              'source': 'openiti',
              'version': 'Shamela0010705',
              'chapters': 42,
              'chars': 180000,
              'file_size': 123456,
              'url': 'https://cdn.example.com/awan/library/books/x.sqlite.zip',
            },
          ],
        },
        baseUrl: base,
      );

      expect(entries, hasLength(1));
      final BookEntry book = entries.single;
      expect(book.id, '0238.IbnHabibQurtubi.MukhtasarFiTibb');
      expect(book.title, '(مختصر في الطب)');
      expect(book.authorDied, 238);
      expect(book.category, 'علوم أخرى');
      expect(book.chapters, 42);
      expect(book.sizeBytes, 123456);
      expect(book.downloaded, isFalse);
    });

    test('derives the archive url from the id when the row has none', () {
      final List<BookEntry> entries = LibraryIndexParser.parse(
        <String, Object?>{
          'books': <Object?>[
            <String, Object?>{'id': '0238.Book', 'title': 'كتاب'},
          ],
        },
        baseUrl: base,
      );

      // The trailing slash in the configured base must not become a double slash:
      // a 404 on every download would be the first thing a real user hits.
      expect(entries.single.url,
          'https://cdn.example.com/awan/library/books/0238.Book.sqlite.zip');
    });

    test('survives rows that are missing, malformed or nameless', () {
      final List<BookEntry> entries = LibraryIndexParser.parse(
        <String, Object?>{
          'books': <Object?>[
            'not a map',
            <String, Object?>{},
            <String, Object?>{'id': 'ok.1', 'title': 'بلا مؤلف', 'category': ''},
          ],
        },
        baseUrl: base,
      );

      expect(entries, hasLength(1));
      expect(entries.single.id, 'ok.1');
      // A book with no author and no category is still a book: it gets a name and
      // a bucket rather than being dropped.
      expect(entries.single.category, 'عام');
      expect(entries.single.author, isEmpty);
    });

    test('an index that is not an object is empty, not an exception', () {
      expect(LibraryIndexParser.parse(null, baseUrl: base), isEmpty);
      expect(LibraryIndexParser.parse('nope', baseUrl: base), isEmpty);
      expect(
        LibraryIndexParser.parse(<String, Object?>{'books': 'nope'},
            baseUrl: base),
        isEmpty,
      );
    });

    test('the search key folds what Arabic readers type', () {
      final BookEntry entry = LibraryIndexParser.parse(
        <String, Object?>{
          'books': <Object?>[
            <String, Object?>{
              'id': 'x',
              'title': 'الألفية في النحو',
              'author': 'ابن مالك',
              'category': 'لغة',
            },
          ],
        },
        baseUrl: base,
      ).single;

      final String key = LibraryIndexParser.searchKey(entry);
      // Typed without the hamza and without the definite-article spelling:
      expect(key.contains('الالفيه'), isTrue);
      expect(key.contains('ابن مالك'), isTrue);
    });
  });
}

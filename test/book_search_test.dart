import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';

/// The needles an in-book search hands the database, and the snippets it shows.
///
/// These are the parts of search that decide *whether the reader finds anything*,
/// so they are pinned here rather than discovered on a phone.
void main() {
  group('BookSearch.needle', () {
    test('strips the harakat, so a vocalised query meets plain prose', () {
      expect(BookSearch.needle('الصَّلَاةُ'), 'الصلاة');
      expect(BookSearch.needle('كِتَاب'), 'كتاب');
    });

    test('drops the tatweel and collapses whitespace', () {
      expect(BookSearch.needle('كتـــاب'), 'كتاب');
      expect(BookSearch.needle('  الصلاة   الوسطى '), 'الصلاة الوسطى');
    });

    test('keeps the letters themselves — no silent hamza rewriting', () {
      // The stored text keeps its own spelling; rewriting the query would stop it
      // matching the very words that use them.
      expect(BookSearch.needle('الإناء'), 'الإناء');
      expect(BookSearch.needle('موسى'), 'موسى');
    });

    test('an empty or mark-only query is empty, not a space', () {
      expect(BookSearch.needle('   '), '');
      expect(BookSearch.needle('َُّ'), '');
    });
  });

  group('BookSearch.words', () {
    test('longest first and capped, so a pasted paragraph is not twenty queries', () {
      final List<String> words = BookSearch.words('الصلاة الوسطى حافظوا');
      expect(words.length, 3);
      expect(words, containsAll(<String>['الصلاة', 'الوسطى', 'حافظوا']));
      expect(BookSearch.words('a bb ccc dddd eeeee ffffff', max: 3),
          <String>['ffffff', 'eeeee', 'dddd']);
    });

    test('particles shorter than three letters are dropped: they match everything', () {
      expect(BookSearch.words('و في الصلاة'), <String>['الصلاة']);
      expect(BookSearch.words('ما من شيء'), <String>['شيء']);
    });
  });

  group('BookSearch.foldedNeedle', () {
    test('folds the alef forms and the alef maqsura', () {
      expect(BookSearch.foldedNeedle('الإخلاص'), 'الاخلاص');
      expect(BookSearch.foldedNeedle('موسى'), 'موسي');
    });

    test('leaves an already plain needle alone', () {
      expect(BookSearch.foldedNeedle('الصلاة'), 'الصلاة');
    });
  });

  group('BookSearch.isPageMarker', () {
    test('a bare printed page is a marker, not a chapter', () {
      for (final String marker in <String>['-102', '102', '102-', ' 102 ', '—102']) {
        expect(BookSearch.isPageMarker(marker), isTrue, reason: marker);
      }
    });

    test('a real heading is never mistaken for one', () {
      for (final String heading in <String>[
        'باب ما جاء في الصلاة',
        'أسعد بن عبد الله',
        'المجلد الأول',
        '102 هـ',
      ]) {
        expect(BookSearch.isPageMarker(heading), isFalse, reason: heading);
      }
    });
  });

  group('BookSearch.snippet', () {
    test('marks the match and keeps it inside the window', () {
      const String text =
          'قال رسول الله صلى الله عليه وسلم: إنما الأعمال بالنيات ولكل امرئ ما نوى.';
      final String snippet = BookSearch.snippet(text, 'إنما الأعمال');
      expect(snippet, contains('إنما الأعمال'));
      expect(snippet.length, lessThan(text.length + 2));
    });

    test('cuts at word boundaries, not mid-word', () {
      final String text = '${'كلمة ' * 40}المطلوب هنا${' وأخرى' * 40}';
      final String snippet = BookSearch.snippet(text, 'المطلوب', before: 20, after: 20);
      expect(snippet, contains('المطلوب'));
      // No half-word at either end: every token is a whole word of the source.
      final String body = snippet.replaceAll('…', '').trim();
      for (final String word in body.split(' ')) {
        expect(text, contains(word));
      }
    });

    test('a text with no match still returns a readable head', () {
      const String text = 'نص قصير';
      expect(BookSearch.snippet(text, 'مفقود'), text);
    });

    test('empty text is empty, not a crash', () {
      expect(BookSearch.snippet('', 'شيء'), '');
    });
  });
}

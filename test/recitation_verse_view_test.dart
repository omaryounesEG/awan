import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/presentation/widgets/recitation_verse_view.dart';

/// The colour contract of the checker, tested as a contract.
///
/// Every rule here is one the user will notice if it breaks: a correct word is
/// green, a right word with the wrong vowel is amber *and* shows the vowel it
/// should have had, a wrong word is red, a word not reached yet is not coloured
/// at all, and the word the reciter is on is where the eye lands.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(1080, 2400),
        builder: (BuildContext context, Widget? _) => MaterialApp(
          home: Scaffold(body: child),
        ),
      );

  RecitationWord word({
    required int index,
    required String text,
    WordVerdict verdict = WordVerdict.pending,
    String? expectedMark,
    String? spoken,
  }) {
    return RecitationWord(
      index: index,
      uthmani: text,
      consonants: text,
      marks: const <String>[''],
      verdict: verdict,
      expectedMark: expectedMark,
      spoken: spoken,
    );
  }

  testWidgets('each verdict paints its own colour and shows its own evidence',
      (WidgetTester tester) async {
    final AyahAlignment alignment = AyahAlignment(
      surah: 1,
      ayah: 1,
      cursor: 2,
      words: <RecitationWord>[
        word(index: 0, text: 'بِسْمِ', verdict: WordVerdict.correct),
        word(
          index: 1,
          text: 'ٱللَّهِ',
          verdict: WordVerdict.diacritic,
          expectedMark: 'i',
        ),
        word(index: 2, text: 'ٱلرَّحْمَٰنِ'),
        word(
          index: 3,
          text: 'ٱلرَّحِيمِ',
          verdict: WordVerdict.word,
          spoken: 'الرحيمُ',
        ),
      ],
    );

    await tester.pumpWidget(host(RecitationVerseView(alignment: alignment)));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(RecitationVerseView));
    final ColorScheme colors = Theme.of(context).colorScheme;

    Color colourOfText(String text) {
      final Finder finder = find.byWidgetPredicate((Widget widget) {
        if (widget is! Text) return false;
        final InlineSpan? span = widget.textSpan;
        if (span is! TextSpan) return false;
        return span.toPlainText().contains(text);
      });
      expect(finder, findsOneWidget, reason: 'word «$text» should be on screen');
      final Text widget = tester.widget<Text>(finder);
      final TextSpan span = widget.textSpan! as TextSpan;
      final TextSpan first = span.children!.first as TextSpan;
      return first.style!.color!;
    }

    expect(colourOfText('بِسْمِ'), colors.primary, reason: 'correct is green');
    expect(colourOfText('ٱللَّهِ'), const Color(0xFFB26A00),
        reason: 'a wrong vowel is amber');
    expect(colourOfText('ٱلرَّحْمَٰنِ'), colors.onSurface,
        reason: 'a word not reached yet must not be coloured');
    expect(colourOfText('ٱلرَّحِيمِ'), colors.error, reason: 'a wrong word is red');

    // The amber word must show the vowel it should have carried.
    expect(find.text('\u0650'), findsOneWidget,
        reason: 'the expected kasra is shown above the word');
  });

  testWidgets('the current word is the only one highlighted',
      (WidgetTester tester) async {
    final AyahAlignment alignment = AyahAlignment(
      surah: 1,
      ayah: 1,
      cursor: 1,
      words: <RecitationWord>[
        word(index: 0, text: 'بِسْمِ', verdict: WordVerdict.correct),
        word(index: 1, text: 'ٱللَّهِ'),
      ],
    );

    await tester.pumpWidget(host(RecitationVerseView(alignment: alignment)));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(RecitationVerseView));
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Iterable<Container> containers =
        tester.widgetList<Container>(find.byType(Container));
    final List<Container> highlighted = containers.where((Container c) {
      final Decoration? d = c.decoration;
      return d is BoxDecoration && d.color == colors.secondaryContainer;
    }).toList();

    expect(highlighted, hasLength(1),
        reason: 'exactly one word carries the "you are here" colour');
  });

  testWidgets('an empty verse renders nothing rather than throwing',
      (WidgetTester tester) async {
    const AyahAlignment alignment = AyahAlignment(
      surah: 1,
      ayah: 1,
      words: <RecitationWord>[],
    );
    await tester.pumpWidget(host(const RecitationVerseView(alignment: alignment)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

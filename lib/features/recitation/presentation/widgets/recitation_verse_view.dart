import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';

/// The verse, coloured by verdict — the architecture note's fifth layer.
///
/// Public and free of providers on purpose: the colour contract (green word,
/// amber vowel, red word, quiet pending) is the part users actually judge the
/// feature by, so it is a widget a test can pump with three words and assert on.

class RecitationVerseView extends StatelessWidget {
  const RecitationVerseView({super.key, required this.alignment});

  final AyahAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 14.h,
          spacing: 6.w,
          children: <Widget>[
            for (final RecitationWord word in alignment.words)
              RecitationWordChip(
                word: word,
                isCurrent: word.index == alignment.cursor,
                isLast: word.index == alignment.words.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class RecitationWordChip extends StatelessWidget {
  const RecitationWordChip({super.key, required this.word, required this.isCurrent, required this.isLast});

  final RecitationWord word;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color base = switch (word.verdict) {
      WordVerdict.correct => colors.primary,
      WordVerdict.diacritic => const Color(0xFFB26A00),
      WordVerdict.word => colors.error,
      WordVerdict.pending => colors.onSurface,
    };
    final Color background = switch (word.verdict) {
      WordVerdict.correct => colors.primary.withOpacity(0.07),
      WordVerdict.diacritic => const Color(0xFFB26A00).withOpacity(0.10),
      WordVerdict.word => colors.error.withOpacity(0.10),
      WordVerdict.pending => Colors.transparent,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isCurrent ? colors.secondaryContainer : background,
            borderRadius: BorderRadius.circular(10.r),
            border: isCurrent
                ? Border.all(color: colors.secondary, width: 1.4)
                : null,
          ),
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: word.uthmani,
                  style: TextStyle(
                    fontSize: 26.sp,
                    height: 1.9,
                    color: base,
                    fontWeight: word.verdict == WordVerdict.word
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (isLast)
                  TextSpan(
                    text: ' ۝',
                    style: TextStyle(fontSize: 22.sp, color: colors.onSurfaceVariant),
                  ),
              ],
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        if (word.verdict == WordVerdict.diacritic && word.expectedMark != null)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              _markGlyph(word.expectedMark!),
              style: TextStyle(
                fontSize: 20.sp,
                color: const Color(0xFFB26A00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  /// Turns the checker's mark key back into the glyph a reader recognises, so
  /// the hint above the word is a vowel rather than the letter `a`.
  String _markGlyph(String key) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < key.length; i++) {
      switch (key[i]) {
        case 'a':
          out.write('\u064E');
        case 'u':
          out.write('\u064F');
        case 'i':
          out.write('\u0650');
        case '0':
          out.write('\u0652');
        case '~':
          out.write('\u0651');
        case 'n':
          out.write('');
        default:
          out.write('');
      }
    }
    return out.toString();
  }
}


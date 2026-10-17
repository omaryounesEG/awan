import 'package:flutter/material.dart';

import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/ayah_ornament.dart';

/// One verse, drawn the way a Mushaf page reads.
///
/// The text is *not* broken into separate widgets: the whole verse is a single
/// justified run ending in «۝ + the number», because that is what makes a line look
/// like a Mushaf line instead of a chat bubble.
class AyahView extends StatelessWidget {
  const AyahView({
    super.key,
    required this.text,
    required this.number,
    required this.appearance,
    required this.onTap,
    this.marked = false,
    this.similar = false,
    this.isSajda = false,
    this.sajdaLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
  });

  final String text;
  final int number;
  final QuranAppearance appearance;
  final VoidCallback onTap;

  /// True when this is the verse the reader stopped on — it gets a soft wash and a
  /// ribbon above it, so the eye finds it instantly on reopening.
  final bool marked;

  /// True when the Mutashabihat corpus knows this verse. With «إظهار
  /// المتشابهات» on, such a verse is tinted and opens the graph when tapped:
  /// the text keeps the Mushaf look, the tint is what marks it.
  final bool similar;
  final bool isSajda;
  final String? sajdaLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final QuranPalette palette = appearance.palette;

    return Semantics(
      button: true,
      label: '$number',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: marked
              ? BoxDecoration(
                  color: palette.markWash,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    right: BorderSide(color: palette.accent, width: 3),
                  ),
                )
              : similar
                  ? BoxDecoration(
                      color: palette.accent.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: palette.accent.withOpacity(0.45),
                        width: 1.2,
                      ),
                    )
                  : null,
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (isSajda && sajdaLabel != null) ...<Widget>[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sajdaLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text.rich(
                ayahWithMedallion(
                  text: text,
                  ayah: number,
                  appearance: appearance,
                  palette: palette,
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: appearance.font.family,
                  fontFamilyFallback: kQuranFallback,
                  fontSize: appearance.ayahSize * appearance.font.sizeFactor,
                  height: appearance.lineHeight,
                  color: palette.text,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The printed-page separator: «الجزء ١ · صفحة ٢» between two pages of the flow.
class PageDivider extends StatelessWidget {
  const PageDivider({
    super.key,
    required this.appearance,
    required this.page,
    required this.juz,
    required this.pageLabel,
    required this.juzLabel,
  });

  final QuranAppearance appearance;
  final int page;
  final int juz;
  final String pageLabel;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    final QuranPalette palette = appearance.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: palette.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$juzLabel ${arabicDigits(juz)} · $pageLabel ${arabicDigits(page)}',
              style: TextStyle(fontSize: 12, color: palette.dim),
            ),
          ),
          Expanded(child: Divider(color: palette.divider)),
        ],
      ),
    );
  }
}

/// The surah opening: name plate, place of revelation, verse count, and the
/// basmala when the Mushaf prints one.
class SurahHeader extends StatelessWidget {
  const SurahHeader({
    super.key,
    required this.appearance,
    required this.name,
    required this.place,
    required this.ayahCount,
    required this.ayahLabel,
    this.showBasmala = true,
  });

  final QuranAppearance appearance;
  final String name;
  final String place;
  final int ayahCount;
  final String ayahLabel;
  final bool showBasmala;

  @override
  Widget build(BuildContext context) {
    final QuranPalette palette = appearance.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        children: <Widget>[
          Text(
            name,
            style: TextStyle(
              fontFamily: appearance.font.family,
              fontFamilyFallback: kQuranFallback,
              fontSize: appearance.ayahSize * 0.95,
              color: palette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$place · ${arabicDigits(ayahCount)} $ayahLabel',
            style: TextStyle(fontSize: 11.5, color: palette.dim),
          ),
          if (showBasmala) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: appearance.font.family,
                fontFamilyFallback: kQuranFallback,
                fontSize: appearance.ayahSize * appearance.font.sizeFactor * 0.85,
                color: palette.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ribbon that hangs over the verse the reader stopped on.
class StopRibbon extends StatelessWidget {
  const StopRibbon({
    super.key,required this.appearance, required this.label});

  final QuranAppearance appearance;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: appearance.palette.accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.bookmark, size: 13, color: appearance.palette.background),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: appearance.palette.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

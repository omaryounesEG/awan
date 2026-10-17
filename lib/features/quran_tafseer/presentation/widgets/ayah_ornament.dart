import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';

/// The ayah-end medallion, drawn rather than typeset.
///
/// The obvious way to mark a verse end is the Unicode character the Mus'haf fonts
/// carry for it, `۝` (U+06DD), and that is what this app did first: the mark followed
/// by the number in Arabic-Indic digits. On the emulator it came out as a **solid
/// black disc with no number in it** — the digits-inside-the-rosette effect depends on
/// the font performing a contextual substitution, and when the digits are drawn by a
/// fallback font that substitution silently never fires. That is a bad failure mode:
/// the verse ends are exactly where a reader looks to keep their place, and the number
/// simply was not there.
///
/// So the medallion is painted here: an outer ring, a ring of beads, and the number
/// centred in the reading font. It looks the same in every font the reader can pick
/// («حفص», «أميري قرآن», «شهرزاد»), at every size, and it always has its number.
class AyahOrnament extends StatelessWidget {
  const AyahOrnament({
    super.key,
    required this.ayah,
    required this.palette,
    required this.fontFamily,
    required this.diameter,
    this.fallback = const <String>[],
    this.color,
  });

  final int ayah;
  final QuranPalette palette;
  final String fontFamily;
  final double diameter;

  /// Quranic fonts to use for digits the chosen font does not carry.
  final List<String> fallback;

  /// Ring colour; defaults to the house green.
  final Color? color;

  /// The digits as a reader expects them: ١٢٣, not 123.
  static String digits(int value) {
    const List<String> arabicIndic = <String>[
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
    ];
    return value
        .toString()
        .split('')
        .map((String d) => arabicIndic[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final Color ring = color ?? palette.accent;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _OrnamentPainter(color: ring, beads: 8),
        child: Center(
          child: Padding(
            // Three digits need to breathe inside the ring; one or two get air too.
            padding: EdgeInsets.symmetric(horizontal: diameter * 0.16),
            child: FittedBox(
              child: Text(
                digits(ayah),
                maxLines: 1,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontFamilyFallback: fallback,
                  fontSize: diameter * 0.44,
                  height: 1,
                  color: palette.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter({required this.color, required this.beads});

  final Color color;
  final int beads;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 1;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color;
    final Paint fill = Paint()..color = color;

    canvas.drawCircle(centre, radius, stroke);

    // The little beads that make a printed mark read as a mark and not as a bullet.
    final double beadRadius = (radius * 0.075).clamp(0.6, 2.2);
    final double orbit = radius - beadRadius - 1.6;
    for (int i = 0; i < beads; i++) {
      // Offset by half a step so the beads straddle top/bottom like a printed rosette.
      final double angle = (i / beads) * 2 * math.pi + math.pi / 8;
      canvas.drawCircle(
        centre + Offset(orbit * math.cos(angle), orbit * math.sin(angle)),
        beadRadius,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) =>
      old.color != color || old.beads != beads;
}

/// The verse text plus its medallion, ready to drop into a `Text.rich`.
///
/// `WidgetSpan` keeps the medallion inside the justified paragraph, so the page keeps
/// its printed shape instead of breaking the line to place an image.
InlineSpan ayahWithMedallion({
  required String text,
  required int ayah,
  required QuranAppearance appearance,
  required QuranPalette palette,
  double sizeFactor = 1,
}) {
  final double base = appearance.ayahSize * appearance.font.sizeFactor * sizeFactor;
  final double diameter = base * 0.92;
  return TextSpan(
    children: <InlineSpan>[
      TextSpan(text: text),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.only(left: diameter * 0.18),
          child: AyahOrnament(
            ayah: ayah,
            palette: palette,
            fontFamily: appearance.font.family,
            fallback: kQuranFallback,
            diameter: diameter,
          ),
        ),
      ),
    ],
  );
}

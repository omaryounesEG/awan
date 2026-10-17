import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:awan/features/prayer_clock/domain/entities/clock_face.dart';

/// The clock face itself: two big digits, drawn either as glowing type or as cut
/// segments, in a colour the reader chose.
///
/// Everything here is a `CustomPaint` over a `TextPainter`: no font file, no
/// image, nothing to download — the face is styled by code so a new face costs
/// one enum value.
class ClockDigits extends StatelessWidget {
  const ClockDigits({
    super.key,
    required this.time,
    required this.face,
    required this.night,
    required this.scale,
  });

  /// What to show. Seconds are drawn small next to the minutes so the big pair
  /// keeps the shape of a wall clock.
  final DateTime time;
  final ClockFace face;
  final bool night;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final ClockFaceStyle style = ClockFaceStyle.of(face, night);
    // The box needs a *width* as well as a height. A `CustomPaint` without a child
    // takes its size from the constraints, and inside a `FittedBox` those are
    // unbounded — so the canvas came out zero-wide and the clock was painted off
    // its own edge, invisible while the countdown beside it showed. The width is
    // the digits' own aspect: four monospaced digits plus the seconds.
    return SizedBox(
      height: 150 * scale,
      width: 340 * scale,
      child: CustomPaint(
        painter: _ClockPainter(
          text: '${time.hour.toString().padLeft(2, '0')}'
              '${time.minute.toString().padLeft(2, '0')}',
          seconds: time.second,
          style: style,
          scale: scale,
        ),
      ),
    );
  }
}

/// Colours and glow per face and time of day.
/// The colours one face is drawn in.
///
/// Public because the screen that draws the clock also draws the countdown under
/// it, and the two must not be the same colour: two large numbers in one hue read
/// as a single blur. [accent] is the deliberate second colour — the countdown and
/// the quiet labels are drawn in it.
class ClockFaceStyle {
  const ClockFaceStyle({
    required this.color,
    required this.glow,
    required this.accent,
    this.segment = false,
  });

  final Color color;
  final Color glow;

  /// A neighbouring-but-different hue, for the countdown beside the clock.
  final Color accent;
  final bool segment;

  static ClockFaceStyle of(ClockFace face, bool night) {
    // In daylight the "white glow" face would be invisible on a light page, so it
    // becomes ink-on-paper — the same face, read the way the room is lit.
    final Color white = night ? const Color(0xFFFFFFFF) : const Color(0xFF101418);
    return switch (face) {
      // Ink or paper for the clock, sky blue for the countdown: the two never
      // share a hue on any background.
      ClockFace.white => ClockFaceStyle(
          color: white,
          glow: night ? const Color(0x66FFFFFF) : const Color(0x22000000),
          accent: night ? const Color(0xFF8FD6FF) : const Color(0xFF0B6BA8),
        ),
      ClockFace.red => const ClockFaceStyle(
          color: Color(0xFFFF3B30),
          glow: Color(0x88FF3B30),
          // Amber against red — the countdown reads as its own number.
          accent: Color(0xFFFFC24B),
        ),
      ClockFace.green => const ClockFaceStyle(
          color: Color(0xFF00E676),
          glow: Color(0x8800E676),
          accent: Color(0xFFFFC24B),
        ),
      ClockFace.segment => ClockFaceStyle(
          color: night ? const Color(0xFFF3F6FF) : const Color(0xFF1B2430),
          glow: night ? const Color(0x55C7D2E6) : const Color(0x22000000),
          accent: night ? const Color(0xFFFFC65C) : const Color(0xFF9A5B00),
          segment: true,
        ),
    };
  }
}

/// The style of one face, for whoever needs the same colours outside the digits.
ClockFaceStyle clockFaceStyle(ClockFace face, {required bool night}) =>
    ClockFaceStyle.of(face, night);

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.text,
    required this.seconds,
    required this.style,
    required this.scale,
  });

  final String text;
  final int seconds;
  final ClockFaceStyle style;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    style.segment
        ? _paintSegments(canvas, size)
        : _paintGlow(canvas, size);
  }

  /// The modern look: a monospaced pair with a coloured bloom behind it.
  void _paintGlow(Canvas canvas, Size size) {
    final double fontSize = size.height * 0.78;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: style.color,
          fontSize: fontSize,
          height: 1.0,
          fontWeight: FontWeight.w600,
          letterSpacing: fontSize * 0.02,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          shadows: <Shadow>[
            Shadow(color: style.glow, blurRadius: fontSize * 0.22),
            Shadow(color: style.glow, blurRadius: fontSize * 0.05),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset origin = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );
    painter.paint(canvas, origin);

    // Seconds, small and calm beside the minutes.
    final TextPainter secs = TextPainter(
      text: TextSpan(
        text: seconds.toString().padLeft(2, '0'),
        style: TextStyle(
          color: style.accent,
          fontSize: fontSize * 0.20,
          height: 1.0,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    secs.paint(
      canvas,
      Offset(
        origin.dx + painter.width + fontSize * 0.10,
        origin.dy + painter.height - secs.height,
      ),
    );
  }

  /// The cut-segment look of the reference samples: seven bars per digit, the
  /// unlit ones set almost invisible so the shape reads even in daylight.
  void _paintSegments(Canvas canvas, Size size) {
    final int h = int.parse(text.substring(0, 2));
    final int m = int.parse(text.substring(2));
    final List<int> digits = <int>[
      h ~/ 10,
      h % 10,
      m ~/ 10,
      m % 10,
    ];

    final double digitH = size.height * 0.82;
    final double digitW = digitH * 0.52;
    final double gap = digitW * 0.22;
    final double colonW = digitW * 0.34;
    final double totalW =
        digitW * 4 + gap * 3 + colonW + digitW * 0.30; // + seconds block
    final double left = math.max(0, (size.width - totalW) / 2);
    final double top = (size.height - digitH) / 2;

    double x = left;
    for (int i = 0; i < digits.length; i++) {
      _paintDigit(
        canvas,
        Rect.fromLTWH(x, top, digitW, digitH),
        digits[i],
      );
      x += digitW;
      if (i == 1) {
        _paintColon(canvas, x, top, colonW, digitH);
        x += colonW;
      } else {
        x += gap;
      }
    }

    // Seconds as a small pair, same bars, so the face stays one idea.
    final double smallH = digitH * 0.26;
    final double smallW = smallH * 0.52;
    double sx = x + digitW * 0.10;
    for (final int d in <int>[seconds ~/ 10, seconds % 10]) {
      _paintDigit(canvas, Rect.fromLTWH(sx, top + digitH - smallH, smallW, smallH), d);
      sx += smallW + smallW * 0.18;
    }
  }

  void _paintColon(Canvas canvas, double x, double top, double w, double h) {
    final Paint paint = Paint()..color = style.color;
    final double r = h * 0.045;
    canvas.drawCircle(Offset(x + w / 2, top + h * 0.34), r, paint);
    canvas.drawCircle(Offset(x + w / 2, top + h * 0.66), r, paint);
  }

  /// Seven-segment digits: a, b, c, d, e, f, g.
  static const Map<int, String> _mask = <int, String>{
    0: 'abcdef',
    1: 'bc',
    2: 'abdeg',
    3: 'abcdg',
    4: 'bcfg',
    5: 'acdfg',
    6: 'acdefg',
    7: 'abc',
    8: 'abcdefg',
    9: 'abcdfg',
  };

  void _paintDigit(Canvas canvas, Rect rect, int digit) {
    final String on = _mask[digit] ?? '';
    final double t = rect.height * 0.13; // bar thickness
    final double inset = t * 0.30;
    final Rect r = rect.deflate(inset);

    final Paint lit = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;
    final Paint off = Paint()
      ..color = style.color.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final Map<String, Rect> bars = <String, Rect>{
      // a top, g middle, d bottom
      'a': Rect.fromLTWH(r.left + t * 0.55, r.top, r.width - t * 1.10, t),
      'g': Rect.fromLTWH(
          r.left + t * 0.55, r.top + r.height / 2 - t / 2, r.width - t * 1.10, t),
      'd': Rect.fromLTWH(
          r.left + t * 0.55, r.bottom - t, r.width - t * 1.10, t),
      // f upper-left, b upper-right
      'f': Rect.fromLTWH(r.left, r.top + t * 0.55, t, r.height / 2 - t * 0.85),
      'b': Rect.fromLTWH(
          r.right - t, r.top + t * 0.55, t, r.height / 2 - t * 0.85),
      // e lower-left, c lower-right
      'e': Rect.fromLTWH(
          r.left, r.top + r.height / 2 + t * 0.30, t, r.height / 2 - t * 0.85),
      'c': Rect.fromLTWH(r.right - t, r.top + r.height / 2 + t * 0.30, t,
          r.height / 2 - t * 0.85),
    };

    bars.forEach((String key, Rect bar) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(t * 0.35)),
        on.contains(key) ? lit : off,
      );
    });
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.text != text ||
      old.seconds != seconds ||
      old.style.color != style.color ||
      old.style.segment != style.segment ||
      old.scale != scale;
}

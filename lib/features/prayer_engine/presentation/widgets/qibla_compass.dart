import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:awan/core/utils/geo.dart';

/// A calm, hand-drawn-style qibla compass.
///
/// **What rotates.** The dial is a real compass card: it turns by `-heading`, so
/// the letter that ends up under the fixed pointer at the top is the direction
/// the phone is facing. The Kaaba marker is drawn at the *absolute* qibla bearing
/// on that card, which means the two line up — and the olive highlight appears —
/// exactly when the user faces Makkah.
///
/// **Why the motion looks smooth.** Two low-pass filters, in series, on purpose:
/// the native sensor listener already smooths its azimuth (0.18 EMA), and the
/// widget animates the remaining gap with a wrap-aware tween. A naive
/// `Tween(begin, end)` would send the needle the long way round every time the
/// reading crosses 359 -> 1, which is the classic compass stutter; the tween here
/// targets `begin + shortestDelta`, so it always turns the short way.
class QiblaCompass extends StatefulWidget {
  const QiblaCompass({
    super.key,
    required this.bearing,
    this.heading,
    required this.isAligned,
    this.scale = 1.0,
    this.semanticsLabel,
  });

  /// True-north bearing to Makkah, degrees.
  final double bearing;

  /// Live true heading, or `null` when the device has no magnetometer (the dial
  /// is then drawn north-up rather than pretending to know which way is which).
  final double? heading;

  /// Within the +/-2 degrees window.
  final bool isAligned;

  /// Elderly Mode grows the whole dial.
  final double scale;

  final String? semanticsLabel;

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Where the needle currently is — deliberately **not** wrapped to [0,360):
  /// letting it drift past 360 is what makes the short-path tween trivial.
  double _displayed = 0;
  double _tweenBegin = 0;
  double _tweenEnd = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.heading ?? 0;
    _tweenBegin = _displayed;
    _tweenEnd = _displayed;
  }

  @override
  void didUpdateWidget(covariant QiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);

    final double? next = widget.heading;
    if (next != null && next != oldWidget.heading) {
      final double from = _currentValue();
      _tweenBegin = from;
      _tweenEnd = from + Geo.shortestAngleDelta(next, from);
      _displayed = _tweenEnd;
      _controller.forward(from: 0);
    }

    // One light tap the moment the user lines up — not a continuous buzz.
    if (widget.isAligned && !oldWidget.isAligned) {
      HapticFeedback.lightImpact();
    }
  }

  double _currentValue() =>
      _tweenBegin + (_tweenEnd - _tweenBegin) * _controller.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: widget.semanticsLabel,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            painter: QiblaCompassPainter(
              heading: _currentValue(),
              bearing: widget.bearing,
              aligned: widget.isAligned,
              scale: widget.scale,
              ink: theme.colorScheme.onSurface,
              inkSoft: theme.colorScheme.onSurfaceVariant,
              outline: theme.colorScheme.outlineVariant,
              primary: theme.colorScheme.primary,
              alignedColor: widget.isAligned
                  ? (isDark ? const Color(0xFF9FC77A) : const Color(0xFF4C6B2F))
                  : theme.colorScheme.primary,
              surface: theme.colorScheme.surface,
              arabic: Localizations.localeOf(context).languageCode == 'ar',
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything the dial needs; no widget state leaks in here.
class QiblaCompassPainter extends CustomPainter {
  QiblaCompassPainter({
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.scale,
    required this.ink,
    required this.inkSoft,
    required this.outline,
    required this.primary,
    required this.alignedColor,
    required this.surface,
    required this.arabic,
  });

  final double heading;
  final double bearing;
  final bool aligned;
  final double scale;
  final Color ink;
  final Color inkSoft;
  final Color outline;
  final Color primary;
  final Color alignedColor;
  final Color surface;

  /// Arabic cardinal letters vs Latin — decided by the app's locale, not the
  /// phone's.
  final bool arabic;

  static const List<String> _cardinalAr = <String>['ش', 'ق', 'ج', 'غ'];
  static const List<String> _cardinalEn = <String>['N', 'E', 'S', 'W'];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 10 * scale;

    // Fixed reference at the top: the direction the phone is pointing.
    _paintFixedPointer(canvas, center, radius);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // The card turns; the world stays put.
    canvas.rotate(-heading * math.pi / 180.0);

    _paintTicks(canvas, radius);
    _paintCardinals(canvas, radius);
    _paintKaabaMarker(canvas, radius);

    canvas.restore();

    _paintHub(canvas, center);
  }

  void _paintFixedPointer(Canvas canvas, Offset center, double radius) {
    final Paint paint = Paint()
      ..color = aligned ? alignedColor : primary
      ..style = PaintingStyle.fill;

    final double w = 9 * scale;
    final double h = 16 * scale;
    final Path path = Path()
      ..moveTo(center.dx, center.dy - radius - 2 * scale)
      ..lineTo(center.dx - w / 2, center.dy - radius + h)
      ..lineTo(center.dx + w / 2, center.dy - radius + h)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintTicks(Canvas canvas, double radius) {
    final Paint tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int degree = 0; degree < 360; degree += 5) {
      final bool major = degree % 45 == 0;
      final bool medium = degree % 15 == 0;

      tick
        ..color = major ? ink.withOpacity(0.55) : outline.withOpacity(0.9)
        ..strokeWidth = (major ? 1.6 : medium ? 1.2 : 0.8) * scale;

      final double inner = radius - (major ? 14 : medium ? 10 : 6) * scale;
      final double rad = (degree - 90) * math.pi / 180.0;
      canvas.drawLine(
        Offset(math.cos(rad) * inner, math.sin(rad) * inner),
        Offset(math.cos(rad) * radius, math.sin(rad) * radius),
        tick,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale
        ..color = outline,
    );
  }

  void _paintCardinals(Canvas canvas, double radius) {
    // Arabic letters when the UI is Arabic (شمال/شرق/جنوب/غرب), Latin otherwise.
    //
    // The locale comes from the widget, not from `platformDispatcher`: a user who
    // switches the app to Arabic on an English phone must get ش/ق/ج/غ, and reading
    // the system locale here is exactly how that got broken once.
    final List<String> letters = arabic ? _cardinalAr : _cardinalEn;

    for (int i = 0; i < 4; i++) {
      final String letter = letters[i];
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: i == 0 ? primary : inkSoft,
            fontSize: 17 * scale,
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double rad = (i * 90 - 90) * math.pi / 180.0;
      final double distance = radius - 34 * scale;
      painter.paint(
        canvas,
        Offset(
          math.cos(rad) * distance - painter.width / 2,
          math.sin(rad) * distance - painter.height / 2,
        ),
      );
    }
  }

  /// The Kaaba: a small cuboid with its gold band, drawn at the true bearing.
  void _paintKaabaMarker(Canvas canvas, double radius) {
    canvas.save();
    canvas.rotate(bearing * math.pi / 180.0);
    canvas.translate(0, -radius + 30 * scale);

    final Color body = aligned ? alignedColor : ink;
    final double side = 16 * scale;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: side,
          height: side * 1.15,
        ),
        Radius.circular(2.5 * scale),
      ),
      Paint()..color = body,
    );

    // The kiswa band, in brass.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -side * 0.18),
        width: side,
        height: 2.6 * scale,
      ),
      Paint()..color = const Color(0xFFC7A45A),
    );

    if (aligned) {
      // A soft halo instead of a loud colour change.
      canvas.drawCircle(
        Offset.zero,
        26 * scale,
        Paint()..color = alignedColor.withOpacity(0.16),
      );
    }

    canvas.restore();
  }

  void _paintHub(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      4.5 * scale,
      Paint()..color = aligned ? alignedColor : ink.withOpacity(0.65),
    );
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.bearing != bearing ||
      oldDelegate.aligned != aligned ||
      oldDelegate.scale != scale ||
      oldDelegate.ink != ink ||
      oldDelegate.surface != surface ||
      oldDelegate.arabic != arabic;
}

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_clock/domain/entities/clock_face.dart';

void main() {
  group('ClockFace', () {
    test('every face survives a round trip through its stored value', () {
      for (final ClockFace face in ClockFace.values) {
        expect(ClockFace.fromWire(face.wire), face);
      }
    });

    test('an unknown or missing value falls back to the segment face', () {
      // A hand-edited preference, or one written by an older build, must not take
      // the clock down or leave it invisible.
      expect(ClockFace.fromWire(null), ClockFace.segment);
      expect(ClockFace.fromWire(''), ClockFace.segment);
      expect(ClockFace.fromWire('neon'), ClockFace.segment);
    });

    test('the wire values are stable strings, not indices', () {
      // Reordering the enum must not repaint the reader's choice.
      expect(ClockFace.segment.wire, 'segment');
      expect(ClockFace.white.wire, 'white');
      expect(ClockFace.red.wire, 'red');
      expect(ClockFace.green.wire, 'green');
    });
  });
}

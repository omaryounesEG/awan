import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/knowledge_graph/domain/entities/ayah_reference.dart';

void main() {
  group('AyahReference.parse', () {
    test('reads the reference however the keyboard writes it', () {
      for (final String typed in <String>['2:255', '٢:٢٥٥', '2/255', '2-255', '2 255', ' ٢ : ٢٥٥ ']) {
        final AyahReference? parsed = AyahReference.parse(typed);
        expect(parsed?.surah, 2, reason: '«$typed» must read as surah 2');
        expect(parsed?.ayah, 255, reason: '«$typed» must read as ayah 255');
      }
    });

    test('takes a surah name when the caller can resolve one', () {
      // The screen keys its name table by the same normalisation it quizzes.
      int? resolver(String name) => name == normalizeArabic('البقرة') ? 2 : null;
      final AyahReference? parsed =
          AyahReference.parse('البقرة 255', surahIdOfName: resolver);
      expect(parsed?.surah, 2);
      expect(parsed?.ayah, 255);
    });

    test('refuses what is not a reference', () {
      expect(AyahReference.parse('لعلكم تتقون'), isNull);
      expect(AyahReference.parse(''), isNull);
      expect(AyahReference.parse('115:1'), isNull, reason: 'there is no surah 115');
      expect(AyahReference.parse('0:5'), isNull);
      expect(AyahReference.parse('2:0'), isNull);
    });

    test('does not invent a verse from a name it cannot resolve', () {
      expect(AyahReference.parse('بني إسرائيل 20'), isNull);
    });
  });
}

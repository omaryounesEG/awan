import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/align_recitation.dart';
import 'package:awan/features/recitation/domain/usecases/quran_text.dart';
import 'package:awan/features/recitation/domain/usecases/speech_segmenter.dart';

/// The checker's brain, tested without a microphone and without a model.
///
/// Every case here is a mistake a real reciter makes: a wrong vowel on the last
/// letter, a word skipped, a word repeated to fix it, a segment that starts in
/// the middle of the verse.
void main() {
  group('reading Arabic twice', () {
    test('the skeleton drops marks and folds the alef forms', () {
      expect(QuranText.skeleton('ٱلْحَمْدُ'), 'الحمد');
      expect(QuranText.skeleton('أَنْعَمْتَ'), 'انعمت');
      expect(QuranText.skeleton('إِيَّاكَ'), 'اياك');
      expect(QuranText.skeleton('آمَنُوا'), 'امنوا');
      expect(QuranText.skeleton('عَلَىٰ'), 'علي');
      expect(QuranText.skeleton('رَحْمَةً'), 'رحمه');
    });

    test('the skeleton keeps a hamza, because a dropped hamza is a mistake', () {
      expect(QuranText.skeleton('شَيْءٍ'), 'شيء');
    });

    test('punctuation and invisible marks from the recogniser are ignored', () {
      // Whisper decorates its output; a comma is not a mispronunciation.
      expect(QuranText.skeleton('ٱلرَّحْمَٰنِ،'), 'الرحمن');
      expect(QuranText.skeleton('\u200fٱللَّهِ\u200e'), 'الله');
      expect(QuranText.skeleton('«رَبِّ»'), 'رب');
    });

    test('marks land on the letter they belong to', () {
      // ا ل(ْ) ح(َ) م(ْ) د(ُ)
      expect(QuranText.marks('ٱلْحَمْدُ'), <String>['', '0', 'a', '0', 'u']);
      // shadda is canonicalised before the vowel it doubles, whichever order
      // the recogniser writes them in
      expect(QuranText.marks('رَبِّ'), <String>['a', '~i']);
      expect(QuranText.marks('رَبِّ'.replaceFirst('\u0650\u0651', '\u0651\u0650')),
          <String>['a', '~i']);
      // tanween stays one key
      expect(QuranText.marks('عَذَابٌ'), <String>['a', 'a', '', 'un']);
    });

    test('a bare word is recognised as unvocalised', () {
      expect(QuranText.hasVowels('الحمد'), isFalse);
      expect(QuranText.hasVowels('ٱلْحَمْدُ'), isTrue);
    });

    test('levenshtein counts code points, not bytes', () {
      expect(QuranText.levenshtein('الحمد', 'الحمد'), 0);
      expect(QuranText.levenshtein('الحمد', 'الحم'), 1);
      expect(QuranText.levenshtein('رب', 'لب'), 1);
      expect(QuranText.similarity('الصراط', 'السراط'), closeTo(0.833, 0.01));
    });
  });

  group('aligning a recitation', () {
    const AlignRecitation align = AlignRecitation();
    final List<RecitationWord> fatiha1 = _words('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
    final AyahAlignment fresh = AyahAlignment(surah: 1, ayah: 1, words: fatiha1);

    test('a clean recitation is all green and lands on the last word', () {
      final AyahAlignment result = align(
        session: fresh,
        heard: <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
      );
      expect(result.words.every((RecitationWord w) => w.verdict == WordVerdict.correct), isTrue);
      expect(result.cursor, 4);
      expect(result.wrongCount, 0);
    });

    test('a wrong vowel is a diacritic error, not a wrong word', () {
      final AyahAlignment result = align(
        session: fresh,
        heard: <String>['بِسْمِ', 'ٱللَّهَ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'],
      );
      final RecitationWord second = result.words[1];
      expect(second.verdict, WordVerdict.diacritic);
      expect(second.expectedMark, isNotNull);
      expect(second.heardMark, isNotNull);
      expect(result.wrongCount, 1);
    });

    test('an unvocalised transcript never invents a vowel error', () {
      final AyahAlignment result = align(
        session: fresh,
        heard: <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
      );
      expect(result.words.where((RecitationWord w) => w.verdict == WordVerdict.diacritic), isEmpty);
    });

    test('a different word is a word error and names what was heard', () {
      final AyahAlignment result = align(
        session: fresh,
        heard: <String>['بسم', 'الرحمن', 'الرحمن', 'الرحيم'],
      );
      expect(result.words[1].verdict, WordVerdict.word);
      expect(result.words[1].spoken, 'الرحمن');
      expect(result.words[2].verdict, WordVerdict.correct);
    });

    test('repeating a word to fix it does not rewind the cursor', () {
      final AyahAlignment once = align(
        session: fresh,
        heard: <String>['بسم', 'الله', 'الرحمن', 'الرحيم'],
      );
      expect(once.cursor, 4);

      final AyahAlignment twice = align(
        session: once,
        heard: <String>['الرحيم'],
      );
      expect(twice.cursor, 4, reason: 'the cursor never goes backwards');
    });

    test('a segment that starts mid-verse aligns to the right words', () {
      final AyahAlignment mid = fresh.copyWith(cursor: 2);
      final AyahAlignment result = align(
        session: mid,
        heard: <String>['الرحمن', 'الرحيم'],
      );
      expect(result.words[2].verdict, WordVerdict.correct);
      expect(result.words[3].verdict, WordVerdict.correct);
      expect(result.cursor, 4);
    });

    test('words heard that the verse does not contain are kept, not coloured', () {
      final AyahAlignment result = align(
        session: fresh,
        heard: <String>['بسم', 'الله', 'يعني', 'الرحمن', 'الرحيم'],
      );
      expect(result.extras, contains('يعني'));
      expect(result.words.every((RecitationWord w) => !w.isWrong), isTrue);
    });

    test('a repeated mistake counts, so the app can offer the word aloud', () {
      final AyahAlignment first = align(
        session: fresh,
        heard: <String>['بسم', 'الرحمن', 'الرحمن', 'الرحيم'],
      );
      expect(first.words[1].timesWrong, 1);
      final AyahAlignment second = align(
        session: AyahAlignment(surah: 1, ayah: 1, words: first.words, cursor: 1),
        heard: <String>['اللهم'],
      );
      expect(second.words[1].timesWrong, 2,
          reason: 'the same mistake twice is what earns the spoken correction');
    });

    test('an empty hypothesis changes nothing', () {
      expect(align(session: fresh, heard: <String>[]), fresh);
    });
  });

  group('splitting audio at the pauses', () {
    List<double> tone(int samples, {double amplitude = 0.3}) => <double>[
          for (int i = 0; i < samples; i++)
            amplitude * math.sin(2 * math.pi * 220 * i / 16000),
        ];

    List<double> silence(int samples) => List<double>.filled(samples, 0);

    test('silence alone produces no segment', () {
      final SpeechSegmenter segmenter = SpeechSegmenter();
      final List<SpeechSegment> segments = segmenter.accept(silence(16000 * 2));
      expect(segments, isEmpty);
    });

    test('one second of speech then a pause closes one segment', () {
      final SpeechSegmenter segmenter = SpeechSegmenter();
      final List<SpeechSegment> first = segmenter.accept(tone(16000));
      expect(first, isEmpty, reason: 'still waiting for the pause');
      final List<SpeechSegment> afterPause = segmenter.accept(silence(16000));
      expect(afterPause, hasLength(1));
      expect(afterPause.single.seconds, greaterThan(1.0));
      expect(afterPause.single.seconds, lessThan(2.0));
    });

    test('a 100 ms blip is not a segment', () {
      final SpeechSegmenter segmenter = SpeechSegmenter();
      final List<SpeechSegment> segments = <SpeechSegment>[
        ...segmenter.accept(tone(1600)),
        ...segmenter.accept(silence(16000)),
      ];
      expect(segments, isEmpty);
    });

    test('continuous speech is cut at five seconds and keeps an overlap', () {
      final SpeechSegmenter segmenter = SpeechSegmenter();
      final List<SpeechSegment> segments = segmenter.accept(tone(16000 * 7));
      expect(segments, isNotEmpty);
      expect(segments.first.seconds, closeTo(5.0, 0.1));
      // The next segment must begin with audio already heard, or the seam eats
      // a letter.
      final List<SpeechSegment> rest = segmenter.accept(silence(16000));
      expect(rest, isNotEmpty);
      expect(rest.first.seconds, greaterThan(0.4));
    });

    test('a fragment too short to trust is not sent to the recogniser', () {
      // Measured on the device: a 1.5 s tail came back as «وَالْمُؤْ», and the
      // checker accused a correct reciter. Short fragments are dropped.
      final SpeechSegment short = SpeechSegment(
        samples: List<double>.filled(16000, 0.1),
        startedAt: Duration.zero,
        endedAt: const Duration(seconds: 1),
      );
      final SpeechSegment usable = SpeechSegment(
        samples: List<double>.filled(40000, 0.1),
        startedAt: Duration.zero,
        endedAt: const Duration(seconds: 2),
      );
      expect(SpeechSegmenter.worthDecoding(short), isFalse);
      expect(SpeechSegmenter.worthDecoding(usable), isTrue);
    });

    test('flushing keeps the last words instead of dropping them', () {
      final SpeechSegmenter segmenter = SpeechSegmenter();
      segmenter.accept(tone(8000));
      final SpeechSegment? last = segmenter.flush();
      expect(last, isNotNull);
      expect(last!.seconds, greaterThan(0.4));
    });
  });
}

List<RecitationWord> _words(String ayah) {
  final List<String> display = QuranText.words(ayah);
  return <RecitationWord>[
    for (int i = 0; i < display.length; i++)
      RecitationWord(
        index: i,
        uthmani: display[i],
        consonants: QuranText.skeleton(display[i]),
        marks: QuranText.marks(display[i]),
      ),
  ];
}

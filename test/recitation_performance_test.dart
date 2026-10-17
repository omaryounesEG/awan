import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/align_recitation.dart';
import 'package:awan/features/recitation/domain/usecases/quran_text.dart';

/// Performance of the checker's own work, measured rather than assumed.
///
/// The budget: a segment arrives every few seconds, but the phone must stay at
/// 60 fps while it does. Anything under a frame (16 ms) is invisible; the test
/// holds the checker to a fifth of that so there is room for the UI, the
/// recogniser and the OS on a slow device.
void main() {
  const AlignRecitation aligner = AlignRecitation();

  late Map<String, dynamic> ayat;

  setUpAll(() {
    final Map<String, dynamic> data = jsonDecode(
      File('assets/data/quran_uthmani.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    ayat = data['ayahs'] as Map<String, dynamic>;
  });

  List<RecitationWord> wordsOf(String text) {
    final List<String> display = QuranText.words(text);
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

  test('the whole mushaf becomes skeletons and marks in a couple of seconds', () {
    final Stopwatch watch = Stopwatch()..start();
    int words = 0;
    for (final dynamic list in ayat.values) {
      for (final dynamic ayah in list as List<dynamic>) {
        for (final String word in QuranText.words(ayah as String)) {
          QuranText.skeleton(word);
          QuranText.marks(word);
          words++;
        }
      }
    }
    watch.stop();

    // ignore: avoid_print
    print('PERF: $words words prepared in ${watch.elapsedMilliseconds} ms');
    expect(words, greaterThan(70000));
    expect(watch.elapsedMilliseconds, lessThan(4000),
        reason: 'the first-run database build must not feel like a hang');
  });

  test('aligning one hypothesis costs a fraction of a frame', () {
    // The longest verse in the Qur'an, plus a realistic 6-word hypothesis.
    final List<RecitationWord> long = wordsOf(
      (ayat['2'] as List<dynamic>)[281] as String,
    );
    final AyahAlignment session = AyahAlignment(surah: 2, ayah: 282, words: long);
    final List<String> heard = <String>[
      for (int i = 0; i < 6; i++) long[i].uthmani,
    ];

    // Warm-up, then measure.
    for (int i = 0; i < 5; i++) {
      aligner(session: session, heard: heard);
    }
    final Stopwatch watch = Stopwatch()..start();
    const int runs = 200;
    for (int i = 0; i < runs; i++) {
      aligner(session: session, heard: heard);
    }
    watch.stop();

    final double perRun = watch.elapsedMicroseconds / runs / 1000.0;
    // ignore: avoid_print
    print('PERF: align ${long.length} words = ${perRun.toStringAsFixed(2)} ms/hypothesis');
    expect(perRun, lessThan(3.0));
  });

  test('a full session of segments stays well inside the budget', () {
    final List<RecitationWord> words = wordsOf(
      (ayat['1'] as List<dynamic>)[6] as String, // Al-Fatiha 7
    );
    AyahAlignment session = AyahAlignment(surah: 1, ayah: 7, words: words);

    final Stopwatch watch = Stopwatch()..start();
    for (int i = 0; i < words.length; i++) {
      session = aligner(session: session, heard: <String>[words[i].uthmani]);
    }
    watch.stop();

    // ignore: avoid_print
    print('PERF: whole ayah, segment per word = ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsedMilliseconds, lessThan(60));
    expect(session.cursor, words.length);
  });
}

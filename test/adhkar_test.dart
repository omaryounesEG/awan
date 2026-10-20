import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/features/adhkar/data/adhkar_progress_store.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';

/// The chapter is scraped from hisnmuslim.com, so the first thing to pin is
/// that the file the app ships is the chapter the reader expects: twenty-four
/// adhkar, both languages filled, a recitation for each, and a count above one
/// only where the page asks for a repetition.
void main() {
  group('bundled chapter', () {
    late Map<String, dynamic> doc;

    setUpAll(() {
      doc = jsonDecode(
        File('assets/adhkar/morning_evening.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('has twenty-four adhkar', () {
      expect((doc['items'] as List<dynamic>).length, 24);
    });

    test('every dhikr carries both languages, its audio, and a real count', () {
      for (final dynamic raw in doc['items'] as List<dynamic>) {
        final AdhkarItem? item = AdhkarItem.fromJson(raw);
        expect(item, isNotNull);
        expect(item!.ar.length, greaterThan(20), reason: 'id ${item.id} ar');
        expect(item.en.length, greaterThan(20), reason: 'id ${item.id} en');
        expect(item.audioUrl, startsWith('https://'));
        expect(item.audioUrl, endsWith('.mp3'));
        expect(item.repeat, inInclusiveRange(1, 100));
      }
    });

    test('ids are unique', () {
      final List<int> ids = (doc['items'] as List<dynamic>)
          .map((dynamic e) => AdhkarItem.fromJson(e)!.id)
          .toList();
      expect(ids.toSet().length, ids.length);
    });

    test('the repetitions the page spells out are the ones we count', () {
      final Map<int, int> reps = <int, int>{
        for (final dynamic raw in doc['items'] as List<dynamic>)
          AdhkarItem.fromJson(raw)!.id: AdhkarItem.fromJson(raw)!.repeat,
      };
      // The threefold dhikr, the hundredfold tasbih, the tenfold takbir.
      expect(reps.values.where((int v) => v == 3).length, greaterThanOrEqualTo(5));
      expect(reps.values.where((int v) => v == 100).length, greaterThanOrEqualTo(2));
      expect(reps.values.where((int v) => v == 10).length, greaterThanOrEqualTo(2));
    });
  });

  group('AdhkarItem', () {
    test('falls back to Arabic when the translation is empty', () {
      const AdhkarItem item = AdhkarItem(
        id: 1,
        repeat: 1,
        audioUrl: 'https://x/y.mp3',
        ar: 'ذكر',
        en: '',
      );
      expect(item.textFor('en'), 'ذكر');
      expect(item.textFor('ar'), 'ذكر');
    });

    test('rejects a record without an id', () {
      expect(AdhkarItem.fromJson(<String, Object?>{'ar': 'x'}), isNull);
      expect(AdhkarItem.fromJson('not a map'), isNull);
    });
  });

  group('progress', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    const List<AdhkarItem> items = <AdhkarItem>[
      AdhkarItem(id: 1, repeat: 1, audioUrl: '', ar: 'a', en: 'a'),
      AdhkarItem(id: 2, repeat: 3, audioUrl: '', ar: 'b', en: 'b'),
    ];
    final DateTime day = DateTime(2026, 10, 20);

    test('an empty day is zero of two', () {
      final AdhkarSessionProgress p =
          AdhkarSessionProgress.of(items, const <int, int>{});
      expect(p.doneItems, 0);
      expect(p.totalItems, 2);
      expect(p.ratio, 0);
      expect(p.finished, isFalse);
    });

    test('the second dhikr closes only on its third count', () async {
      final AdhkarProgressStore store = AdhkarProgressStore();
      await store.increment(day, AdhkarSession.morning, items[1]);
      await store.increment(day, AdhkarSession.morning, items[1]);
      AdhkarSessionProgress p = AdhkarSessionProgress.of(
        items,
        await store.countsFor(day, AdhkarSession.morning),
      );
      expect(p.doneItems, 0);
      expect(p.counts[2], 2);

      await store.increment(day, AdhkarSession.morning, items[1]);
      p = AdhkarSessionProgress.of(
        items,
        await store.countsFor(day, AdhkarSession.morning),
      );
      expect(p.doneItems, 1);
      expect(p.ratio, 0.5);
    });

    test('a count never climbs past its repetition', () async {
      final AdhkarProgressStore store = AdhkarProgressStore();
      for (int i = 0; i < 9; i++) {
        await store.increment(day, AdhkarSession.evening, items[1]);
      }
      expect(
        (await store.countsFor(day, AdhkarSession.evening))[2],
        3,
      );
    });

    test('the two sittings do not bleed into each other', () async {
      final AdhkarProgressStore store = AdhkarProgressStore();
      await store.complete(day, AdhkarSession.morning, items[0]);
      expect((await store.countsFor(day, AdhkarSession.morning))[1], 1);
      expect((await store.countsFor(day, AdhkarSession.evening))[1], isNull);
    });

    test('reset clears one dhikr and one sitting', () async {
      final AdhkarProgressStore store = AdhkarProgressStore();
      await store.complete(day, AdhkarSession.morning, items[0]);
      await store.complete(day, AdhkarSession.morning, items[1]);
      await store.resetItem(day, AdhkarSession.morning, 1);
      expect(await store.countsFor(day, AdhkarSession.morning),
          <int, int>{2: 3});
      await store.resetSession(day, AdhkarSession.morning);
      expect(await store.countsFor(day, AdhkarSession.morning), isEmpty);
    });

    test('days are stored under a sortable key and read back whole', () async {
      final AdhkarProgressStore store = AdhkarProgressStore();
      await store.complete(DateTime(2026, 10, 5), AdhkarSession.morning, items[0]);
      await store.complete(DateTime(2026, 10, 20), AdhkarSession.evening, items[1]);
      final Map<String, AdhkarDayCounts> all = await store.readAll();
      expect(all.keys, containsAll(<String>['2026-10-05', '2026-10-20']));
      expect(all['2026-10-05']!.morning[1], 1);
      expect(all['2026-10-20']!.evening[2], 3);
    });

    test('a corrupt store does not throw away the day', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adhkar_progress_v1': '{not json',
      });
      final AdhkarProgressStore store = AdhkarProgressStore();
      expect(await store.readAll(), isEmpty);
      await store.complete(day, AdhkarSession.morning, items[0]);
      expect((await store.readAll()).length, 1);
    });
  });
}

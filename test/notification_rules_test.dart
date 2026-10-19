import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/data/repositories/prayer_repository_impl.dart';

/// Two rules the reader asked for by name, kept where a rename or a tweak would
/// otherwise quietly undo them.
void main() {
  test('the count-up after an adhan lasts twenty minutes', () {
    expect(PrayerRepositoryImpl.elapsedWindow, const Duration(minutes: 20));
  });

  group('alert labels', () {
    Map<String, dynamic> arb(String lang) => jsonDecode(
          File('lib/l10n/app_$lang.arb').readAsStringSync(),
        ) as Map<String, dynamic>;

    test('the bundled clips are numbered, not named after their files', () {
      for (final String lang in <String>['ar', 'en']) {
        final Map<String, dynamic> strings = arb(lang);
        final String prefix = lang == 'ar' ? 'تنبيه ' : 'Alert ';
        for (final (String key, int n) in <(String, int)>[
          ('soundTakbir', 1),
          ('soundCall', 2),
          ('soundAdhan', 3),
          ('soundRing', 4),
        ]) {
          expect(
            strings[key],
            '$prefix$n',
            reason: '$lang/$key must not mention the raw asset name',
          );
        }
      }
    });

    test('no label leaks an asset file name', () {
      for (final String lang in <String>['ar', 'en']) {
        for (final MapEntry<String, dynamic> entry in arb(lang).entries) {
          if (!entry.key.startsWith('sound')) continue;
          expect(
            '${entry.value}',
            isNot(matches(RegExp(r'azan_salah|nokia_notification|aser_ela|allah_akbar'))),
            reason: '${entry.key} in $lang',
          );
        }
      }
    });
  });
}

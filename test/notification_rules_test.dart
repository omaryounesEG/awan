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

    test('the clips keep the names printed on the files: adhan 1–2, alert 1–3',
        () {
      const Map<String, (String, String)> expected = <String, (String, String)>{
        'soundAdhan1': ('أذان ١', 'Adhan 1'),
        'soundAdhan2': ('أذان ٢', 'Adhan 2'),
        'soundTanbih1': ('تنبيه ١', 'Alert 1'),
        'soundTanbih2': ('تنبيه ٢', 'Alert 2'),
        'soundTanbih3': ('تنبيه ٣', 'Alert 3'),
      };
      final Map<String, dynamic> ar = arb('ar');
      final Map<String, dynamic> en = arb('en');
      expected.forEach((String key, (String, String) names) {
        expect(ar[key], names.$1, reason: 'ar/$key');
        expect(en[key], names.$2, reason: 'en/$key');
      });
    });

    test('no label leaks an asset file name', () {
      for (final String lang in <String>['ar', 'en']) {
        for (final MapEntry<String, dynamic> entry in arb(lang).entries) {
          if (!entry.key.startsWith('sound')) continue;
          expect(
            '${entry.value}',
            isNot(matches(RegExp(r'azan_salah|nokia_notification|aser_ela|allah_akbar|adhan_1|tanbih_'))),
            reason: '${entry.key} in $lang',
          );
        }
      }
    });
  });
}

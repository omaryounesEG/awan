import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/mosque_radar/data/user_mosque_store.dart';
import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';

/// Two small promises the radar now makes: a pin the reader placed survives a
/// restart and can be removed, and an unresolved automatic location is never
/// mistaken for "the reader is in Cairo".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('user mosques', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('a saved pin comes back with its coordinates', () async {
      final UserMosqueStore store = UserMosqueStore();
      await store.add(UserMosque(
        id: 'user:1',
        name: 'مسجد الحي',
        latitude: 31.2001,
        longitude: 29.9187,
        createdAt: DateTime(2026, 10, 18, 12),
      ));

      // A fresh store, as if the app had been restarted.
      final List<UserMosque> again = await UserMosqueStore().list();
      expect(again, hasLength(1));
      expect(again.single.name, 'مسجد الحي');
      expect(again.single.latitude, closeTo(31.2001, 1e-9));
      expect(again.single.accuracyMeters, UserMosque.defaultAccuracyMeters);
    });

    test('standing in the same mosque twice keeps one pin', () async {
      final UserMosqueStore store = UserMosqueStore();
      const double lat = 24.7136;
      const double lng = 46.6753;
      await store.add(UserMosque(
          id: 'a', latitude: lat, longitude: lng, createdAt: DateTime(2026)));
      await store.add(UserMosque(
          id: 'b', latitude: lat, longitude: lng, createdAt: DateTime(2026)));

      final List<UserMosque> all = await store.list();
      expect(all, hasLength(1), reason: 'one place, one pin');
      expect(all.single.id, 'b', reason: 'the newer capture wins');
    });

    test('removing a pin leaves the rest alone', () async {
      final UserMosqueStore store = UserMosqueStore();
      await store.add(UserMosque(
          id: 'keep', latitude: 30.0, longitude: 31.0, createdAt: DateTime(2026)));
      await store.add(UserMosque(
          id: 'drop', latitude: 30.5, longitude: 31.5, createdAt: DateTime(2026)));

      final (List<UserMosque> left, bool removed) = await store.remove('drop');
      expect(removed, isTrue);
      expect(left.map((UserMosque m) => m.id), <String>['keep']);

      final (List<UserMosque> unchanged, bool again) = await store.remove('drop');
      expect(again, isFalse);
      expect(unchanged, hasLength(1));
    });

    test('a corrupt blob is a miss, not a crash', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{'user_mosques_v1': '{not json'},
      );
      expect(await UserMosqueStore().list(), isEmpty);
    });
  });

  group('location honesty', () {
    test('untouched automatic mode reports the default as unset', () {
      const AppSettings s = AppSettings();
      expect(s.locationIsDefault, isTrue);
    });

    test('a real fix is not the default', () {
      const AppSettings s = AppSettings(latitude: 31.2001, longitude: 29.9187);
      expect(s.locationIsDefault, isFalse);
    });

    test('a hand-picked city is a legitimate location, not a missing one', () {
      const AppSettings s = AppSettings(locationMode: 'manual');
      expect(s.locationIsDefault, isFalse,
          reason: 'the reader chose Cairo; the radar may show Cairo');
    });
  });
}

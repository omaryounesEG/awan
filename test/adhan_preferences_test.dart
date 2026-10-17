import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/settings/adhan_preferences.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';

/// Per-adhan choices: one preference string carries five prayers' worth of
/// decisions, so the codec is the part that must not drift.
void main() {
  group('AdhanPreferences', () {
    test('defaults are the ones the app ships with', () {
      const AdhanPreferences prefs = AdhanPreferences();

      expect(prefs.alertModeFor('fajr'), AdhanAlertMode.tone);
      expect(prefs.silentStartFor('isha'), 0);
      expect(prefs.silentDurationFor('isha'), 15);
    });

    test('a mode set for one prayer leaves the others alone', () {
      final AdhanPreferences prefs =
          const AdhanPreferences().withAlertMode('fajr', AdhanAlertMode.quiet);

      expect(prefs.alertModeFor('fajr'), AdhanAlertMode.quiet);
      expect(prefs.alertModeFor('dhuhr'), AdhanAlertMode.tone);
    });

    test('survives the round trip through the stored string', () {
      final AdhanPreferences prefs = const AdhanPreferences()
          .withAlertMode('fajr', AdhanAlertMode.vibrate)
          .withSilentWindow('asr', startMinutes: 15)
          .withSilentWindow('maghrib', minutes: 20);

      final AdhanPreferences back = AdhanPreferences.decode(prefs.encode());

      expect(back.alertModeFor('fajr'), AdhanAlertMode.vibrate);
      expect(back.alertModeFor('asr'), AdhanAlertMode.tone);
      expect(back.silentStartFor('asr'), 15);
      expect(back.silentDurationFor('maghrib'), 20);
      expect(back.silentDurationFor('asr'), AdhanPreferences.defaultSilentMinutes);
    });

    test('a missing or damaged value falls back to the defaults', () {
      for (final String? raw in <String?>[null, '', '   ', 'not json', '{"alert":7}']) {
        final AdhanPreferences prefs = AdhanPreferences.decode(raw);
        expect(prefs.alertModeFor('fajr'), AdhanAlertMode.tone, reason: 'raw=$raw');
        expect(prefs.silentDurationFor('fajr'), AdhanPreferences.defaultSilentMinutes);
      }
    });

    test('every offered choice is a real one', () {
      // The screen drops anything else, but the model should not be able to hold
      // a value the data thinks is meaningful.
      for (final int start in AdhanPreferences.silentStartChoices) {
        expect(
          const AdhanPreferences()
              .withSilentWindow('fajr', startMinutes: start)
              .silentStartFor('fajr'),
          start,
        );
      }
      for (final int minutes in AdhanPreferences.silentMinutesChoices) {
        expect(
          const AdhanPreferences()
              .withSilentWindow('fajr', minutes: minutes)
              .silentDurationFor('fajr'),
          minutes,
        );
      }
    });

    test('an unknown mode value reads as the loud one', () {
      expect(AdhanAlertMode.fromWire(99), AdhanAlertMode.tone);
      expect(AdhanAlertMode.fromWire(null), AdhanAlertMode.tone);
      expect(AdhanAlertMode.fromWire(1), AdhanAlertMode.vibrate);
    });
  });
}

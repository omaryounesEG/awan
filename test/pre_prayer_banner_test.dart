import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/pre_prayer_banner.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Drives the floating hourglass exactly as the app does — same widget, same
/// providers — with the clock and the day's times pinned, so "does it appear, and
/// does a tap get rid of it" is answered in a second instead of by waiting for a
/// real prayer to come within twenty minutes.
const PrayerCalcSpec _spec = PrayerCalcSpec(
  latitude: 30.0444,
  longitude: 31.2357,
  method: PrayerMethod.egyptian,
  madhab: AsrMadhab.shafi,
  highLatitude: HighLatitude.middleOfTheNight,
);

DayPrayerTimes _day({required DateTime asr}) => DayPrayerTimes(
      date: DateTime(asr.year, asr.month, asr.day),
      times: <PrayerName, DateTime>{
        PrayerName.fajr: asr.subtract(const Duration(hours: 10)),
        PrayerName.dhuhr: asr.subtract(const Duration(hours: 3)),
        PrayerName.asr: asr,
        PrayerName.maghrib: asr.add(const Duration(hours: 3)),
        PrayerName.isha: asr.add(const Duration(hours: 5)),
      },
      spec: _spec,
      computedAt: asr,
    );

Future<void> _pump(
  WidgetTester tester, {
  required AppSettings settings,
  required DayPrayerTimes day,
  required DateTime now,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWithValue(settings),
        nowProvider.overrideWithValue(now),
        dayPrayerTimesProvider.overrideWith(
          (Ref ref, DateTime date) async => day,
        ),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              SizedBox.expand(),
              PrePrayerBanner(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('appears inside the window, and one tap takes it away',
      (WidgetTester tester) async {
    final DateTime asr = DateTime(2026, 10, 10, 15, 45);
    await _pump(
      tester,
      settings: const AppSettings(preAdhanEnabled: true, preAdhanMinutes: 20),
      day: _day(asr: asr),
      now: DateTime(2026, 10, 10, 15, 31),
    );

    // 14 minutes left: the card names the prayer and the countdown. 14 is in
    // Arabic's "many" band, so the noun stays singular — the plural bands are
    // asserted in the plainer test below.
    expect(find.text('باقي 14 دقيقة على العصر'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.hourglass_bottom), findsNothing,
        reason: 'a tap dismisses it, with no side effects');
    expect(find.textContaining('العصر'), findsNothing);
  });

  testWidgets('counts down in the reader\'s own grammar', (
    WidgetTester tester,
  ) async {
    final DateTime asr = DateTime(2026, 10, 10, 15, 45);
    // Five minutes left: "few" in Arabic takes the plural (دقائق).
    await _pump(
      tester,
      settings: const AppSettings(preAdhanEnabled: true, preAdhanMinutes: 20),
      day: _day(asr: asr),
      now: DateTime(2026, 10, 10, 15, 40),
    );
    expect(find.text('باقي 5 دقائق على العصر'), findsOneWidget);
    expect(find.text('تجهّز لصلاة العصر'), findsOneWidget);
  });

  testWidgets('says "one minute" in the singular', (WidgetTester tester) async {
    await _pump(
      tester,
      settings: const AppSettings(preAdhanEnabled: true, preAdhanMinutes: 20),
      day: _day(asr: DateTime(2026, 10, 10, 15, 45)),
      now: DateTime(2026, 10, 10, 15, 44),
    );
    expect(find.text('باقي دقيقة على العصر'), findsOneWidget);
  });

  testWidgets('stays away outside the window', (WidgetTester tester) async {
    await _pump(
      tester,
      settings: const AppSettings(preAdhanEnabled: true, preAdhanMinutes: 20),
      day: _day(asr: DateTime(2026, 10, 10, 15, 45)),
      // An hour before the window opens.
      now: DateTime(2026, 10, 10, 14, 45),
    );
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
  });

  testWidgets('stays away when the reader turned the reminder off',
      (WidgetTester tester) async {
    await _pump(
      tester,
      settings: const AppSettings(preAdhanEnabled: false),
      day: _day(asr: DateTime(2026, 10, 10, 15, 45)),
      now: DateTime(2026, 10, 10, 15, 40),
    );
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
  });

  testWidgets('shows the soft-chime state on the card', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      settings: const AppSettings(
        preAdhanEnabled: true,
        preAdhanSound: AdhanSound.system,
      ),
      day: _day(asr: DateTime(2026, 10, 10, 15, 45)),
      now: DateTime(2026, 10, 10, 15, 40),
    );
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget,
        reason: 'the card tells the reader the reminder will chime');
  });
}

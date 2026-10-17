import 'package:awan/l10n/app_localizations.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';

/// Shared presentation vocabulary.
///
/// Lives outside the features so the notification text (built in the data
/// layer, off a `BuildContext`) and the widgets use exactly the same words.

String prayerLabel(AppLocalizations l10n, PrayerName prayer) => switch (prayer) {
      PrayerName.fajr => l10n.fajr,
      PrayerName.sunrise => l10n.sunrise,
      PrayerName.dhuhr => l10n.dhuhr,
      PrayerName.asr => l10n.asr,
      PrayerName.maghrib => l10n.maghrib,
      PrayerName.isha => l10n.isha,
    };

/// 12h clock for Arabic (how Islamic timetables are read), 24h for English.
String formatClock(DateTime time, String localeCode, {bool force24 = false}) {
  final String hh = time.hour.toString().padLeft(2, '0');
  final String mm = time.minute.toString().padLeft(2, '0');
  if (localeCode != 'ar' || force24) return '$hh:$mm';
  final int hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour < 12 ? 'ص' : 'م';
  return '$hour12:${time.minute.toString().padLeft(2, '0')} $suffix';
}

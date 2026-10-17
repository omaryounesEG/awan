import 'package:awan/l10n/app_localizations.dart';

/// "14 minutes to Asr" in the reader's own grammar.
///
/// Arabic counts in bands: one minute, two minutes, then the plural (3-10,
/// دقائق) and back to the singular from eleven up (دقيقة) — «باقي 5 دقيقة» reads
/// as broken Arabic. The band is picked here rather than handed to ICU, whose
/// nested placeholders inside plural branches gen-l10n refuses to parse
/// ("Expected } but found ,").
String prePrayerHeadline(AppLocalizations l10n, int minutes, String prayer) {
  if (minutes <= 1) return l10n.reminderSoonOne(prayer);
  if (minutes == 2) return l10n.reminderSoonTwo(prayer);
  if (minutes <= 10) return l10n.reminderSoonFew(minutes, prayer);
  return l10n.reminderSoonMany(minutes, prayer);
}

import 'package:awan/l10n/app_localizations.dart';
import 'package:awan/l10n/app_localizations_ar.dart';
import 'package:awan/l10n/app_localizations_en.dart';
import 'package:flutter/widgets.dart';

/// Localization helpers.
///
/// The app ships two full interfaces (Arabic RTL / English LTR) that can be
/// flipped at any moment from the home screen or the settings.

/// Context-bound accessor: `context.l10n.fajr`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Context-free accessor for non-widget callers (notification text, background
/// tasks) — the generated per-locale classes are public and cheap.
AppLocalizations localizationsFor(String localeCode) => localeCode == 'ar'
    ? AppLocalizationsAr()
    : AppLocalizationsEn();

const List<Locale> kSupportedLocales = <Locale>[
  Locale('ar'),
  Locale('en'),
];

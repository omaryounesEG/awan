# Step 2 — Theming, Localization (RTL) and Elderly Mode

Status: **implemented and verified** (`flutter analyze` clean, `flutter test` 8/8,
debug APK builds).

---

## What was built

| File | Role |
| --- | --- |
| `lib/core/constants/app_colors.dart` | The Zen palette: sand `#F5F2EB` light, OLED `#000000` dark, ink that never goes pure white |
| `lib/core/constants/app_typography.dart` | `GoogleFonts.ibmPlexSansArabicTextTheme()` + the separate Quran face + font preload |
| `lib/core/theme/app_theme.dart` | `AppTheme.lightTheme()` / `AppTheme.darkTheme()` from one spec |
| `lib/core/theme/app_settings_provider.dart` | `@riverpod` notifier, `AppUiSettings` (themeMode, isElderlyMode, textScale, locale) |
| `lib/core/theme/…` + `lib/app.dart` | `ScreenUtilInit` above `MaterialApp`, RTL/LTR frame, elderly text scale |
| `lib/l10n/app_ar.arb`, `app_en.arb` | 213 keys each — the two interfaces are complete, not token sets |

## Why two layers for settings

* `SettingsController` (core/settings) owns **persistence** — one JSON snapshot in
  `SharedPreferences`, written atomically, so the app theme is known before the
  first frame and no database has to be opened on the cold-start path.
* `AppUiSettings` (core/theme) is the **reactive slice the UI reads**. Toggling
  the theme therefore cannot rebuild the notification scheduler, and a location
  change cannot rebuild the settings screen.

## Elderly mode

It is a **scale, not a third theme**: `MediaQuery.withClampedTextScaling(min=max=
textScale)` at the root, so every widget — including ones written later — obeys it
with no per-screen work. On top of that the dashboard swaps its layout (three
full-width targets instead of a 3-up grid) and a floating "turn off" button is
always visible, so the mode can never trap the user.

`flutter_screenutil` covers the other axis: sizes are expressed in `.sp`/`.w`/`.h`
against a 390×844 canvas, so a large phone and a small phone look the same, while
elderly mode scales *text* on top of that.

## Localization: how the files are generated

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
synthetic-package: false     # generate INTO the repo, not into .dart_tool
```

Then:

```bash
flutter pub get
flutter gen-l10n          # reads the ARBs, writes lib/l10n/app_localizations*.dart
```

With `synthetic-package: false` the three generated files are real, committed
source (`app_localizations.dart`, `app_localizations_ar.dart`,
`app_localizations_en.dart`), which is what lets `lib/core/l10n/l10n.dart` build
the non-widget accessors used by the notification text:

```dart
AppLocalizations localizationsFor(String localeCode) =>
    localeCode == 'ar' ? AppLocalizationsAr() : AppLocalizationsEn();
```

Adding a key = add it to **both** ARBs, run `flutter gen-l10n`, use
`context.l10n.myKey`. A key missing from `app_ar.arb` fails the generator rather
than silently falling back to English.

## RTL / LTR

`MaterialApp.locale` drives the generated delegate, but the app also sets
`Directionality` explicitly at the root from `AppUiSettings.isArabic`. Reason: the
*interface* language must decide the direction of surface content (prayer names,
hijri dates, the timetable), independently of the phone's system language — a user
running an English phone with the Arabic interface still gets RTL.

## Verified

```bash
flutter analyze     # 0 errors, 0 warnings
flutter test        # 8/8 — prayer-engine domain tests
flutter build apk --debug
```

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography (Task 1 of Step 2).
///
/// * **UI text** — IBM Plex Sans Arabic through `google_fonts`
///   (`ibmPlexSansArabicTextTheme()`), so weights and the family stay in sync
///   with one call and every style carries the family Google registers.
/// * **Quran text** — a *separate* family, bundled as an asset instead of
///   fetched: the scripture must render on a plane with no network and no
///   first-run download, and its Uthmani vowel marks need the dedicated face.
class AppTypography {
  AppTypography._();

  /// Registered by the bundled `fonts:` section of `pubspec.yaml`.
  static const String uiFamilyGoogle = 'IBMPlexSansArabic';
  static const String quranUthmaniFamily = 'AmiriQuran';
  static const String quranScheherazadeFamily = 'ScheherazadeNew';

  /// Reader choices, persisted as plain keys.
  static const Map<String, String> quranFonts = <String, String>{
    'uthmani': quranUthmaniFamily,
    'scheherazade': quranScheherazadeFamily,
  };

  /// The UI text theme.
  ///
  /// `GoogleFonts.ibmPlexSansArabicTextTheme()` supplies the family for every
  /// role; the sizes, line heights and colours below are the app's own so the
  /// two interfaces (AR/EN) and both themes stay identical in rhythm.
  static TextTheme textTheme(Color ink, Color inkSoft) {
    final TextTheme family = GoogleFonts.ibmPlexSansArabicTextTheme();

    TextStyle? style(
      TextStyle? base, {
      required double size,
      required double height,
      required FontWeight weight,
      Color? color,
    }) =>
        base?.copyWith(
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: color ?? ink,
        );

    return TextTheme(
      displaySmall: style(family.displaySmall,
          size: 34, height: 1.25, weight: FontWeight.w600),
      headlineMedium: style(family.headlineMedium,
          size: 26, height: 1.30, weight: FontWeight.w600),
      headlineSmall: style(family.headlineSmall,
          size: 22, height: 1.35, weight: FontWeight.w600),
      titleLarge: style(family.titleLarge,
          size: 19, height: 1.40, weight: FontWeight.w600),
      titleMedium: style(family.titleMedium,
          size: 16.5, height: 1.45, weight: FontWeight.w500),
      bodyLarge: style(family.bodyLarge,
          size: 16, height: 1.60, weight: FontWeight.w400),
      bodyMedium: style(family.bodyMedium,
          size: 14.5, height: 1.60, weight: FontWeight.w400),
      bodySmall: style(family.bodySmall,
          size: 12.5, height: 1.50, weight: FontWeight.w400, color: inkSoft),
      labelLarge: style(family.labelLarge,
          size: 15, height: 1.20, weight: FontWeight.w600),
      labelMedium: style(family.labelMedium,
          size: 13, height: 1.20, weight: FontWeight.w500, color: inkSoft),
    );
  }

  /// The scripture style — never mixed with UI text.
  static TextStyle quran(
    double size, {
    String family = quranUthmaniFamily,
    Color color = Colors.black,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: 2.0,
        color: color,
        wordSpacing: 0.5,
      );

  /// Warms the font cache before the first frame so switching language, theme
  /// or elderly mode never shows a flash of the fallback font.
  ///
  /// `allowRuntimeFetching = false` is deliberate: the five weights are bundled
  /// in `assets/google_fonts/`, so an offline-first app never depends on
  /// fonts.gstatic.com being reachable.
  static Future<void> preload() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    try {
      await GoogleFonts.pendingFonts(<TextStyle>[
        GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w300),
        GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w400),
        GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w500),
        GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
        GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
      ]);
    } catch (_) {
      // A missing weight must never stop the app from starting.
    }
  }
}

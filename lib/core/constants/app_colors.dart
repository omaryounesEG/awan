import 'package:flutter/material.dart';

/// The "Zen / spiritual calmness" palette (Task 1 of Step 2).
///
/// * **Light (day)** — sand & beige paper (`#F5F2EB`) with a calm petrol-green
///   primary so that long reading sessions never strain the eye.
/// * **Dark (night)** — true OLED black (`#000000`) with an off-white ink
///   (never pure white), which is what removes halation around Arabic glyphs
///   and saves power on an OLED panel at the same time.
///
/// Colour roles are named by *intent* (`sand`, `oled`, `ink`) rather than by
/// hue, so a future re-theme only touches this file.
class AppColors {
  AppColors._();

  // ------------------------------------------------------------- light/day
  /// Background: sand paper.
  static const Color sand = Color(0xFFF5F2EB);

  /// Slightly deeper sand for grouped blocks / input fills.
  static const Color sandHigh = Color(0xFFEFEAE0);

  /// Card surface, a touch lighter than the background for quiet separation.
  static const Color sandCard = Color(0xFFFBF9F4);

  /// Primary ink: deep olive-charcoal, softer than pure black.
  static const Color ink = Color(0xFF232722);

  /// Secondary ink for captions and metadata.
  static const Color inkSoft = Color(0xFF5B6159);

  // ------------------------------------------------------------- dark/night
  /// OLED black background.
  static const Color oled = Color(0xFF000000);

  /// Elevated dark surface (navigation bar, drawers, sheets).
  static const Color oledHigh = Color(0xFF0B0C0B);

  /// Card surface in the dark theme.
  static const Color oledCard = Color(0xFF121312);

  /// Off-white ink (avoids the glow/halation of `#FFFFFF` on OLED).
  static const Color inkNight = Color(0xFFE7E5E0);
  static const Color inkNightSoft = Color(0xFF9BA09A);

  // ------------------------------------------------------------ brand hues
  /// Muted petroleum green — the light theme's primary.
  static const Color primaryLight = Color(0xFF1F4E46);

  /// The same hue lifted for dark backgrounds (contrast, not saturation).
  static const Color primaryDark = Color(0xFF86C3B4);

  static const Color primaryContainerLight = Color(0xFFD7E6E0);
  static const Color primaryContainerDark = Color(0xFF12312C);

  /// Warm brass accent, used sparingly (hijri date, the "next prayer" ring).
  static const Color brassLight = Color(0xFF9A7B3F);
  static const Color brassDark = Color(0xFFD8BC7E);

  // ----------------------------------------------------------------- states
  static const Color errorLight = Color(0xFF8C3B2E);
  static const Color errorDark = Color(0xFFE7A79B);
  static const Color okLight = Color(0xFF2E6B4F);
  static const Color okDark = Color(0xFF8FD3AE);

  /// Radar marker / user-position dot.
  static const Color radar = Color(0xFF2C7A6B);

  /// The "you are facing the qibla" state (Step 6 asks for deep olive green).
  static const Color oliveLight = Color(0xFF4C6B2F);
  static const Color oliveDark = Color(0xFF9FC77A);

  static const Color dividerLight = Color(0xFFE2DCCF);
  static const Color dividerDark = Color(0xFF232523);
}

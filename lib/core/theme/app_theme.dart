import 'package:flutter/material.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/constants/app_typography.dart';

/// Theme construction (Task 2 of Step 2).
///
/// One private builder produces both faces of the app from the same spec, so no
/// surface can differ between light and dark, or between the Arabic and English
/// interfaces.
///
/// Elderly mode deliberately gets **no** third theme: it is a *scale*, applied
/// through `MediaQuery.textScaler`, which keeps colours and shapes single-
/// sourced and makes the mode instant to toggle (a rebuild, not a re-theme).
class AppTheme {
  AppTheme._();

  /// Shared geometry tokens.
  static const double radius = 18;
  static const double radiusSmall = 12;

  static ThemeData lightTheme() => _build(Brightness.light);

  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background = isDark ? AppColors.oled : AppColors.sand;
    final Color surface = isDark ? AppColors.oledCard : AppColors.sandCard;
    final Color surfaceHigh = isDark ? AppColors.oledHigh : AppColors.sandHigh;
    final Color ink = isDark ? AppColors.inkNight : AppColors.ink;
    final Color inkSoft = isDark ? AppColors.inkNightSoft : AppColors.inkSoft;
    final Color primary =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color primaryContainer =
        isDark ? AppColors.primaryContainerDark : AppColors.primaryContainerLight;
    final Color secondary = isDark ? AppColors.brassDark : AppColors.brassLight;
    final Color error = isDark ? AppColors.errorDark : AppColors.errorLight;
    final Color divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF06201B) : Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: ink,
      secondary: secondary,
      onSecondary: isDark ? const Color(0xFF2A1F07) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF2A2418) : const Color(0xFFF1E7D2),
      onSecondaryContainer: ink,
      error: error,
      onError: isDark ? const Color(0xFF2B0B04) : Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: surfaceHigh,
      outline: divider,
      outlineVariant: divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: background,
      inversePrimary: primary,
    );

    final TextTheme text = AppTypography.textTheme(ink, inkSoft);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // The sand paper / OLED black decision lands here.
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: AppTypography.uiFamilyGoogle,
      textTheme: text,
      primaryTextTheme: text,
      dividerColor: divider,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: ink, size: 22),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: divider.withOpacity(isDark ? 0.6 : 0.9)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: text.labelLarge,
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: ink,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: text.bodyMedium?.copyWith(color: inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.oledHigh : AppColors.sandCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryContainer,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(color: ink),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.oledHigh : AppColors.sandCard,
        indicatorColor: primaryContainer,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: inkSoft),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.oledHigh : AppColors.sandCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.oledHigh : AppColors.sandCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.oledCard : AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? AppColors.inkNight : AppColors.sand,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: divider,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected)
              ? (isDark ? const Color(0xFF06201B) : Colors.white)
              : inkSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) =>
              s.contains(WidgetState.selected) ? primary : divider,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: primaryContainer,
        side: BorderSide(color: divider),
        labelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: inkSoft,
        indicatorColor: primary,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: divider,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: divider),
        ),
        textStyle: text.bodySmall,
      ),
    );
  }
}

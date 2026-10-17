import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';

part 'app_settings_provider.g.dart';

/// The *presentation* view of the settings (Task 4 of Step 2).
///
/// Two layers, on purpose:
///
/// * `SettingsController` (core/settings) owns persistence — the whole JSON blob
///   with location, prayer parameters, notifications and library state.
/// * `AppUiSettings` is the small, reactive slice the UI actually reads: the
///   theme mode, elderly mode and the effective text scale. Screens depend on
///   *this*, so toggling the theme cannot rebuild the notification scheduler and
///   vice versa.
@immutable
class AppUiSettings extends Equatable {
  const AppUiSettings({
    required this.themeMode,
    required this.isElderlyMode,
    required this.textScale,
    required this.localeCode,
  });

  final ThemeMode themeMode;
  final bool isElderlyMode;

  /// Already elderly-aware: `max(configured, 1.5)` while elderly mode is on.
  final double textScale;

  final String localeCode;

  bool get isArabic => localeCode == 'ar';
  bool get isDark => themeMode == ThemeMode.dark;

  @override
  List<Object?> get props =>
      <Object?>[themeMode, isElderlyMode, textScale, localeCode];
}

/// `@riverpod` (generator) notifier — the canonical Riverpod 2 pattern: no
/// manual `StateNotifierProvider` boilerplate, and `keepAlive` because UI
/// preferences must survive tab switches.
@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppUiSettings build() {
    // Rebuilds only when the persistent settings actually change.
    final AppSettings settings = ref.watch(settingsProvider);
    return AppUiSettings(
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      isElderlyMode: settings.elderlyMode,
      textScale: settings.effectiveTextScale,
      localeCode: settings.localeCode,
    );
  }

  Future<void> toggleTheme() =>
      setThemeMode(state.isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setThemeMode(ThemeMode mode) =>
      ref.read(settingsControllerProvider.notifier).setThemeMode(
            switch (mode) {
              ThemeMode.light => 'light',
              ThemeMode.dark => 'dark',
              ThemeMode.system => 'system',
            },
          );

  Future<void> toggleElderlyMode() =>
      setElderlyMode(!state.isElderlyMode);

  Future<void> setElderlyMode(bool value) =>
      ref.read(settingsControllerProvider.notifier).setElderlyMode(value);

  /// Manual scale, used by the "text size" slider (0.85 → 1.6).
  Future<void> setTextScale(double value) =>
      ref.read(settingsControllerProvider.notifier).setTextScale(value);

  Future<void> toggleLocale() =>
      ref.read(settingsControllerProvider.notifier).toggleLocale();
}

/// Friendly alias.
///
/// `riverpod_generator` names the provider after the notifier class
/// (`appSettingsNotifierProvider`); screens read the shorter
/// `appSettingsProvider`, and this alias keeps both spellings valid so a rename
/// of the class cannot ripple through the UI.
final NotifierProvider<AppSettingsNotifier, AppUiSettings> appSettingsProvider =
    appSettingsNotifierProvider;

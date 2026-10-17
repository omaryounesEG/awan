import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/background_sync_service.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/theme/app_theme.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/pre_prayer_banner.dart';
import 'package:awan/features/shell/presentation/app_shell.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The root widget (Task 5 of Step 2).
///
/// * `ScreenUtilInit` sits directly above `MaterialApp`, so every screen can
///   size itself against one design canvas (390×844) and elderly mode's larger
///   layout still fits a small phone.
/// * `themeMode` comes from `appSettingsProvider` (the `@riverpod` notifier), so
///   toggling the theme rebuilds exactly one widget subtree.
/// * `_AppFrame` fixes the *direction* from the locale and applies the elderly
///   text scale — the two things Material cannot infer by itself.
class AwanApp extends ConsumerWidget {
  const AwanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUiSettings ui = ref.watch(appSettingsProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext context, Widget? child) => MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        themeMode: ui.themeMode,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        locale: Locale(ui.localeCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (BuildContext context, Widget? child) =>
            _AppFrame(ui: ui, child: child ?? const SizedBox.shrink()),
        home: const AppShell(),
      ),
    );
  }
}

/// Applies RTL/LTR from the locale and the elderly text scale.
///
/// `Directionality` is set explicitly rather than relying on
/// `MaterialApp.locale` alone: the generated delegate handles it, but the app
/// also renders surface content (prayer names, hijri dates) that must flip with
/// the *interface* language, not with the phone's system language.
class _AppFrame extends ConsumerWidget {
  const _AppFrame({required this.ui, required this.child});

  final AppUiSettings ui;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: ui.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery.withClampedTextScaling(
        // Elderly mode's single lever: one scale factor for every widget, so no
        // screen can be missed.
        minScaleFactor: ui.textScale,
        maxScaleFactor: ui.textScale,
        // The hourglass floats above whatever route is on screen: it is mounted
        // here, above the navigator, so it cannot be covered by a pushed page or
        // lost when one is popped. `Align` (inside the banner) keeps the rest of
        // the surface tappable — only the card itself takes touches.
        child: Stack(
          children: <Widget>[
            _Bootstrapper(child: child),
            const PrePrayerBanner(),
          ],
        ),
      ),
    );
  }
}

/// Runs the one-shot start-up work once, after the first frame.
class _Bootstrapper extends ConsumerStatefulWidget {
  const _Bootstrapper({required this.child});

  final Widget child;

  @override
  ConsumerState<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends ConsumerState<_Bootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // Notification channels + cache pruning: never blocks the first frame.
    await ref.read(bootstrapProvider.future).catchError((Object _) {});
    // One-time OS hand-off: the weekly verification job. Registration itself is
    // idempotent, and the job body checks the user's opt-in flag.
    await BackgroundSyncService.registerWeeklyPrayerSync()
        .catchError((Object _) => false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

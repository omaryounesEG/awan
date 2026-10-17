import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/prayer_engine/presentation/screens/dashboard_screen.dart';
import 'package:awan/features/prayer_engine/presentation/screens/monthly_timetable_screen.dart';
import 'package:awan/features/prayer_engine/presentation/screens/qibla_screen.dart';
import 'package:awan/features/settings/presentation/screens/about_screen.dart';
import 'package:awan/features/settings/presentation/screens/settings_screen.dart';
import 'package:awan/features/tasbih/presentation/screens/tasbih_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The app frame: three destinations plus a drawer for the secondary screens.
///
/// Two energy decisions live here:
///
/// * the countdown ticker is **paused** on `paused`/`inactive` and resumed on
///   `resumed`, so a backgrounded app holds no running `Timer`;
/// * the destinations live in an `IndexedStack`, so switching tabs neither
///   rebuilds nor refetches the other tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _index = 0;

  /// Five prayers a day, so 25 pending notifications is a week of runway.
  static const int _minimumRunway = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nextPrayerProvider.notifier).setActive(true);
      _topUpAdhanSchedule();
      _armSilenceWindows();
    });
  }

  /// Auto-silent is armed from here, not only from the settings screen: alarms do
  /// not survive a reinstall or a reboot, and a reader who turns the switch on
  /// once should not have to remember to touch it again. Sixty-three days of
  /// windows are two binder calls — no wake-up, no timer, nothing left running.
  Future<void> _armSilenceWindows() async {
    try {
      final AppSettings settings = ref.read(settingsProvider);
      final PrayerRepository repository = ref.read(prayerRepositoryProvider);
      if (!settings.silentModeEnabled && settings.jumuahSilentMinutes == 0) {
        return;
      }
      await repository.scheduleSilence(days: AppConstants.notificationDaysAhead);
    } catch (_) {
      // Silence is an extra: it must never be the reason a launch fails.
    }
  }

  /// Keeps the operating system supplied with a month of adhan.
  ///
  /// The plan is handed over in one shot, but a user who does not open the app
  /// for a month would otherwise run out. So on every launch we merely *count*
  /// what is pending (one binder call, no network, no wake-up) and re-arm only
  /// when the runway drops below a week. That keeps the app self-healing without
  /// making launch cost anything measurable.
  Future<void> _topUpAdhanSchedule() async {
    try {
      final AppSettings settings = ref.read(settingsProvider);

      // Two things must happen on **every** launch, whether or not the month is
      // already armed:
      //
      // * the channels — Android freezes a channel's sound at creation, so a
      //   build that changes the adhan tone or the lock-screen card only takes
      //   effect once the new channel id is actually created;
      // * the all-day lock-screen card — otherwise it stays pointing at a prayer
      //   that has already passed.
      //
      // Both are one binder call each. They used to sit behind the runway check
      // below, which meant a phone that had been scheduled once never created the
      // new channels at all: the fix would have been invisible on exactly the
      // device it was written for.
      final PrayerRepository repository = ref.read(prayerRepositoryProvider);
      await repository.ensureNotificationChannels();
      await repository.refreshLockScreenCard();

      if (!settings.isAdhanEnabled) return;

      final int pending =
          await ref.read(notificationServiceProvider).pendingCount();
      if (pending >= _minimumRunway) return;

      await repository.scheduleNotifications(
        days: AppConstants.notificationDaysAhead,
      );

      // The settings screen may already have read the (then empty) count: refresh
      // it so the number it shows is the number that was just armed.
      if (mounted) ref.invalidate(pendingAdhanCountProvider);
    } catch (_) {
      // A scheduling failure must never break the dashboard; the settings screen
      // surfaces the count and offers a manual re-arm.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool active = state == AppLifecycleState.resumed;
    ref.read(nextPrayerProvider.notifier).setActive(active);
    if (active) {
      // Times may have elapsed while the app slept.
      ref.read(nextPrayerProvider.notifier).refresh();
      // ...and so has the prayer the lock-screen card is counting down to.
      unawaited(
        ref.read(prayerRepositoryProvider).refreshLockScreenCard(),
      );
    }
  }

  void _go(int index) {
    setState(() => _index = index);
    Navigator.of(context).maybePop();
  }

  Future<void> _push(Widget screen) async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext _) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);

    return Scaffold(
      drawer: _AppDrawer(onTab: _go, onPush: _push),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          DashboardScreen(),
          MonthlyTimetableScreen(embedded: true),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        // In elderly mode the labels would wrap to two lines at 150% text, so
        // only the selected destination keeps its label.
        labelBehavior: ui.isElderlyMode
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time_filled),
            label: l10n.prayerTimetable,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.monthlyTimetable,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
      // Elderly mode announces itself and is one tap away from being turned off
      // — a user must never feel trapped in a mode they cannot read.
      floatingActionButton: ui.isElderlyMode
          ? FloatingActionButton.extended(
              onPressed: () =>
                  ref.read(appSettingsProvider.notifier).setElderlyMode(false),
              icon: const Icon(Icons.close),
              label: Text(l10n.turnOffElderly),
            )
          : null,
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.onTab, required this.onPush});

  final void Function(int) onTab;
  final Future<void> Function(Widget) onPush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    final String city = ui.isArabic
        ? (settings.cityAr.isEmpty ? settings.cityEn : settings.cityAr)
        : (settings.cityEn.isEmpty ? settings.cityAr : settings.cityEn);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.appFullName,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(Icons.place_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          city.isEmpty ? l10n.location : city,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(l10n.qibla),
              onTap: () => onPush(const QiblaScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.touch_app_outlined),
              title: Text(l10n.tasbih),
              onTap: () => onPush(const TasbihScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.monthlyTimetable),
              onTap: () => onTab(1),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.remove_red_eye_outlined),
              title: Text(l10n.elderlyMode),
              subtitle: Text(l10n.elderlyModeDesc),
              value: ui.isElderlyMode,
              onChanged: (bool value) =>
                  ref.read(appSettingsProvider.notifier).setElderlyMode(value),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(l10n.theme),
              subtitle: Text(switch (ui.themeMode) {
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
                ThemeMode.system => l10n.themeSystem,
              }),
              onTap: () => ref.read(appSettingsProvider.notifier).toggleTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.translate_outlined),
              title: Text(l10n.language),
              subtitle: Text(ui.isArabic ? l10n.arabic : l10n.english),
              onTap: () => ref.read(appSettingsProvider.notifier).toggleLocale(),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.about),
              onTap: () => onPush(const AboutScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

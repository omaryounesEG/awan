import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_provider.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/prayer_engine/presentation/screens/elderly_dashboard_view.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/hijri_header.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/next_prayer_card.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/prayer_card.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/silent_now_banner.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/quick_actions.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/quran_shortcut_card.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabihat_shortcut_card.dart';
import 'package:awan/features/smart_calendar/presentation/widgets/smart_calendar_shortcut_card.dart';
import 'package:awan/features/shamila_library/presentation/widgets/library_shortcut_card.dart';
import 'package:awan/features/settings/presentation/widgets/quick_settings_actions.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The dashboard — Step 4.
///
/// Two layouts, one source of truth:
///
/// * **standard** — the hero card (next prayer + countdown + progress arc), the
///   day's six rows, and the shortcut grid;
/// * **elderly** — see [ElderlyDashboardView]: decoration removed rather than
///   enlarged, three full-screen-width targets, maximum contrast.
///
/// The switch is a single boolean on [appSettingsProvider], so the layout swaps
/// on the frame after the toggle — no navigation, no rebuild of the engine, no
/// refetch. The day's times come from [prayerControllerProvider] (Step 3); the
/// countdown comes from the foreground-gated ticker behind
/// [nextPrayerProvider], so both layouts stay on battery-friendly updates.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AsyncValue<PrayerTimesEntity> today =
        ref.watch(prayerControllerProvider);

    final Widget body = today.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _DashboardError(message: '$error'),
      data: (PrayerTimesEntity entity) => ui.isElderlyMode
          ? ElderlyDashboardView(entity: entity)
          : _StandardDashboard(entity: entity),
    );

    // The dashboard owns its `Scaffold` and app bar: it is stacked inside the
    // shell's `IndexedStack`, so the bar must travel with the tab.
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: const <Widget>[QuickSettingsActions()],
      ),
      // The banner sits above everything because it reports something the
      // system did while the app was closed — it must not be scrolled past.
      body: Column(
        children: <Widget>[
          const SilentNowBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Task 2 — hero, timeline, shortcuts.
class _StandardDashboard extends ConsumerWidget {
  const _StandardDashboard({required this.entity});

  final PrayerTimesEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    final DateTime now = DateTime.now();

    // Fresh every second while the ticker is active — this is what makes the
    // highlight travel down the list without recomputing any prayer times.
    final NextPrayer? next = ref.watch(nextPrayerProvider).next;
    final PrayerName? currentName = _currentPrayer(entity, now);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.r, 4.r, 16.r, 28.r),
      children: <Widget>[
        HijriHeader(date: entity.date),
        SizedBox(height: 10.h),
        const NextPrayerCard(),
        SizedBox(height: 16.h),
        Row(
          children: <Widget>[
            Text(l10n.todayPrayers, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text(
              gregorianLabel(entity.date, ui.localeCode),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (final PrayerName name in PrayerName.values)
                if (entity.timeOf(name) != null)
                  PrayerCard(
                    name: name,
                    at: entity.timeOf(name)!,
                    localeCode: ui.localeCode,
                    status: _statusFor(
                      name: name,
                      at: entity.timeOf(name)!,
                      next: next,
                      currentName: currentName,
                      now: now,
                    ),
                  ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: <Widget>[
                Icon(Icons.place_outlined,
                    size: 18.sp, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _cityLabel(settings, ui.localeCode),
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 18.h),
        const QuranShortcutCard(),
        const LibraryShortcutCard(),
        const SizedBox(height: 12),
        const MutashabihatShortcutCard(),
        const SizedBox(height: 12),
        const SmartCalendarShortcutCard(),
        SizedBox(height: 18.h),
        const QuickActions(),
      ],
    );
  }

  /// The prayer whose window we are inside: the latest obligatory prayer that
  /// has already started today (null before fajr).
  PrayerName? _currentPrayer(PrayerTimesEntity entity, DateTime now) {
    PrayerName? result;
    for (final PrayerName name in PrayerName.obligatory) {
      final DateTime? at = entity.timeOf(name);
      if (at != null && !at.isAfter(now)) result = name;
    }
    return result;
  }

  PrayerCardStatus _statusFor({
    required PrayerName name,
    required DateTime at,
    required NextPrayer? next,
    required PrayerName? currentName,
    required DateTime now,
  }) {
    if (name == PrayerName.sunrise) return PrayerCardStatus.marker;
    if (next != null && next.name == name) return PrayerCardStatus.next;
    if (name == currentName) return PrayerCardStatus.current;
    return at.isAfter(now) ? PrayerCardStatus.upcoming : PrayerCardStatus.past;
  }

  String _cityLabel(AppSettings settings, String localeCode) => localeCode == 'ar'
      ? (settings.cityAr.isEmpty ? settings.cityEn : settings.cityAr)
      : (settings.cityEn.isEmpty ? settings.cityAr : settings.cityEn);
}

/// Shown when the engine itself cannot produce a day (an out-of-range location,
/// say). It names the cause and offers a retry — never a blank screen.
class _DashboardError extends ConsumerWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 42),
            SizedBox(height: 12.h),
            Text(l10n.error, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: () => ref.invalidate(prayerControllerProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_times_entity.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_home_screen.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/graph_screen.dart';
import 'package:awan/features/shamila_library/presentation/screens/library_home_screen.dart';
import 'package:awan/features/settings/presentation/screens/settings_screen.dart';
import 'package:awan/features/tasbih/presentation/screens/tasbih_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Task 3 — the elderly layout.
///
/// The rule is **remove, don't scale**: an older eye is not helped by a denser
/// screen with bigger type, so the timeline, the month grid, the location line
/// and the shortcut grid all disappear, and what is left is three targets that
/// fill the width of the phone. Everything remaining is high-contrast
/// (`onSurface` on the sand/OLED background, bold weights) and sized in `.sp`,
/// which the shell has already clamped to the elderly text scale, so these
/// numbers are the *base* and the user's own scale stacks on top.
class ElderlyDashboardView extends ConsumerWidget {
  const ElderlyDashboardView({super.key, required this.entity});

  final PrayerTimesEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 28.r),
      children: <Widget>[
        _HugeNextPrayerCard(entity: entity),
        SizedBox(height: 18.h),
        ElderlyActionCard(
          icon: Icons.menu_book_outlined,
          label: l10n.quran,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const QuranHomeScreen(),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        ElderlyActionCard(
          icon: Icons.local_library_outlined,
          label: l10n.libraryTitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const LibraryHomeScreen(),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        ElderlyActionCard(
          icon: Icons.hub_outlined,
          label: l10n.graphTitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const GraphScreen(
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        ElderlyActionCard(
          icon: Icons.touch_app_outlined,
          label: l10n.tasbih,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const TasbihScreen(),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        ElderlyActionCard(
          icon: Icons.settings_outlined,
          label: l10n.settings,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext _) => const SettingsScreen(),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        // The date is useful, but it is not why the screen exists: it goes last,
        // at reading size, after the three targets.
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hijriLabel(
                    entity.date,
                    localeCode: ui.localeCode,
                    offsetDays: ref.watch(settingsProvider).hijriOffsetDays,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 4.h),
                Text(
                  gregorianLabel(entity.date, ui.localeCode),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        // Clearance for the floating "turn off elderly mode" button.
        SizedBox(height: 84.h),
      ],
    );
  }
}

/// Card 1: the next prayer, said in one sentence and nothing else.
class _HugeNextPrayerCard extends ConsumerWidget {
  const _HugeNextPrayerCard({required this.entity});

  final PrayerTimesEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final NextPrayerState state = ref.watch(nextPrayerProvider);
    final NextPrayer? next = state.next;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (state.loading || next == null) {
      return const Card(
        child: SizedBox(height: 210, child: Center(child: CircularProgressIndicator())),
      );
    }

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(22.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.nextPrayer,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              prayerLabel(l10n, next.name),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: <Widget>[
                Icon(Icons.schedule, size: 28.sp, color: scheme.onPrimaryContainer),
                SizedBox(width: 8.w),
                Text(
                  formatClock(next.at, ui.localeCode),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              state.isDue
                  ? l10n.prayerNow
                  : '${l10n.remaining}: ${countdownLabel(state.remaining, ui.localeCode)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width, thumb-height action. 92 logical pixels of height at the base
/// scale, and the whole card is the hit target.
class ElderlyActionCard extends StatelessWidget {
  const ElderlyActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // The affordance must point the way the layout flows: left in Arabic, right
    // in English. `chevron_left`/`chevron_right` do not mirror automatically.
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 96.h,
          child: Row(
            children: <Widget>[
              SizedBox(width: 20.w),
              Icon(icon, size: 38.sp, color: scheme.primary),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
              ),
              Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                size: 30.sp,
                color: scheme.outline,
              ),
              SizedBox(width: 14.w),
            ],
          ),
        ),
      ),
    );
  }
}

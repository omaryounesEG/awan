import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/mosque_radar/presentation/screens/radar_screen.dart';
import 'package:awan/features/recitation/presentation/screens/recitation_screen.dart';
import 'package:awan/features/prayer_engine/presentation/screens/monthly_timetable_screen.dart';
import 'package:awan/features/prayer_engine/presentation/screens/qibla_screen.dart';
import 'package:awan/features/tasbih/presentation/screens/tasbih_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The dashboard's shortcut grid.
///
/// Only destinations that exist are listed — a tile that leads nowhere is worse
/// than one tile fewer. [elderly] swaps the compact grid for full-width rows,
/// because a wide target is hit far more reliably than a small square.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, this.elderly = false});

  final bool elderly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    final List<_Action> actions = <_Action>[
      _Action(
        icon: Icons.calendar_month_outlined,
        label: l10n.monthlyTimetable,
        builder: () => const MonthlyTimetableScreen(),
      ),
      _Action(
        icon: Icons.explore_outlined,
        label: l10n.qibla,
        builder: () => const QiblaScreen(),
      ),
      _Action(
        icon: Icons.touch_app_outlined,
        label: l10n.tasbih,
        builder: () => const TasbihScreen(),
      ),
      _Action(
        icon: Icons.mosque_outlined,
        label: l10n.mosqueRadar,
        builder: () => const RadarScreen(),
      ),
      _Action(
        icon: Icons.graphic_eq_rounded,
        label: l10n.recitationTitle,
        builder: () => const RecitationScreen(),
      ),
    ];

    if (elderly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final _Action action in actions) ...<Widget>[
            SizedBox(
              height: 84.h,
              child: FilledButton.tonalIcon(
                onPressed: () => _push(context, action),
                icon: Icon(action.icon, size: 28.sp),
                label: Text(action.label,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ],
      );
    }

    // Three across left a single orphan tile on its own row once the radar
    // landed, so the grid is balanced on purpose: 2x2 for four actions, 3 for
    // three, one column for the elderly layout's huge targets.
    final int columns = actions.length <= 4 ? 2 : 3;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: columns == 2 ? 1.35 : 1.02,
      children: <Widget>[
        for (final _Action action in actions)
          _ActionTile(action: action, onTap: () => _push(context, action)),
      ],
    );
  }

  void _push(BuildContext context, _Action action) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext _) => action.builder()),
    );
  }
}

class _Action {
  const _Action({required this.icon, required this.label, required this.builder});

  final IconData icon;
  final String label;
  final Widget Function() builder;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final _Action action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(action.icon, size: 26.sp, color: scheme.primary),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

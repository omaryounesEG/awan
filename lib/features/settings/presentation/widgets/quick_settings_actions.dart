import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The three quick toggles an evaluator (or a user) wants at hand: language,
/// theme, and elderly mode.
///
/// They live in one widget because the app bar of the shell and the app bar of
/// the standalone [DashboardScreen] must show *the same* controls — one
/// definition, two placements, no drift.
class QuickSettingsActions extends ConsumerWidget {
  const QuickSettingsActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: l10n.elderlyMode,
          onPressed: () =>
              ref.read(appSettingsProvider.notifier).toggleElderlyMode(),
          icon: Icon(
            ui.isElderlyMode
                ? Icons.accessibility_new
                : Icons.accessibility_new_outlined,
            color: ui.isElderlyMode
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        IconButton(
          tooltip: l10n.language,
          onPressed: () => ref.read(appSettingsProvider.notifier).toggleLocale(),
          icon: const Icon(Icons.translate),
        ),
        IconButton(
          tooltip: l10n.theme,
          onPressed: () => ref.read(appSettingsProvider.notifier).toggleTheme(),
          icon: Icon(
            ui.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );
  }
}

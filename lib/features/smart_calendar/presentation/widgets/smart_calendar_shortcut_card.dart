import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';
import 'package:awan/features/smart_calendar/presentation/providers/smart_calendar_providers.dart';
import 'package:awan/features/smart_calendar/presentation/screens/smart_calendar_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The smart-sync entry point on the home screen.
///
/// It counts the blocks it is about to protect instead of advertising a feature:
/// a number that changes when the window or the working hours change is the
/// honest subtitle for this card.
class SmartCalendarShortcutCard extends ConsumerWidget {
  const SmartCalendarShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<PrayerBlock>> blocks = ref.watch(smartBlocksProvider);
    final AsyncValue<bool> permission = ref.watch(calendarPermissionProvider);
    final ThemeData theme = Theme.of(context);

    final String subtitle = permission.valueOrNull != true
        ? l10n.smartHeroBody
        : l10n.smartBlockCount(blocks.valueOrNull?.length ?? 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SmartCalendarScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.smartTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

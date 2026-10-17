import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/date_x.dart';

/// The "sakinah" header: hijri date, gregorian date and a time-aware greeting.
class HijriHeader extends ConsumerWidget {
  const HijriHeader({super.key, this.date});

  /// Defaults to "now"; the dashboard passes the day it is displaying so the
  /// header can never disagree with the timetable under it.
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final AppLocation location = ref.watch(locationProvider);
    final DateTime now = date ?? DateTime.now();
    final ThemeData theme = Theme.of(context);

    final String greeting = switch (now.hour) {
      >= 4 && < 12 => context.l10n.greetingMorning,
      >= 12 && < 17 => context.l10n.greetingNoon,
      _ => context.l10n.greetingEvening,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(greeting, style: theme.textTheme.titleLarge),
              ),
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                settings.isArabic
                    ? (location.cityAr?.isNotEmpty == true
                        ? location.cityAr!
                        : location.cityEn ?? '')
                    : (location.cityEn?.isNotEmpty == true
                        ? location.cityEn!
                        : location.cityAr ?? ''),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.nights_stay_outlined,
                  size: 15, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                hijriLabel(
                  now,
                  localeCode: settings.localeCode,
                  offsetDays: settings.hijriOffsetDays,
                ),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            gregorianLabel(now, settings.localeCode),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

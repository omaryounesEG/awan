import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// A whole month at a glance.
///
/// The month is computed **off the UI isolate** (`computeMonthInIsolate`) and
/// then cached per day by Isar, so paging through months stays smooth and works
/// with no network at all. [embedded] keeps it usable as a tab (no back button)
/// and as a pushed route.
class MonthlyTimetableScreen extends ConsumerStatefulWidget {
  const MonthlyTimetableScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MonthlyTimetableScreen> createState() =>
      _MonthlyTimetableScreenState();
}

class _MonthlyTimetableScreenState
    extends ConsumerState<MonthlyTimetableScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) => setState(() {
        _month = DateTime(_month.year, _month.month + months);
      });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AsyncValue<List<DayPrayerTimes>> month =
        ref.watch(monthPrayerTimesProvider(_month));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.monthlyTimetable),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.yesterday,
            onPressed: () => _shift(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l10n.tomorrow,
            onPressed: () => _shift(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: <Widget>[
                Text(
                  '${monthName(_month.month, ui.localeCode)} ${_month.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  ref.watch(settingsProvider).cityAr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: month.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error', textAlign: TextAlign.center),
                ),
              ),
              data: (List<DayPrayerTimes> days) => _MonthTable(
                days: days,
                localeCode: ui.localeCode,
                elderly: ui.isElderlyMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthTable extends StatelessWidget {
  const _MonthTable({
    required this.days,
    required this.localeCode,
    required this.elderly,
  });

  final List<DayPrayerTimes> days;
  final String localeCode;
  final bool elderly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime today = DateTime.now();

    final double rowHeight = elderly ? 54 : 40;
    final double firstColumn = elderly ? 132 : 108;

    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: <Widget>[
              Container(
                color: scheme.surfaceContainerHighest.withOpacity(0.6),
                child: Row(
                  children: <Widget>[
                    _cell(context, l10n.gregorianDate,
                        width: firstColumn,
                        height: rowHeight,
                        bold: true,
                        color: scheme.primary),
                    for (final PrayerName name in PrayerName.values)
                      _cell(context, prayerLabel(context.l10n, name),
                          width: elderly ? 96 : 78,
                          height: rowHeight,
                          bold: true,
                          color: scheme.primary),
                  ],
                ),
              ),
              for (final DayPrayerTimes day in days)
                Container(
                  color: _isSameDay(day.date, today)
                      ? scheme.primaryContainer.withOpacity(0.45)
                      : null,
                  child: Row(
                    children: <Widget>[
                      _cell(
                        context,
                        '${weekdayName(day.date, localeCode)} '
                        '${day.date.day}',
                        width: firstColumn,
                        height: rowHeight,
                        bold: _isSameDay(day.date, today),
                      ),
                      for (final PrayerName name in PrayerName.values)
                        _cell(
                          context,
                          formatClock(day.timeOf(name), localeCode),
                          width: elderly ? 96 : 78,
                          height: rowHeight,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _cell(
    BuildContext context,
    String text, {
    required double width,
    required double height,
    bool bold = false,
    Color? color,
  }) =>
      SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
          ),
        ),
      );
}

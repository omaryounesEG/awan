import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/adhkar/data/adhkar_progress_store.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';
import 'package:awan/features/adhkar/presentation/providers/adhkar_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The month, as a calendar of days rather than a table of numbers.
///
/// A day is coloured by the average of its two sittings, so a glance answers
/// "was I consistent?" — and tapping a day says exactly what was done.
class AdhkarReportScreen extends ConsumerStatefulWidget {
  const AdhkarReportScreen({super.key});

  @override
  ConsumerState<AdhkarReportScreen> createState() => _AdhkarReportScreenState();
}

class _AdhkarReportScreenState extends ConsumerState<AdhkarReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AdhkarMonthSummary> summary =
        ref.watch(adhkarMonthProvider(_month));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adhkarReport)),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(child: Text('$error')),
        data: (AdhkarMonthSummary data) => ListView(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month - 1)),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_month, l10n),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            _SummaryRow(summary: data, l10n: l10n),
            SizedBox(height: 14.h),
            _Calendar(
              month: _month,
              summary: data,
              items: ref.watch(adhkarChapterProvider).valueOrNull?.items ??
                  const <AdhkarItem>[],
              l10n: l10n,
              onDay: (DateTime day) => _showDay(day),
            ),
            SizedBox(height: 10.h),
            _Legend(l10n: l10n),
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime month, AppLocalizations l10n) {
    const List<String> ar = <String>[
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو',
      'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    const List<String> en = <String>[
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final String name = (isAr ? ar : en)[month.month - 1];
    return '$name ${month.year}';
  }

  Future<void> _showDay(DateTime day) async {
    final AdhkarMonthSummary? summary =
        ref.read(adhkarMonthProvider(_month)).valueOrNull;
    final AdhkarDayCounts? counts = summary?.days[day];
    final AppLocalizations l10n = context.l10n;
    final AdhkarChapter? chapter = ref.read(adhkarChapterProvider).valueOrNull;
    if (chapter == null) return;
    final AdhkarSessionProgress morning =
        AdhkarSessionProgress.of(chapter.items, counts?.morning ?? const <int, int>{});
    final AdhkarSessionProgress evening =
        AdhkarSessionProgress.of(chapter.items, counts?.evening ?? const <int, int>{});
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: Text('${day.day} ${_monthLabel(day, l10n)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${l10n.adhkarMorning}: ${morning.doneItems}/${morning.totalItems}'
                ' — ${(morning.ratio * 100).round()}%'),
            SizedBox(height: 6.h),
            Text('${l10n.adhkarEvening}: ${evening.doneItems}/${evening.totalItems}'
                ' — ${(evening.ratio * 100).round()}%'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary, required this.l10n});

  final AdhkarMonthSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<({String label, String value})> cards = <({String label, String value})>[
      (label: l10n.adhkarMorningDays, value: '${summary.morningDays}'),
      (label: l10n.adhkarEveningDays, value: '${summary.eveningDays}'),
      (label: l10n.adhkarBothDays, value: '${summary.bothDays}'),
      (
        label: l10n.adhkarAverage,
        value: '${(((summary.morningAverage + summary.eveningAverage) / 2) * 100).round()}%'
      ),
    ];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: <Widget>[
        for (final ({String label, String value}) c in cards)
          Container(
            width: (MediaQuery.of(context).size.width - 44.w) / 2,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(c.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(c.label,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.summary,
    required this.items,
    required this.l10n,
    required this.onDay,
  });

  final DateTime month;
  final AdhkarMonthSummary summary;
  final List<AdhkarItem> items;
  final AppLocalizations l10n;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final DateTime today = DateTime.now();
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String d in <String>[
              l10n.weekdaySun,
              l10n.weekdayMon,
              l10n.weekdayTue,
              l10n.weekdayWed,
              l10n.weekdayThu,
              l10n.weekdayFri,
              l10n.weekdaySat,
            ])
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: firstWeekday + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (BuildContext context, int i) {
            if (i < firstWeekday) return const SizedBox.shrink();
            final int day = i - firstWeekday + 1;
            final DateTime date = DateTime(month.year, month.month, day);
            final AdhkarDayCounts? counts = summary.days[date];
            final double ratio = counts == null
                ? 0
                : (AdhkarSessionProgress.of(items, counts.morning).ratio +
                        AdhkarSessionProgress.of(items, counts.evening).ratio) /
                    2;
            final bool isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final Color color = counts == null
                ? theme.colorScheme.surfaceContainerHighest
                : Color.lerp(
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.primary,
                    0.15 + 0.85 * ratio,
                  )!;
            return GestureDetector(
              onTap: () => onDay(date),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6.r),
                  border: isToday
                      ? Border.all(color: theme.colorScheme.secondary, width: 1.4)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ratio > 0.6
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget item(double ratio, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: ratio == 0
                    ? theme.colorScheme.surfaceContainerHighest
                    : Color.lerp(
                        theme.colorScheme.surfaceContainerHighest,
                        theme.colorScheme.primary,
                        0.15 + 0.85 * ratio,
                      ),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(width: 4.w),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        );
    return Wrap(
      spacing: 12.w,
      runSpacing: 6.h,
      children: <Widget>[
        item(0.0, l10n.adhkarLegendNone),
        item(0.5, l10n.adhkarLegendHalf),
        item(1.0, l10n.adhkarLegendFull),
      ],
    );
  }
}

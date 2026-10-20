import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/adhkar/data/adhkar_progress_store.dart';
import 'package:awan/features/adhkar/data/adhkar_reminders.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';
import 'package:awan/features/adhkar/presentation/providers/adhkar_providers.dart';
import 'package:awan/features/adhkar/presentation/screens/adhkar_player_screen.dart';
import 'package:awan/features/adhkar/presentation/screens/adhkar_report_screen.dart';
import 'package:awan/features/adhkar/presentation/widgets/adhkar_download_sheet.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «الأذكار» — a task, not a wall of text.
///
/// Two sittings, twenty-four adhkar each; every card counts up to the number the
/// page itself asks for, then closes. The header says how much of the sitting is
/// done, and the report says how the month went. That is the whole feature.
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key, this.session});

  final AdhkarSession? session;

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.session == AdhkarSession.evening ? 1 : 0,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AdhkarChapter> chapter = ref.watch(adhkarChapterProvider);
    final AsyncValue<Map<AdhkarSession, AdhkarSessionProgress>> progress =
        ref.watch(adhkarTodayProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adhkarTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.adhkarReport,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdhkarReportScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.adhkarAudioTitle,
            icon: const Icon(Icons.download_outlined),
            onPressed: () => AdhkarDownloadSheet.show(context),
          ),
          IconButton(
            tooltip: l10n.adhkarReminders,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => _openReminders(chapter.valueOrNull),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.adhkarMorning),
            Tab(text: l10n.adhkarEvening),
          ],
        ),
      ),
      body: chapter.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (AdhkarChapter data) => TabBarView(
          controller: _tabs,
          children: <Widget>[
            _SessionList(
              session: AdhkarSession.morning,
              chapter: data,
              progress: progress.valueOrNull?[AdhkarSession.morning],
            ),
            _SessionList(
              session: AdhkarSession.evening,
              chapter: data,
              progress: progress.valueOrNull?[AdhkarSession.evening],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReminders(AdhkarChapter? chapter) async {
    final AppLocalizations l10n = context.l10n;
    final AdhkarReminderSettings current =
        await ref.read(adhkarReminderSettingsProvider.future);
    if (!mounted) return;

    bool enabled = current.enabled;
    TimeOfDay morning = _toTime(current.morningMinutes);
    TimeOfDay evening = _toTime(current.eveningMinutes);

    final bool? save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.adhkarReminders,
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 6.h),
              Text(l10n.adhkarRemindersBody,
                  style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 8.h),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.adhkarRemindersEnable),
                value: enabled,
                onChanged: (bool value) => setSheet(() => enabled = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: enabled,
                leading: const Icon(Icons.wb_twilight),
                title: Text(l10n.adhkarMorning),
                trailing: Text(_label(morning)),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: morning,
                  );
                  if (picked != null) setSheet(() => morning = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: enabled,
                leading: const Icon(Icons.nights_stay_outlined),
                title: Text(l10n.adhkarEvening),
                trailing: Text(_label(evening)),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: evening,
                  );
                  if (picked != null) setSheet(() => evening = picked);
                },
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheet).pop(true),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (save != true) return;
    await ref.read(adhkarRemindersProvider).save(
          enabled: enabled,
          morning: morning.hour * 60 + morning.minute,
          evening: evening.hour * 60 + evening.minute,
          morningTitle: l10n.adhkarMorningReminderTitle,
          morningBody: l10n.adhkarMorningReminderBody,
          eveningTitle: l10n.adhkarEveningReminderTitle,
          eveningBody: l10n.adhkarEveningReminderBody,
        );
    ref.invalidate(adhkarReminderSettingsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(enabled ? l10n.adhkarReminderSaved : l10n.adhkarReminderOff)),
    );
  }

  static TimeOfDay _toTime(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  static String _label(TimeOfDay time) {
    final String suffix = time.hour < 12 ? 'ص' : 'م';
    final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
  }
}

class _SessionList extends ConsumerWidget {
  const _SessionList({
    required this.session,
    required this.chapter,
    required this.progress,
  });

  final AdhkarSession session;
  final AdhkarChapter chapter;
  final AdhkarSessionProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AdhkarSessionProgress state =
        progress ?? AdhkarSessionProgress.of(chapter.items, const <int, int>{});

    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 28.h),
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      state.finished
                          ? (session == AdhkarSession.morning
                              ? l10n.adhkarMorningDone
                              : l10n.adhkarEveningDone)
                          : l10n.adhkarProgressOf(
                              state.doneItems, state.totalItems),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${(state.ratio * 100).round()}%',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: state.ratio,
                  minHeight: 8.h,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.headphones, size: 18),
                      label: Text(l10n.adhkarListen),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdhkarPlayerScreen(
                            session: session,
                            startIndex: _firstUnfinished(state),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    tooltip: l10n.adhkarReset,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: () => ref
                        .read(adhkarActionsProvider)
                        .resetSession(session),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        for (final AdhkarItem item in chapter.items)
          _DhikrCard(
            item: item,
            session: session,
            count: state.counts[item.id] ?? 0,
          ),
      ],
    );
  }

  int _firstUnfinished(AdhkarSessionProgress state) {
    for (int i = 0; i < chapter.items.length; i++) {
      final AdhkarItem item = chapter.items[i];
      if ((state.counts[item.id] ?? 0) < item.repeat) return i;
    }
    return 0;
  }
}

class _DhikrCard extends ConsumerStatefulWidget {
  const _DhikrCard({
    required this.item,
    required this.session,
    required this.count,
  });

  final AdhkarItem item;
  final AdhkarSession session;
  final int count;

  @override
  ConsumerState<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends ConsumerState<_DhikrCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool done = widget.count >= widget.item.repeat;
    final String text = widget.item.textFor(Localizations.localeOf(context).languageCode);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: done
            ? theme.colorScheme.primaryContainer.withOpacity(0.55)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: done ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, done ? 10.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    maxLines: _open ? null : 4,
                    overflow: _open ? TextOverflow.visible : TextOverflow.fade,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                  ),
                  if (!_open)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        l10n.adhkarTapToExpand,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 6.h),
            child: Row(
              children: <Widget>[
                if (widget.item.repeat > 1)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.w),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('×${widget.item.repeat}'),
                    ),
                  ),
                IconButton(
                  tooltip: l10n.adhkarPlay,
                  icon: const Icon(Icons.play_circle_outline, size: 22),
                  onPressed: () => _play(),
                ),
                const Spacer(),
                if (done)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(l10n.adhkarDone),
                    onPressed: () => ref
                        .read(adhkarActionsProvider)
                        .resetItem(widget.session, widget.item),
                  )
                else
                  FilledButton(
                    onPressed: () => ref
                        .read(adhkarActionsProvider)
                        .increment(widget.session, widget.item),
                    child: Text(
                      widget.item.repeat > 1
                          ? '${widget.count}/${widget.item.repeat}'
                          : l10n.adhkarCount,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _play() async {
    final String? local =
        await ref.read(adhkarRepositoryProvider).localAudio(widget.item.id);
    await ref.read(adhkarAudioServiceProvider).play(
          local ?? widget.item.audioUrl,
          title: widget.item.textFor(
            Localizations.localeOf(context).languageCode,
          ).substring(0, 20),
        );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/audio_manager_service.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/smart_calendar/data/repositories/smart_calendar_repository_impl.dart';
import 'package:awan/features/smart_calendar/domain/entities/smart_calendar_entities.dart';
import 'package:awan/features/smart_calendar/presentation/providers/smart_calendar_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Two architectures, one screen: the calendar half writes the rolling prayer
/// blocks, the silence half decides what the phone does at the adhan.
///
/// The screen is deliberately a *reader*, not a wizard: every card states what
/// the app will do and offers the one action that changes it.
class SmartCalendarScreen extends ConsumerStatefulWidget {
  const SmartCalendarScreen({super.key});

  @override
  ConsumerState<SmartCalendarScreen> createState() =>
      _SmartCalendarScreenState();
}

class _SmartCalendarScreenState extends ConsumerState<SmartCalendarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smartTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.smartCalendarTab, icon: const Icon(Icons.event_busy_outlined)),
            Tab(text: l10n.smartSilentTab, icon: const Icon(Icons.volume_off_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const <Widget>[
          _CalendarTab(),
          _SilentTab(),
        ],
      ),
    );
  }
}

Future<void> _mutate(WidgetRef ref, AppSettings Function(AppSettings) change) =>
    ref.read(settingsControllerProvider.notifier).mutate(change);

// ------------------------------------------------------------------ calendar

class _CalendarTab extends ConsumerWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<bool> permission = ref.watch(calendarPermissionProvider);
    final AsyncValue<List<PrayerBlock>> blocks = ref.watch(smartBlocksProvider);
    final AsyncValue<List<Conflict>> conflicts = ref.watch(smartConflictsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(calendarPermissionProvider);
        ref.invalidate(calendarEventsProvider);
        ref.invalidate(smartBlocksProvider);
        await ref.read(smartBlocksProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const _HeroCard(),
          const SizedBox(height: 12),
          permission.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (Object error, StackTrace _) => _Notice(
              icon: Icons.error_outline,
              text: '$error',
            ),
            data: (bool granted) => granted
                ? _WriteCard(blocks: blocks.valueOrNull ?? const <PrayerBlock>[])
                : const _PermissionCard(),
          ),
          if (permission.valueOrNull == true) ...<Widget>[
            const SizedBox(height: 12),
            const _ConfigCard(),
            const SizedBox(height: 12),
            conflicts.when(
              loading: () => const SizedBox.shrink(),
              error: (Object error, StackTrace _) => _Notice(
                icon: Icons.error_outline,
                text: '$error',
              ),
              data: (List<Conflict> items) => items.isEmpty
                  ? const _NoConflictsCard()
                  : _ConflictsCard(conflicts: items),
            ),
            SectionTitle(label: l10n.smartBlocksPreview),
            if (blocks.valueOrNull != null)
              for (final PrayerBlock block
                  in blocks.valueOrNull!.take(6))
                _BlockTile(block: block),
          ],
        ],
      ),
    );
  }
}

/// The one-liner that explains the whole idea, in the app's own voice.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool night = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: night
              ? <Color>[const Color(0xFF14312B), const Color(0xFF0B1F1C)]
              : <Color>[const Color(0xFFE8F3EF), const Color(0xFFF6FAF8)],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(night ? 0.35 : 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
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
              children: <Widget>[
                Text(l10n.smartHeroTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.smartHeroBody,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteCard extends ConsumerStatefulWidget {
  const _WriteCard({required this.blocks});

  final List<PrayerBlock> blocks;

  @override
  ConsumerState<_WriteCard> createState() => _WriteCardState();
}

class _WriteCardState extends ConsumerState<_WriteCard> {
  bool _busy = false;

  Future<void> _write() async {
    if (_busy) return;
    setState(() => _busy = true);
    final AppLocalizations l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppSettings settings = ref.read(settingsProvider);
    try {
      final SmartCalendarRepositoryImpl repository =
          ref.read(smartCalendarRepositoryProvider);
      final SyncOutcome outcome = await repository.writeBlocks(
        widget.blocks,
        title: (PrayerBlock block) =>
            '${l10n.adhan} · ${prayerLabel(l10n, block.prayer)}',
      );
      ref.read(lastSyncProvider.notifier).state = outcome;
      if (!mounted) return;
      if (!outcome.ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              outcome.reason == 'no-calendar'
                  ? l10n.smartNoCalendar
                  : l10n.smartNeedPermission,
            ),
          ),
        );
        return;
      }
      ref.invalidate(calendarEventsProvider);
      ref.invalidate(smartConflictsProvider);

      // The calendar is now the source of truth, so the meetings that sit on a
      // prayer can be silenced *before* they happen — no background timer, the
      // OS alarm the app already owns does the work.
      int silenced = 0;
      if (settings.smartDndEnabled) {
        silenced = await _silenceConflicts();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            silenced == 0
                ? l10n.smartWrote(
                    outcome.created, outcome.updated, outcome.unchanged)
                : '${l10n.smartWrote(outcome.created, outcome.updated, outcome.unchanged)} · ${l10n.smartSilencedCount(silenced)}',
          ),
        ),
      );
      // Writing the window is the intent: keep the switch in step with it.
      if (!settings.smartCalendarEnabled) {
        await _mutate(ref, (AppSettings s) => s.copyWith(
              smartCalendarEnabled: true,
            ));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Arms the phone's silent windows for every meeting that swallows a prayer.
  /// Windows are clipped to the future: a meeting already underway is silenced
  /// only from now on.
  Future<int> _silenceConflicts() async {
    // Re-read after the invalidation above: the write may have moved a block,
    // and `valueOrNull` would still hold the list from before it.
    final List<Conflict> conflicts = await ref.read(smartConflictsProvider.future);
    if (conflicts.isEmpty) return 0;
    final DateTime now = DateTime.now();
    final List<SilenceWindow> windows = <SilenceWindow>[
      for (final Conflict conflict in conflicts)
        SilenceWindow(
          start: conflict.event.start.isAfter(now) ? conflict.event.start : now,
          end: conflict.event.end,
        ),
    ].where((SilenceWindow w) => w.end.isAfter(w.start)).toList();
    if (windows.isEmpty) return 0;
    await ref.read(audioManagerServiceProvider).scheduleWindows(windows);
    return windows.length;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final SyncOutcome? last = ref.watch(lastSyncProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.event_available_outlined,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.smartBlockCount(widget.blocks.length),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (last != null && last.ok) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                l10n.smartWrote(last.created, last.updated, last.unchanged),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _write,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_done_outlined, size: 18),
              label: Text(_busy ? l10n.smartWriting : l10n.smartWrite),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends ConsumerStatefulWidget {
  const _PermissionCard();

  @override
  ConsumerState<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends ConsumerState<_PermissionCard> {
  Future<void> _grant() async {
    await ref.read(smartCalendarRepositoryProvider).requestPermission();
    ref.invalidate(calendarPermissionProvider);
    ref.invalidate(calendarEventsProvider);
    ref.invalidate(smartBlocksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.smartNeedPermission,
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _grant,
              child: Text(l10n.smartGrant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizon, block length and working hours — three choices, no more.
class _ConfigCard extends ConsumerWidget {
  const _ConfigCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSettings settings = ref.watch(settingsProvider);
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Row(
              label: l10n.smartWindow,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 14, label: Text(l10n.smartWindowDays(14))),
                  ButtonSegment<int>(value: 30, label: Text(l10n.smartWindowDays(30))),
                ],
                selected: <int>{settings.smartBlockDays >= 30 ? 30 : 14},
                onSelectionChanged: (Set<int> value) => _mutate(
                  ref,
                  (AppSettings s) => s.copyWith(smartBlockDays: value.first),
                ),
              ),
            ),
            const Divider(height: 18),
            _Row(
              label: l10n.smartDuration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: settings.smartBlockMinutes <= 5
                        ? null
                        : () => _mutate(
                              ref,
                              (AppSettings s) => s.copyWith(
                                smartBlockMinutes: s.smartBlockMinutes - 5,
                              ),
                            ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(l10n.smartDurationMinutes(settings.smartBlockMinutes),
                      style: theme.textTheme.bodyMedium),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: settings.smartBlockMinutes >= 60
                        ? null
                        : () => _mutate(
                              ref,
                              (AppSettings s) => s.copyWith(
                                smartBlockMinutes: s.smartBlockMinutes + 5,
                              ),
                            ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const Divider(height: 18),
            _Row(
              label: l10n.smartWorkHours,
              child: Wrap(
                spacing: 8,
                children: <Widget>[
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text(
                      '${l10n.smartFrom} ${settings.smartWorkStart}',
                    ),
                    onPressed: () => _pickTime(
                      context,
                      ref,
                      initial: settings.smartWorkStart,
                      save: (String value) => _mutate(
                        ref,
                        (AppSettings s) => s.copyWith(smartWorkStart: value),
                      ),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text('${l10n.smartTo} ${settings.smartWorkEnd}'),
                    onPressed: () => _pickTime(
                      context,
                      ref,
                      initial: settings.smartWorkEnd,
                      save: (String value) => _mutate(
                        ref,
                        (AppSettings s) => s.copyWith(smartWorkEnd: value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required String initial,
    required ValueChanged<String> save,
  }) async {
    final ClockTime start = ClockTime.parse(initial);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour, minute: start.minute),
    );
    if (picked == null) return;
    final String value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    save(value);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        child,
      ],
    );
  }
}

class _NoConflictsCard extends StatelessWidget {
  const _NoConflictsCard();

  @override
  Widget build(BuildContext context) {
    return _Notice(
      icon: Icons.check_circle_outline,
      text: context.l10n.smartNoConflicts,
      tint: Theme.of(context).colorScheme.primary,
    );
  }
}

class _ConflictsCard extends ConsumerWidget {
  const _ConflictsCard({required this.conflicts});

  final List<Conflict> conflicts;

  Future<void> _postpone(
    BuildContext context,
    WidgetRef ref,
    Conflict conflict,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final SmartCalendarRepositoryImpl repository =
        ref.read(smartCalendarRepositoryProvider);
    final bool moved = await repository.moveEvent(
      conflict.event.id,
      conflict.suggestedStart,
      conflict.suggestedStart.add(conflict.event.duration),
    );
    if (!moved) return;
    ref.invalidate(calendarEventsProvider);
    ref.invalidate(smartConflictsProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.smartPostponed)));
  }

  Future<void> _silence(
    BuildContext context,
    WidgetRef ref,
    Conflict conflict,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DateTime now = DateTime.now();
    await ref.read(audioManagerServiceProvider).scheduleWindows(
      <SilenceWindow>[
        SilenceWindow(
          start: now.isAfter(conflict.event.start) ? now : conflict.event.start,
          end: conflict.event.end,
        ),
      ],
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.smartSilenced)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String locale = ref.watch(settingsProvider).localeCode;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.tertiaryContainer.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.tertiary, size: 20),
                const SizedBox(width: 6),
                Text(l10n.smartConflicts, style: theme.textTheme.titleSmall),
              ],
            ),
            for (final Conflict conflict in conflicts)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${conflict.event.title} · '
                      '${formatClock(conflict.event.start, locale)} — '
                      '${formatClock(conflict.event.end, locale)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${prayerLabel(l10n, conflict.block.prayer)} '
                      '${formatClock(conflict.block.start, locale)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        TextButton.icon(
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text(
                            l10n.smartPostponeTo(
                              formatClock(conflict.suggestedStart, locale),
                            ),
                          ),
                          onPressed: () => _postpone(context, ref, conflict),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.volume_off_outlined, size: 16),
                          label: Text(l10n.smartSilentDuring),
                          onPressed: () => _silence(context, ref, conflict),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlockTile extends ConsumerWidget {
  const _BlockTile({required this.block});

  final PrayerBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final String locale = ref.watch(settingsProvider).localeCode;
    final DateTime start = block.start;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          formatClock(start, locale).split(' ').first,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      title: Text(prayerLabel(l10n, block.prayer)),
      subtitle: Text(
        '${start.day}/${start.month} · '
        '${l10n.smartDurationMinutes(block.length.inMinutes)}',
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.tint});

  final IconData icon;
  final String text;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: tint ?? theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

// -------------------------------------------------------------------- silent

class _SilentTab extends ConsumerWidget {
  const _SilentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSettings settings = ref.watch(settingsProvider);
    final ContextDecision decision = ref.watch(contextDecisionProvider);
    final AsyncValue<List<Mosque>> mosques = ref.watch(nearbyMosquesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _DecisionCard(decision: decision),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            secondary: const Icon(Icons.volume_off_outlined),
            title: Text(l10n.smartDndOn),
            subtitle: Text(l10n.smartDndDesc),
            value: settings.smartDndEnabled,
            onChanged: (bool value) => _mutate(
              ref,
              (AppSettings s) => s.copyWith(smartDndEnabled: value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _MatrixCard(),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(l10n.smartRadius,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 40,
                      label: Text(l10n.smartRadiusMeters(40)),
                    ),
                    ButtonSegment<int>(
                      value: 60,
                      label: Text(l10n.smartRadiusMeters(60)),
                    ),
                    ButtonSegment<int>(
                      value: 100,
                      label: Text(l10n.smartRadiusMeters(100)),
                    ),
                  ],
                  selected: <int>{
                    <int>{40, 60, 100}.contains(settings.smartSilentRadius)
                        ? settings.smartSilentRadius
                        : 60,
                  },
                  onSelectionChanged: (Set<int> value) => _mutate(
                    ref,
                    (AppSettings s) =>
                        s.copyWith(smartSilentRadius: value.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.smartMosques,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.smartRefresh,
                onPressed: () => ref.invalidate(nearbyMosquesProvider),
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
        ),
        mosques.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace _) => _Notice(
            icon: Icons.wifi_off_outlined,
            text: l10n.smartMosqueError,
          ),
          data: (List<Mosque> items) => items.isEmpty
              ? _Notice(icon: Icons.mosque_outlined, text: l10n.smartNoMosques)
              : Column(
                  children: <Widget>[
                    for (final Mosque mosque in items.take(8))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mosque_outlined, size: 20),
                        title: Text(mosque.name),
                        subtitle: Text(
                          mosque.distanceMeters == null
                              ? '—'
                              : l10n.smartRadiusMeters(mosque.distanceMeters!),
                        ),
                        trailing: (mosque.distanceMeters ?? 1 << 30) <=
                                settings.smartSilentRadius
                            ? Icon(
                                Icons.my_location,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.decision});

  final ContextDecision decision;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ContextDecision value = decision;

    final (IconData icon, Color tone, String text) = switch (value) {
      ContextDecision(action: SmartContextAction.hapticSilent) => (
          Icons.mosque_outlined,
          theme.colorScheme.primary,
          value.reason == ContextReason.inMosque
              ? l10n.smartInMosque(value.mosque?.name ?? '')
              : l10n.smartAtGate(value.mosque?.name ?? ''),
        ),
      ContextDecision(action: SmartContextAction.smartSilent) => (
          Icons.event_busy_outlined,
          theme.colorScheme.tertiary,
          l10n.smartInMeeting(value.meeting?.title ?? ''),
        ),
      _ => (Icons.volume_up_outlined, theme.colorScheme.primary, l10n.smartNormal),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.withOpacity(0.30)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tone.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.smartDecisionNow,
                    style: theme.textTheme.labelMedium?.copyWith(color: tone)),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixCard extends StatelessWidget {
  const _MatrixCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final List<(IconData, String, String)> rows = <(IconData, String, String)>[
      (Icons.mosque_outlined, l10n.smartMatrixMosque, l10n.smartMatrixMosqueAction),
      (Icons.event_busy_outlined, l10n.smartMatrixMeeting, l10n.smartMatrixMeetingAction),
      (Icons.volume_up_outlined, l10n.smartMatrixNormal, l10n.smartMatrixNormalAction),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.smartMatrixTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final (IconData icon, String label, String action) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: <Widget>[
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(action, style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

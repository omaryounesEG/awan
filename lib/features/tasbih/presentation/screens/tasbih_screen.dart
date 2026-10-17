import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The tasbih counter.
///
/// Kept deliberately dumb: the state lives in the settings blob, so a count
/// survives an app kill and no database write is needed per tap. Only the
/// *committed* count is persisted (every 10 taps and on pause), which keeps the
/// flash storage quiet and the tap itself instantaneous.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  int _count = 0;
  int _rounds = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final AppSettings s = ref.read(settingsProvider);
    _count = s.tasbihCount;
    _rounds = s.tasbihRounds;
    _loaded = true;
  }

  Future<void> _tap(int target) async {
    HapticFeedback.selectionClick();
    setState(() {
      _count++;
      if (_count >= target) {
        _rounds++;
        _count = 0;
        HapticFeedback.mediumImpact();
      }
    });
    if (_count % 10 == 0 || _count == 0) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setTasbih(target: target, count: _count, rounds: _rounds);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _count = 0;
      _rounds = 0;
    });
    await ref
        .read(settingsControllerProvider.notifier)
        .setTasbih(count: 0, rounds: 0);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    final int target = settings.tasbihTarget;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasbih),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.tasbihReset,
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(target),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '$_count',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: ui.isElderlyMode ? 118 : 92,
                            color: scheme.primary,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures()
                            ],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.tasbihTarget}: $target',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        value: target == 0 ? 0 : _count / target,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _Pill(
                    label: l10n.tasbihCount,
                    value: '${_rounds * target + _count}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Pill(label: l10n.done, value: '$_rounds'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Wrap(
              spacing: 10,
              children: <Widget>[
                for (final int value in <int>[33, 99, 100])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: target == value,
                    onSelected: (bool selected) {
                      if (!selected) return;
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setTasbih(target: value);
                      _reset();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

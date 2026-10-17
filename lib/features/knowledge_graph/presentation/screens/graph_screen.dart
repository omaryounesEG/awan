import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/kisai_layer_screen.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/ayah_search_sheet.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_graph.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_node_views.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_sheet.dart';
import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The interactive Mutashabihat graph for one ayah.
///
/// The ayah comes from one of three places, in this order:
///
/// 1. what the reader tapped ([absoluteAyahId] / the picker),
/// 2. the verse the reader last stopped at — so opening this from the home card
///    continues the reading instead of always landing on the same fixed verse,
/// 3. nothing, in which case the screen asks for an ayah rather than pretending
///    the corpus is empty.
///
/// The diagram is shown at a *level* — a handful of the strongest matches, or
/// all of them — because thirty labels cannot share one phone screen.
class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key, this.absoluteAyahId});

  /// The ayah to open on, in the app-wide Mushaf numbering (1..6236).
  final int? absoluteAyahId;

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

/// Sentinel for "no level chosen yet": the screen then picks one that fits.
const int _kLevelDefault = -1;
const int _kLevelAll = 0;

class _GraphScreenState extends ConsumerState<GraphScreen> {
  /// Which target's sheet is open, so its node can show that it is the one
  /// being read.
  int? _openTarget;

  /// An ayah chosen from the picker, overriding whatever opened the screen.
  int? _pickedAyah;

  /// How many similar ayat to draw. `_kLevelDefault` picks by fan-out.
  int _level = _kLevelDefault;

  @override
  void initState() {
    super.initState();
    _pickedAyah = widget.absoluteAyahId;
  }

  /// Node labels: the surah's name when the Mushaf index is loaded (it always
  /// is by the time a reader gets here), the number otherwise.
  String _labelFor(QuranText? text, bool arabicUi, int surah, int ayah) {
    final AppLocalizations l10n = context.l10n;
    final String ayahDigits = arabicUi ? arabicDigits(ayah) : '$ayah';
    final String? name = text?.surah(surah).nameAr;
    if (name == null || name.isEmpty) {
      return l10n.graphNodeLabel(
        arabicUi ? arabicDigits(surah) : '$surah',
        ayahDigits,
      );
    }
    return l10n.graphNodeNamedLabel(name, ayahDigits);
  }

  /// Search first, dropdowns second: a reader who knows the verse types it, and
  /// the sheet still offers the old picker for everyone else.
  Future<void> _openSearch() async {
    final AyahSearchOutcome? outcome = await showAyahSearch(context);
    if (outcome == null || !mounted) {
      return;
    }
    if (outcome.bySurah) {
      await _pickAyah();
      return;
    }
    setState(() {
      _pickedAyah = outcome.absoluteId;
      _level = _kLevelDefault;
      _openTarget = null;
    });
  }

  void _openKisaiLayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const KisaiLayerScreen(),
      ),
    );
  }

  Future<void> _pickAyah() async {
    final MushafNumbering numbering = ref.read(mushafNumberingProvider);
    final QuranText? text = ref.read(quranTextProvider).valueOrNull;
    final int? chosen = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _AyahPickerDialog(numbering: numbering, text: text),
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _pickedAyah = chosen;
      _level = _kLevelDefault;
      _openTarget = null;
    });
  }

  int _levelFor(MutashabihNodeEntry node) {
    if (_level != _kLevelDefault) {
      return _level;
    }
    // Ten spokes carry a readable label on a phone; a node with fewer than that
    // has nothing to hide.
    return node.targetCount > 10 ? 10 : _kLevelAll;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranText? text = ref.watch(quranTextProvider).valueOrNull;
    final int? lastRead = ref.watch(quranLastReadAbsoluteIdProvider);

    final int? ayahId = _pickedAyah ?? lastRead;
    final AsyncValue<MutashabihNodeEntry?> nodeAsync = ayahId == null
        ? const AsyncValue<MutashabihNodeEntry?>.data(null)
        : ref.watch(similaritiesProvider(ayahId));

    final MutashabihNodeEntry? node = nodeAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          node == null
              ? l10n.graphTitle
              : _labelFor(
                  text,
                  arabicUi,
                  node.sourceSurahNumber,
                  node.sourceAyahNumber,
                ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.kisaiLayerTitle,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: _openKisaiLayer,
          ),
          IconButton(
            tooltip: l10n.ayahSearchTitle,
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: nodeAsync.when(
        loading: () => _Preparing(label: l10n.graphPreparing),
        error: (Object error, StackTrace _) => _GraphError(
          message: l10n.graphSeedFailed,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(mutashabihatSeedProvider),
        ),
        data: (MutashabihNodeEntry? value) {
          if (value == null || value.targetCount == 0) {
            return _EmptyNode(
              label: l10n.graphEmptyNode,
              hint: l10n.graphPickAyah,
              actionLabel: l10n.graphPickAyah,
              onAction: _openSearch,
            );
          }

          final int level = _levelFor(value);
          final List<MutashabihTargetEntry> shownTargets =
              value.orderedTargets(limit: level == _kLevelAll ? null : level);
          final MutashabihNodeEntry shown = value.withTargets(shownTargets);

          return Column(
            children: <Widget>[
              _GraphHeader(
                shown: shown.targetCount,
                total: value.targetCount,
                countLabel: l10n.graphTargetCount(shown.targetCount),
                shownLabel: l10n.graphShownOf(
                  '${arabicUi ? arabicDigits(shown.targetCount) : shown.targetCount}',
                  '${arabicUi ? arabicDigits(value.targetCount) : value.targetCount}',
                ),
                hint: l10n.graphTapHint,
                levelHint: l10n.graphLevelHint,
                sourceTag: l10n.graphSourceTag,
                targetTag: l10n.graphTargetTag,
                level: level,
                onLevel: (int chosen) => setState(() {
                  _level = chosen;
                  _openTarget = null;
                }),
                allLabel: l10n.graphLevelAll,
                arabicUi: arabicUi,
              ),
              Expanded(
                child: MutashabihGraph(
                  node: shown,
                  highlightedTargetIndex: _openTarget,
                  labelFor: (int surah, int ayah) =>
                      _labelFor(text, arabicUi, surah, ayah),
                  onTargetTap: (int index) {
                    setState(() => _openTarget = index);
                    showMutashabihSheet(
                      context: context,
                      target: shownTargets[index],
                      appearance: appearance,
                      labelFor: (int surah, int ayah) =>
                          _labelFor(text, arabicUi, surah, ayah),
                    ).whenComplete(() {
                      if (mounted) {
                        setState(() => _openTarget = null);
                      }
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Surah + ayah, as two dropdowns — the whole picker, because the reader who
/// wants verse 55:13 does not want to hunt for a graph entry point first.
class _AyahPickerDialog extends StatefulWidget {
  const _AyahPickerDialog({required this.numbering, required this.text});

  final MushafNumbering numbering;
  final QuranText? text;

  @override
  State<_AyahPickerDialog> createState() => _AyahPickerDialogState();
}

class _AyahPickerDialogState extends State<_AyahPickerDialog> {
  int _surah = 1;
  int _ayah = 1;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<Surah>? surahs = widget.text?.surahs;
    final int ayahCount = widget.numbering.ayahCountOf(_surah);
    final bool ready = surahs != null && surahs.isNotEmpty && ayahCount > 0;

    return AlertDialog(
      title: Text(l10n.graphPickAyah),
      content: ready
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<int>(
                  value: _surah,
                  decoration: InputDecoration(labelText: l10n.surah),
                  items: <DropdownMenuItem<int>>[
                    for (final Surah surah in surahs)
                      DropdownMenuItem<int>(
                        value: surah.id,
                        child: Text('${surah.id}. ${surah.nameAr}'),
                      ),
                  ],
                  onChanged: (int? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _surah = value;
                      _ayah = 1;
                    });
                  },
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<int>(
                  value: _ayah.clamp(1, ayahCount),
                  decoration: InputDecoration(labelText: l10n.ayah),
                  items: <DropdownMenuItem<int>>[
                    for (int i = 1; i <= ayahCount; i++)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Text('$i'),
                      ),
                  ],
                  onChanged: (int? value) => setState(() => _ayah = value ?? 1),
                ),
              ],
            )
          : Text(l10n.graphPreparing),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.of(context).pop(
                    widget.numbering.idOf(_surah, _ayah),
                  )
              : null,
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

class _GraphHeader extends StatelessWidget {
  const _GraphHeader({
    required this.shown,
    required this.total,
    required this.countLabel,
    required this.shownLabel,
    required this.hint,
    required this.levelHint,
    required this.sourceTag,
    required this.targetTag,
    required this.level,
    required this.onLevel,
    required this.allLabel,
    required this.arabicUi,
  });

  final int shown;
  final int total;
  final String countLabel;
  final String shownLabel;
  final String hint;
  final String levelHint;
  final String sourceTag;
  final String targetTag;
  final int level;
  final void Function(int level) onLevel;
  final String allLabel;
  final bool arabicUi;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool offersLevels = total > 2;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            offersLevels && shown != total ? shownLabel : countLabel,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Text(offersLevels ? levelHint : hint, style: theme.textTheme.bodySmall),
          SizedBox(height: 8.h),
          if (offersLevels)
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: <Widget>[
                for (final int choice in <int>[2, 5, 10, _kLevelAll])
                  ChoiceChip(
                    label: Text(
                      choice == _kLevelAll
                          ? allLabel
                          : (arabicUi ? arabicDigits(choice) : '$choice'),
                    ),
                    selected: level == choice,
                    onSelected: (_) => onLevel(choice),
                  ),
              ],
            ),
          if (offersLevels) SizedBox(height: 6.h),
          Wrap(
            spacing: 14.w,
            runSpacing: 6.h,
            children: <Widget>[
              _LegendDot(color: kMutashabihSourceColor, label: sourceTag),
              _LegendDot(color: kMutashabihTargetColor, label: targetTag),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            SizedBox(height: 14.h),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}

class _EmptyNode extends StatelessWidget {
  const _EmptyNode({
    required this.label,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  final String label;
  final String hint;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.hub_outlined,
                  size: 40.sp, color: Theme.of(context).colorScheme.outline),
              SizedBox(height: 12.h),
              Text(label, textAlign: TextAlign.center),
              SizedBox(height: 4.h),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 12.h),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.search),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      );
}

class _GraphError extends StatelessWidget {
  const _GraphError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline,
                  size: 40.sp, color: Theme.of(context).colorScheme.error),
              SizedBox(height: 12.h),
              Text(message, textAlign: TextAlign.center),
              SizedBox(height: 10.h),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      );
}

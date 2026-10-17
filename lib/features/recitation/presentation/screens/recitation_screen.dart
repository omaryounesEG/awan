import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/features/recitation/data/datasources/mushaf_source.dart';
import 'package:awan/features/recitation/data/repositories/recitation_repository.dart';
import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/presentation/providers/recitation_providers.dart';
import 'package:awan/features/recitation/presentation/widgets/recitation_verse_view.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «صحيح التلاوة» — the reciter reads, the screen answers word by word.
///
/// The whole design follows one rule from the architecture note: a correction
/// is only useful where the eye already is. So the verse is the screen, the
/// words change colour in place, and everything else — the microphone, the
/// latency, the transcript — is deliberately quiet until it is asked for.
class RecitationScreen extends ConsumerStatefulWidget {
  const RecitationScreen({super.key});

  @override
  ConsumerState<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends ConsumerState<RecitationScreen> {
  WordVerdict _lastVerdict = WordVerdict.pending;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RecitationUiState ui = ref.watch(recitationProvider);
    final RecitationSnapshot snapshot = ui.snapshot;
    final AyahAlignment? alignment = snapshot.alignment;
    final bool arabic = ref.watch(appSettingsProvider).isArabic;

    _reactToMistakes(alignment);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recitationTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.recitationPickAyah,
            onPressed: () => _openPicker(context, ref, ui),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _VerseHeader(
              surahName: arabic ? ui.surahName : ui.surahName,
              ayah: ui.ayah,
              total: alignment?.words.length ?? 0,
              cursor: alignment?.cursor ?? 0,
            ),
            if (!ui.modelInstalled)
              _ModelCard(
                l10n: l10n,
                downloading: ui.downloading,
                progress: ui.downloadProgress,
                error: ui.downloadError,
                source: ui.downloadSource,
                onDownload: () => ref.read(recitationProvider.notifier).download(),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: alignment == null
                    ? _Preparing(l10n: l10n, progress: snapshot.progress)
                    : RecitationVerseView(alignment: alignment),
              ),
            ),
            if (snapshot.heard != null && ui.showHeard)
              _HeardStrip(text: snapshot.heard!, latency: snapshot.latency),
            _ErrorBanner(alignment: alignment, l10n: l10n),
            _Controls(
              l10n: l10n,
              snapshot: snapshot,
              hasModel: ui.modelInstalled,
              onMic: () {
                final RecitationController c = ref.read(recitationProvider.notifier);
                if (snapshot.phase == RecitationPhase.listening ||
                    snapshot.phase == RecitationPhase.thinking) {
                  c.stop();
                } else {
                  c.start();
                }
              },
              onToggleHeard: () => ref.read(recitationProvider.notifier).toggleHeard(),
              showHeard: ui.showHeard,
              onSample: ui.modelInstalled &&
                      snapshot.phase == RecitationPhase.idle
                  ? () => ref.read(recitationProvider.notifier).trySample()
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _reactToMistakes(AyahAlignment? alignment) {
    if (alignment == null) return;
    final RecitationWord? wrong = alignment.words
        .where((RecitationWord w) => w.isWrong)
        .cast<RecitationWord?>()
        .firstWhere((RecitationWord? w) => w!.verdict != _lastVerdict, orElse: () => null);
    if (wrong == null) return;
    _lastVerdict = wrong.verdict;
    if (wrong.verdict == WordVerdict.word) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref, RecitationUiState ui) async {
    final List<SurahMeta> surahs = await ref.read(surahListProvider.future);
    if (!context.mounted) return;
    final _Pick? picked = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => _PickerSheet(surahs: surahs, current: ui.surah),
    );
    if (picked == null) return;
    await ref.read(recitationProvider.notifier).select(
          surah: picked.surah.id,
          ayah: picked.ayah,
          surahName: picked.surah.nameAr,
        );
  }
}

class _VerseHeader extends StatelessWidget {
  const _VerseHeader({
    required this.surahName,
    required this.ayah,
    required this.total,
    required this.cursor,
  });

  final String surahName;
  final int ayah;
  final int total;
  final int cursor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
      child: Row(
        children: <Widget>[
          Text(surahName, style: theme.textTheme.titleMedium),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '﴿$ayah﴾',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const Spacer(),
          if (total > 0)
            Text(
              '$cursor/$total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.alignment, required this.l10n});

  final AyahAlignment? alignment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AyahAlignment? a = alignment;
    if (a == null) return const SizedBox.shrink();

    final List<RecitationWord> wrong =
        a.words.where((RecitationWord w) => w.verdict == WordVerdict.word).toList();
    if (wrong.isEmpty) return const SizedBox.shrink();
    final RecitationWord last = wrong.last;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.record_voice_over_outlined, size: 18.sp, color: theme.colorScheme.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              l10n.recitationHeardInstead(last.spoken ?? '', last.uthmani),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.l10n,
    required this.snapshot,
    required this.hasModel,
    required this.onMic,
    required this.onToggleHeard,
    required this.showHeard,
    required this.onSample,
  });

  final AppLocalizations l10n;
  final RecitationSnapshot snapshot;
  final bool hasModel;
  final VoidCallback onMic;
  final VoidCallback onToggleHeard;
  final bool showHeard;

  /// Runs a bundled ayah so the feature can be seen working in five seconds,
  /// before the user has decided to trust it with their own voice.
  final VoidCallback? onSample;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool busy = snapshot.phase == RecitationPhase.listening ||
        snapshot.phase == RecitationPhase.thinking;
    final bool error = snapshot.phase == RecitationPhase.error;

    final String status = switch (snapshot.phase) {
      RecitationPhase.listening => l10n.recitationListening,
      RecitationPhase.thinking => l10n.recitationThinking,
      RecitationPhase.complete => l10n.recitationComplete,
      RecitationPhase.preparing => l10n.recitationPreparing,
      RecitationPhase.error => _errorText(l10n, snapshot.error),
      RecitationPhase.idle => hasModel ? l10n.recitationIdle : l10n.recitationModelMissing,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
      child: Column(
        children: <Widget>[
          Text(
            status,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: error ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          if (onSample != null)
            TextButton.icon(
              onPressed: onSample,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: Text(l10n.recitationTrySample),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: l10n.recitationHeard,
                onPressed: snapshot.heard == null ? null : onToggleHeard,
                icon: Icon(showHeard ? Icons.subtitles : Icons.subtitles_off_outlined),
              ),
              SizedBox(width: 18.w),
              _MicButton(
                level: snapshot.level,
                busy: busy,
                enabled: hasModel,
                onTap: onMic,
              ),
              SizedBox(width: 18.w),
              SizedBox(
                width: 48.w,
                child: snapshot.latency.inMilliseconds > 0
                    ? Text(
                        '${snapshot.latency.inMilliseconds}ms',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'mic_denied':
        return l10n.recitationMicDenied;
      case 'model_missing':
        return l10n.recitationModelMissing;
      case 'download_failed':
        return l10n.recitationDownloadFailed;
      default:
        return l10n.recitationError;
    }
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.level,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final double level;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double ring = 74 + (busy ? level * 46 : 0);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: ring.w,
        height: ring.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? (busy ? theme.colorScheme.primary : theme.colorScheme.primaryContainer)
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          busy ? Icons.stop_rounded : Icons.mic_none_rounded,
          size: 34.sp,
          color: busy
              ? theme.colorScheme.onPrimary
              : (enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HeardStrip extends StatelessWidget {
  const _HeardStrip({required this.text, required this.latency});

  final String text;
  final Duration latency;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.l10n,
    required this.downloading,
    required this.progress,
    required this.onDownload,
    this.error,
    this.source,
  });

  final AppLocalizations l10n;
  final bool downloading;
  final double progress;
  final VoidCallback onDownload;

  /// Reason code from the last attempt — shown in words, never as a code.
  final String? error;
  final String? source;

  String? get _errorText => switch (error) {
        null => null,
        'offline' => l10n.recitationDownloadErrorOffline,
        'timeout' => l10n.recitationDownloadErrorTimeout,
        'not_found' => l10n.recitationDownloadErrorNotFound,
        'bad_payload' => l10n.recitationDownloadErrorBadPayload,
        _ => l10n.recitationDownloadErrorUnknown,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.recitationModelHint,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.recitationModelSizeHint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (source != null && !downloading)
            Text(
              l10n.recitationDownloadedFrom(source!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (_errorText != null) ...<Widget>[
            SizedBox(height: 6.h),
            Text(
              _errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          if (downloading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LinearProgressIndicator(value: progress == 0 ? null : progress),
                SizedBox(height: 4.h),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            )
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                onPressed: onDownload,
                child: Text(
                  _errorText == null
                      ? l10n.recitationDownload
                      : l10n.recitationDownloadRetry,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({required this.l10n, required this.progress});

  final AppLocalizations l10n;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 40.h),
        const CircularProgressIndicator(),
        SizedBox(height: 16.h),
        Text(l10n.recitationPreparing),
      ],
    );
  }
}

class _Pick {
  const _Pick(this.surah, this.ayah);
  final SurahMeta surah;
  final int ayah;
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.surahs, required this.current});

  final List<SurahMeta> surahs;
  final int current;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late int _surah = widget.current;
  int _ayah = 1;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SurahMeta row = widget.surahs.firstWhere(
      (SurahMeta s) => s.id == _surah,
      orElse: () => widget.surahs.first,
    );
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('السورة', style: theme.textTheme.titleMedium),
                ),
                Text('${row.nameAr} • ${row.ayahCount} آية',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          SizedBox(
            height: 160.h,
            child: ListView.builder(
              itemCount: widget.surahs.length,
              itemBuilder: (BuildContext context, int index) {
                final SurahMeta s = widget.surahs[index];
                final bool selected = s.id == _surah;
                return ListTile(
                  dense: true,
                  selected: selected,
                  title: Text('${s.id}. ${s.nameAr}'),
                  subtitle: Text('${s.ayahCount} آية'),
                  onTap: () => setState(() {
                    _surah = s.id;
                    _ayah = 1;
                  }),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
              ),
              itemCount: row.ayahCount,
              itemBuilder: (BuildContext context, int index) {
                final int number = index + 1;
                final bool selected = number == _ayah;
                return InkWell(
                  borderRadius: BorderRadius.circular(10.r),
                  onTap: () => setState(() => _ayah = number),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primary : null,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected ? theme.colorScheme.onPrimary : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_Pick(row, _ayah)),
                child: const Text('ابدأ هذه الآية'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hidden-but-real entry for verifying the pipeline on a device with no
/// microphone: drops a 16 kHz mono WAV through the same segmenter and model.
class RecitationFileProbe {
  const RecitationFileProbe._();

  static Future<void> run(WidgetRef ref, File file) async {
    await ref.read(recitationProvider.notifier).feed(file);
  }
}

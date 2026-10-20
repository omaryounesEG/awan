import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';
import 'package:awan/features/adhkar/presentation/providers/adhkar_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «الاستماع دون إنترنت» — a download the reader asks for.
///
/// The clips are ~1.3 MB each, so they are not shipped inside the APK: the
/// chapter text is a few kilobytes and must work offline, the voices are thirty
/// megabytes and belong on the phone only if the reader wants them there.
class AdhkarDownloadSheet extends ConsumerStatefulWidget {
  const AdhkarDownloadSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const AdhkarDownloadSheet(),
      );

  @override
  ConsumerState<AdhkarDownloadSheet> createState() => _AdhkarDownloadSheetState();
}

class _AdhkarDownloadSheetState extends ConsumerState<AdhkarDownloadSheet> {
  bool _busy = false;
  double _progress = 0;
  int _done = 0;
  int _downloaded = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _count();
  }

  Future<void> _count() async {
    final AdhkarChapter? chapter =
        await ref.read(adhkarChapterProvider.future);
    if (chapter == null) return;
    final int count =
        await ref.read(adhkarRepositoryProvider).downloadedCount(chapter.items);
    if (!mounted) return;
    setState(() {
      _downloaded = count;
      _total = chapter.items.length;
    });
  }

  Future<void> _downloadAll() async {
    final AdhkarChapter? chapter =
        await ref.read(adhkarChapterProvider.future);
    if (chapter == null) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _done = 0;
      _error = null;
    });
    try {
      for (int i = 0; i < chapter.items.length; i++) {
        final AdhkarItem item = chapter.items[i];
        if (await ref.read(adhkarRepositoryProvider).localAudio(item.id) !=
            null) {
          setState(() {
            _done = i + 1;
            _progress = (i + 1) / chapter.items.length;
          });
          continue;
        }
        await ref.read(adhkarRepositoryProvider).downloadAudio(
          item,
          onProgress: (double p) {
            if (mounted) {
              setState(() => _progress = (i + p) / chapter.items.length);
            }
          },
        );
        if (!mounted) return;
        setState(() => _done = i + 1);
      }
      await _count();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAll() async {
    final AdhkarChapter? chapter =
        await ref.read(adhkarChapterProvider.future);
    if (chapter == null) return;
    setState(() => _busy = true);
    for (final AdhkarItem item in chapter.items) {
      await ref.read(adhkarRepositoryProvider).deleteAudio(item.id);
    }
    await _count();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.adhkarAudioTitle, style: theme.textTheme.titleMedium),
          SizedBox(height: 6.h),
          Text(
            l10n.adhkarAudioBody,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 10.h),
          Row(
            children: <Widget>[
              Icon(Icons.download_done, size: 16.sp,
                  color: theme.colorScheme.primary),
              SizedBox(width: 6.w),
              Text(
                l10n.adhkarAudioCount(_downloaded, _total),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          if (_busy) ...<Widget>[
            SizedBox(height: 10.h),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 4.h),
            Text('$_done / $_total', style: theme.textTheme.labelSmall),
          ],
          if (_error != null) ...<Widget>[
            SizedBox(height: 8.h),
            Text('$_error',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _downloadAll,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.adhkarAudioDownload),
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
                onPressed: _busy || _downloaded == 0 ? null : _deleteAll,
                child: Text(l10n.adhkarAudioDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

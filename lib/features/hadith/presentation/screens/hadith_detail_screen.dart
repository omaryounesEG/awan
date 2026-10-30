import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// One hadith, then its takhrij: the same matn in the other books.
///
/// The «تخريج» here is not a scholar's verdict and does not pretend to be — it
/// says plainly where the same words are narrated, which is what lets a reader
/// check a hadith instead of trusting one app.
class HadithDetailScreen extends ConsumerWidget {
  const HadithDetailScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final HadithCorpus? corpus = ref.watch(hadithCorpusProvider).valueOrNull;

    if (corpus == null || index < 0 || index >= corpus.hadiths.length) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Hadith hadith = corpus.hadiths[index];
    final HadithBook book = corpus.bookOf(hadith);
    final String chapter = corpus.chapterOf(hadith);
    final String grade = hadith.grade < corpus.gradeLabels.length
        ? corpus.gradeLabels[hadith.grade]
        : '';
    final List<Hadith> related = corpus.relatedTo(hadith);

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.ar} · ${hadith.number}'),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.hadithCopy,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text: '${hadith.text}\n\n${book.ar} — ${l10n.hadithNumber} '
                    '${hadith.number}${chapter.isEmpty ? '' : ' · $chapter'}',
              ));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.hadithCopied)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(grade, style: theme.textTheme.labelSmall),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  chapter,
                  style: theme.textTheme.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SelectableText(
            hadith.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 2.0),
          ),
          SizedBox(height: 20.h),
          Text(
            l10n.hadithTakhrij,
            style: theme.textTheme.titleSmall,
          ),
          SizedBox(height: 4.h),
          Text(
            related.isEmpty ? l10n.hadithNoTakhrij : l10n.hadithTakhrijNote,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 10.h),
          for (final Hadith other in related)
            Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                dense: true,
                title: Text(
                  '${corpus.bookOf(other).ar} · ${l10n.hadithNumber} ${other.number}',
                  style: theme.textTheme.labelMedium,
                ),
                subtitle: Text(
                  other.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_left, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HadithDetailScreen(index: other.index),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

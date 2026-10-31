import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:awan/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:awan/features/hadith/presentation/screens/hadith_research_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «الحديث» — search first, browse second.
///
/// Twenty-four thousand hadiths are useless as a list and useful as an answer:
/// the field is at the top, the filters are one tap away, and the list underneath
/// is what matched, not everything that exists.
class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<HadithCorpus> corpus = ref.watch(hadithCorpusProvider);
    final HadithFilter filter = ref.watch(hadithFilterProvider);
    final HadithResults? results = ref.watch(hadithResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hadithTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.hadithResearchTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HadithResearchScreen(),
              ),
            ),
            icon: const Icon(Icons.biotech_outlined),
          ),
          IconButton(
            tooltip: l10n.hadithFilters,
            onPressed: () => _openFilters(corpus.valueOrNull),
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: corpus.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              SizedBox(height: 12.h),
              Text(l10n.hadithLoading),
            ],
          ),
        ),
        error: (Object error, StackTrace _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (HadithCorpus data) => Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
              child: TextField(
                controller: _field,
                textInputAction: TextInputAction.search,
                onChanged: ref.read(hadithFilterProvider.notifier).setQuery,
                decoration: InputDecoration(
                  hintText: l10n.hadithSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _field.clear();
                            ref.read(hadithFilterProvider.notifier).setQuery('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  isDense: true,
                ),
              ),
            ),
            _FilterStrip(filter: filter, corpus: data),
            if (results != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.hadithResultCount(results.total),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    if (results.capped)
                      Text(
                        l10n.hadithCapped(results.items.length),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            Expanded(
              child: results == null
                  ? const SizedBox.shrink()
                  : results.items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.hadithEmpty,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
                          itemCount: results.items.length,
                          itemBuilder: (BuildContext context, int i) => _HadithTile(
                            hadith: results.items[i],
                            corpus: data,
                            query: filter.query,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters(HadithCorpus? corpus) async {
    if (corpus == null) return;
    final AppLocalizations l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController scroll) =>
            Consumer(builder: (BuildContext context, WidgetRef ref, _) {
          final HadithFilter filter = ref.watch(hadithFilterProvider);
          final HadithController controller =
              ref.read(hadithFilterProvider.notifier);
          return ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(l10n.hadithFilters,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.clear();
                      _field.clear();
                    },
                    child: Text(l10n.hadithClearFilters),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(l10n.hadithBooks, style: Theme.of(context).textTheme.labelLarge),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: <Widget>[
                  for (int i = 0; i < corpus.books.length; i++)
                    FilterChip(
                      label: Text(corpus.books[i].ar),
                      selected: filter.books.contains(i),
                      onSelected: (_) => controller.toggleBook(i),
                    ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(l10n.hadithGrades, style: Theme.of(context).textTheme.labelLarge),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: <Widget>[
                  for (int i = 0; i < corpus.gradeLabels.length; i++)
                    FilterChip(
                      label: Text(corpus.gradeLabels[i]),
                      selected: filter.grades.contains(i),
                      onSelected: (_) => controller.toggleGrade(i),
                    ),
                ],
              ),
              if (filter.books.length == 1) ...<Widget>[
                SizedBox(height: 14.h),
                Text(l10n.hadithChapters,
                    style: Theme.of(context).textTheme.labelLarge),
                SizedBox(height: 6.h),
                for (final HadithChapter chapter
                    in corpus.books[filter.books.first].chapters)
                  RadioListTile<int>(
                    dense: true,
                    value: chapter.id,
                    groupValue: filter.chapterId,
                    title: Text(chapter.ar,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onChanged: (int? value) => controller.setChapter(
                      filter.books.first,
                      value == filter.chapterId ? null : value,
                    ),
                  ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip({required this.filter, required this.corpus});

  final HadithFilter filter;
  final HadithCorpus corpus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<Widget> chips = <Widget>[
      for (final int book in filter.books)
        InputChip(
          label: Text(corpus.books[book].ar),
          onDeleted: () => ref.read(hadithFilterProvider.notifier).toggleBook(book),
        ),
      for (final int grade in filter.grades)
        InputChip(
          label: Text(corpus.gradeLabels[grade]),
          onDeleted: () =>
              ref.read(hadithFilterProvider.notifier).toggleGrade(grade),
        ),
      if (filter.chapterId != null)
        InputChip(
          label: Text(
            corpus.books[filter.chapterBook ?? 0].chapter(filter.chapterId!)?.ar ??
                l10n.hadithChapters,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () => ref
              .read(hadithFilterProvider.notifier)
              .setChapter(filter.chapterBook ?? 0, null),
        ),
    ];
    if (chips.isEmpty) return SizedBox(height: 8.h);
    return SizedBox(
      height: 44.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: <Widget>[
          for (final Widget chip in chips)
            Padding(padding: EdgeInsetsDirectional.only(end: 6.w), child: chip),
        ],
      ),
    );
  }
}

class _HadithTile extends StatelessWidget {
  const _HadithTile({
    required this.hadith,
    required this.corpus,
    required this.query,
  });

  final Hadith hadith;
  final HadithCorpus corpus;
  final String query;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final HadithBook book = corpus.bookOf(hadith);
    final String grade = hadith.grade < corpus.gradeLabels.length
        ? corpus.gradeLabels[hadith.grade]
        : '';

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HadithDetailScreen(index: hadith.index),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${book.ar} · ${l10n.hadithNumber} ${hadith.number}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  if (grade.isNotEmpty) _GradeBadge(label: grade),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                hadith.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool strong = label.contains('صحيح') && !label.contains('حسن');
    final bool weak = label.contains('ضعيف');
    final Color color = weak
        ? theme.colorScheme.errorContainer
        : strong
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

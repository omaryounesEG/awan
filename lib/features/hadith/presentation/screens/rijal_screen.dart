import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/hadith/domain/entities/narrator.dart';
import 'package:awan/features/hadith/presentation/providers/rijal_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «رجال الحديث» — the narrator index, searchable by name and filterable by the
/// category the source gave them.
class RijalScreen extends ConsumerStatefulWidget {
  const RijalScreen({super.key});

  @override
  ConsumerState<RijalScreen> createState() => _RijalScreenState();
}

class _RijalScreenState extends ConsumerState<RijalScreen> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<RijalIndex> index = ref.watch(rijalIndexProvider);
    final RijalQuery query = ref.watch(rijalQueryProvider);
    final List<Narrator>? results = ref.watch(rijalResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hadithResearchRijalTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext dialog) => AlertDialog(
                title: Text(l10n.hadithRijalSourceTitle),
                content: Text(l10n.hadithRijalSourceBody),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialog).pop(),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(child: Text('$error')),
        data: (RijalIndex data) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _field,
                onChanged: ref.read(rijalQueryProvider.notifier).setQuery,
                decoration: InputDecoration(
                  hintText: l10n.hadithRijalSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: <Widget>[
                  for (int i = 0; i < data.categories.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6, top: 6),
                      child: FilterChip(
                        label: Text(data.categories[i]),
                        selected: query.categories.contains(i),
                        onSelected: (_) => ref
                            .read(rijalQueryProvider.notifier)
                            .toggleCategory(i),
                      ),
                    ),
                ],
              ),
            ),
            if (results != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    results.length >= kRijalResultCap
                        ? l10n.hadithRijalCapped(kRijalResultCap)
                        : l10n.hadithRijalCount(results.length),
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),
            Expanded(
              child: results == null
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int i) {
                        final Narrator narrator = results[i];
                        final String grade = data.categoryOf(narrator);
                        final List<String> meta = <String>[
                          if (grade.isNotEmpty) grade,
                          if (narrator.deathYear > 0)
                            l10n.hadithRijalDied(narrator.deathYear),
                          if (narrator.place.isNotEmpty) narrator.place,
                        ];
                        return ListTile(
                          dense: true,
                          title: Text(narrator.name),
                          subtitle: Text(
                            meta.join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:awan/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «المتون والعلاقات» — search for words inside the matn, and see, for every
/// hit, the other books that narrate the same matn.
///
/// This is the takhrij workbench: it says where the words are, and refuses to
/// say whether the hadith is authentic.
class MatnRelationsScreen extends ConsumerStatefulWidget {
  const MatnRelationsScreen({super.key});

  @override
  ConsumerState<MatnRelationsScreen> createState() => _MatnRelationsScreenState();
}

class _MatnRelationsScreenState extends ConsumerState<MatnRelationsScreen> {
  final TextEditingController _field = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final HadithCorpus? corpus = ref.watch(hadithCorpusProvider).valueOrNull;

    if (corpus == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.hadithResearchMatnTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String needle = normalizeArabic(_query);
    final List<Hadith> hits = <Hadith>[];
    if (needle.isNotEmpty) {
      for (int i = 0; i < corpus.hadiths.length; i++) {
        if (!corpus.search[i].contains(needle)) continue;
        hits.add(corpus.hadiths[i]);
        if (hits.length >= 120) break;
      }
      hits.sort((Hadith a, Hadith b) => a.related.length.compareTo(b.related.length));
      hits.sort((Hadith a, Hadith b) =>
          b.related.length.compareTo(a.related.length));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithResearchMatnTitle)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: TextField(
              controller: _field,
              textInputAction: TextInputAction.search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.hadithMatnSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (needle.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.hadithMatnIntro,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            Expanded(
              child: hits.isEmpty
                  ? Center(child: Text(l10n.hadithEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: hits.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Hadith hadith = hits[i];
                        final List<Hadith> related = corpus.relatedTo(hadith);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    HadithDetailScreen(index: hadith.index),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${corpus.bookOf(hadith).ar} · ${hadith.number}',
                                    style: theme.textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hadith.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (related.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: <Widget>[
                                        for (final Hadith other in related.take(4))
                                          ActionChip(
                                            visualDensity: VisualDensity.compact,
                                            label: Text(
                                              '${corpus.bookOf(other).ar} · ${other.number}',
                                              style: theme.textTheme.labelSmall,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => HadithDetailScreen(
                                                  index: other.index,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

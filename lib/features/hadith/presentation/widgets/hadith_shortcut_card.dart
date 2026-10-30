import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:awan/features/hadith/presentation/screens/hadith_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The hadith on the home screen, beside the Qur'an and the mutashabihat.
///
/// It is a card rather than a square in the shortcut grid because it is a
/// library, not a tool: the card says how many hadiths are inside and what can be
/// asked of them.
class HadithShortcutCard extends ConsumerWidget {
  const HadithShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final HadithCorpus? corpus = ref.watch(hadithCorpusProvider).valueOrNull;

    final String subtitle = corpus == null
        ? l10n.hadithSubtitle
        : l10n.hadithCardCount(
            corpus.total,
            corpus.books.length,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HadithScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.hadithTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

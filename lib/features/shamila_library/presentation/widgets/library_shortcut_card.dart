import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/presentation/providers/library_providers.dart';
import 'package:awan/features/shamila_library/presentation/screens/library_home_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The library on the home screen.
///
/// Like the Quran card, it is its own card rather than a square in the shortcut
/// grid, because it can say something the grid cannot: how many books are on the
/// device and what was read last. A reader who has downloaded nothing gets the
/// one sentence that explains what this is for.
class LibraryShortcutCard extends ConsumerWidget {
  const LibraryShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<BookEntry>> shelf = ref.watch(libraryShelfProvider);
    final List<BookEntry> books = shelf.valueOrNull ?? const <BookEntry>[];

    final String subtitle;
    if (books.isEmpty) {
      subtitle = l10n.libraryShortcutEmpty;
    } else {
      final BookEntry last = books.firstWhere(
        (BookEntry book) => book.lastChapter > 0,
        orElse: () => books.first,
      );
      subtitle = last.lastChapter > 0
          ? l10n.libraryShortcutLastRead(last.title)
          : l10n.libraryShortcutShelf(books.length);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LibraryHomeScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_library_outlined,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.libraryTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
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

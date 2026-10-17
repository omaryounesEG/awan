import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/presentation/providers/library_providers.dart';
import 'package:awan/features/shamila_library/presentation/screens/book_reader_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// One catalogue row.
///
/// The tile is the whole install story: a book that is not on the device offers
/// one action (download), a book that is offers one (read) plus the way to give
/// the space back. While a download runs the tile *is* the progress bar, because
/// the reader asked for one thing and should not have to hunt for it.
class BookTile extends ConsumerWidget {
  const BookTile({required this.book, super.key});

  final BookEntry book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final BookInstallProgress? progress =
        ref.watch(bookInstallProvider(book.id));
    final bool busy = progress != null &&
        (progress.phase == BookInstallPhase.downloading ||
            progress.phase == BookInstallPhase.installing);
    final bool failed = progress?.phase == BookInstallPhase.failed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: book.downloaded
            ? () => _openReader(context)
            : (busy ? null : () => _install(ref)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _Cover(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _byline(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(book: book, l10n: l10n),
                    if (busy || failed) ...<Widget>[
                      const SizedBox(height: 8),
                      _InstallLine(
                        progress: progress,
                        l10n: l10n,
                        onCancel: () =>
                            ref.read(libraryActionsProvider.notifier).cancel(book.id),
                      ),
                    ],
                  ],
                ),
              ),
              _Trailing(
                book: book,
                busy: busy,
                progress: progress,
                onInstall: () => _install(ref),
                onRead: () => _openReader(context),
                onDismiss: () => ref
                    .read(libraryActionsProvider.notifier)
                    .dismiss(book.id),
                onRemove: () => _confirmRemove(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _byline(AppLocalizations l10n) {
    final List<String> parts = <String>[
      if (book.author.isNotEmpty) book.author,
      if ((book.authorDied ?? 0) > 0) l10n.libraryAuthorDied(book.authorDied!),
    ];
    return parts.isEmpty ? book.category : parts.join(' · ');
  }

  void _install(WidgetRef ref) =>
      ref.read(libraryActionsProvider.notifier).start(book.id);

  /// Deleting an offline copy is the one destructive action here, so it asks —
  /// and says what it will not do (the book stays in the catalogue).
  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.libraryRemoveQuestion(book.title)),
        content: Text(l10n.libraryRemoveHint),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.libraryCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.libraryRemove),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(libraryActionsProvider.notifier).remove(book.id);
      if (context.mounted) {
        ref.read(libraryActionsProvider.notifier).dismiss(book.id);
      }
    }
  }

  void _openReader(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => BookReaderScreen(bookId: book.id),
        ),
      );
}

/// No cover art exists in the corpus, so the tile shows a spine instead of
/// pretending to have a scan.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.primary.withOpacity(0.25)),
      ),
      child: Icon(Icons.menu_book_outlined, size: 22, color: scheme.primary),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.book, required this.l10n});

  final BookEntry book;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> parts = <String>[
      if (book.chapters > 0) l10n.libraryChaptersCount(book.chapters),
      if (book.sizeBytes > 0)
        l10n.librarySizeKb((book.sizeBytes / 1024).round()),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(book.category, style: theme.textTheme.labelSmall),
        ),
        for (final String part in parts)
          Text(part, style: theme.textTheme.labelSmall),
        if (book.downloaded)
          Icon(Icons.offline_pin_outlined,
              size: 14, color: theme.colorScheme.primary),
      ],
    );
  }
}

class _InstallLine extends StatelessWidget {
  const _InstallLine({
    required this.progress,
    required this.l10n,
    required this.onCancel,
  });

  final BookInstallProgress? progress;
  final AppLocalizations l10n;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final BookInstallProgress? value = progress;
    final int percent = ((value?.ratio ?? 0) * 100).round();
    final bool failed = value?.phase == BookInstallPhase.failed;

    final String label = failed
        ? l10n.librarySyncFailed
        : value?.phase == BookInstallPhase.installing
            ? l10n.libraryUnpacking(percent)
            : l10n.libraryInstalling(percent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: failed ? 0 : (value?.ratio ?? 0).clamp(0.0, 1.0),
            minHeight: 5,
          ),
        ),
        if (!failed)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.libraryCancelInstall),
            ),
          ),
      ],
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.book,
    required this.busy,
    required this.progress,
    required this.onInstall,
    required this.onRead,
    required this.onDismiss,
    required this.onRemove,
  });

  final BookEntry book;
  final bool busy;
  final BookInstallProgress? progress;
  final VoidCallback onInstall;
  final VoidCallback onRead;
  final VoidCallback onDismiss;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, right: 4),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    if (progress?.phase == BookInstallPhase.done) {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline),
        color: Theme.of(context).colorScheme.primary,
        onPressed: onDismiss,
      );
    }

    if (book.downloaded) {
      return PopupMenuButton<String>(
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        onSelected: (String value) {
          if (value == 'remove') onRemove();
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'read',
            onTap: onRead,
            child: Text(context.l10n.libraryRead),
          ),
          PopupMenuItem<String>(
            value: 'remove',
            child: Text(context.l10n.libraryRemove),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: FilledButton.tonal(
        onPressed: onInstall,
        child: Text(context.l10n.libraryInstall),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';
import 'package:awan/features/shamila_library/presentation/providers/library_providers.dart';
import 'package:awan/features/shamila_library/presentation/widgets/book_tile.dart';
import 'package:awan/features/shamila_library/presentation/widgets/library_source_sheet.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The library screen: find a book, or open one already on the device.
///
/// Two tabs, because those are the only two questions a reader has here — and the
/// index is refreshed on open rather than behind a button, since a stale catalogue
/// is the only thing that could make the first tab useless. The freshness window
/// in the repository makes that cheap: opening the screen five times fetches once.
class LibraryHomeScreen extends ConsumerStatefulWidget {
  const LibraryHomeScreen({super.key});

  @override
  ConsumerState<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends ConsumerState<LibraryHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) ref.read(libraryIndexProvider.notifier).sync();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 220),
      () => ref.read(libraryQueryProvider.notifier).state = value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.librarySource,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => showLibrarySourceSheet(context, ref),
          ),
          const _SyncButton(),
          const _InstallAllButton(),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.libraryDiscover),
            Tab(text: l10n.libraryShelf),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          const _StatusBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _DiscoverTab(search: _search, onQueryChanged: _onQueryChanged),
                const _ShelfTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryIndexState state = ref.watch(libraryIndexProvider);
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: context.l10n.librarySync,
      icon: const Icon(Icons.refresh),
      onPressed: () =>
          ref.read(libraryIndexProvider.notifier).sync(force: true),
    );
  }
}

/// One line between the tabs and the list: what the last sync did, or why it
/// could not run. Silent when there is nothing to say.
class _StatusBanner extends ConsumerWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final LibraryIndexState state = ref.watch(libraryIndexProvider);
    final ThemeData theme = Theme.of(context);

    final Failure? failure = state.failure;
    final LibrarySyncReport? report = state.report;
    if (failure == null && report == null) return const SizedBox.shrink();

    // An error can arrive after a successful sync (a later refresh failed), and
    // then it is shown with the numbers of the last good one still visible.
    final bool isError = failure != null;
    final String text = isError
        ? libraryFailureText(l10n, failure)
        : report == null
            ? l10n.librarySynced
            : l10n.librarySyncedDetail(report.added, report.total);

    return Container(
      width: double.infinity,
      color: isError
          ? theme.colorScheme.errorContainer.withOpacity(0.5)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
            size: 16,
            color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.labelMedium)),
          if (isError)
            TextButton(
              onPressed: () =>
                  ref.read(libraryIndexProvider.notifier).sync(force: true),
              child: Text(l10n.libraryRetry),
            ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab({required this.search, required this.onQueryChanged});

  final TextEditingController search;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<BookEntry>> results =
        ref.watch(libraryResultsProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: search,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.librarySearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        search.clear();
                        onQueryChanged('');
                      },
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const _CategoryBar(),
        Expanded(
          child: results.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (Object error, StackTrace _) => _EmptyState(
              title: l10n.librarySyncFailed,
              hint: '$error',
              icon: Icons.cloud_off_outlined,
            ),
            data: (List<BookEntry> books) {
              if (books.isEmpty) {
                final bool searching = ref.watch(libraryQueryProvider).isNotEmpty;
                return _EmptyState(
                  title: searching ? l10n.libraryNoResults : l10n.libraryIndexEmpty,
                  hint: searching ? l10n.librarySearchHint : l10n.libraryIndexEmptyHint,
                  icon: searching ? Icons.search_off : Icons.cloud_download_outlined,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: books.length,
                itemBuilder: (BuildContext context, int index) =>
                    BookTile(book: books[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends ConsumerWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<({String name, int count})>> categories =
        ref.watch(libraryCategoriesProvider);
    final String? selected = ref.watch(libraryCategoryProvider);
    final List<({String name, int count})> values =
        categories.valueOrNull ?? const <({String name, int count})>[];
    if (values.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(l10n.libraryAllCategories),
              selected: selected == null,
              onSelected: (bool _) =>
                  ref.read(libraryCategoryProvider.notifier).state = null,
            ),
          ),
          for (final ({String name, int count}) category in values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${category.name} · ${category.count}'),
                selected: selected == category.name,
                onSelected: (bool isSelected) => ref
                    .read(libraryCategoryProvider.notifier)
                    .state = isSelected ? category.name : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShelfTab extends ConsumerWidget {
  const _ShelfTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<BookEntry>> shelf = ref.watch(libraryShelfProvider);

    return shelf.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (Object error, StackTrace _) => _EmptyState(
        title: l10n.librarySyncFailed,
        hint: '$error',
        icon: Icons.error_outline,
      ),
      data: (List<BookEntry> books) {
        if (books.isEmpty) {
          return _EmptyState(
            title: l10n.libraryShelfEmpty,
            hint: l10n.libraryShelfEmptyHint,
            icon: Icons.download_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: books.length,
          itemBuilder: (BuildContext context, int index) =>
              BookTile(book: books[index]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint, required this.icon});

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              hint,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Installs the books the app already ships, in one tap.
///
/// Every book in the catalogue travels inside the APK, so «تحميل» on a bundled
/// book has always meant «copy it out of the bundle» — no network, no waiting.
/// Doing that one book at a time is what made the library look half-empty; this
/// fills it in one pass and says how far it has got.
class _InstallAllButton extends ConsumerStatefulWidget {
  const _InstallAllButton();

  @override
  ConsumerState<_InstallAllButton> createState() => _InstallAllButtonState();
}

class _InstallAllButtonState extends ConsumerState<_InstallAllButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = context.l10n;
    try {
      final LibraryRepository repository =
          await ref.read(libraryRepositoryProvider.future);
      final List<BookEntry> shelf = await repository.bookshelf();
      final Set<String> installed = <String>{
        for (final BookEntry book in shelf) book.id,
      };
      final List<BookEntry> all = await repository.search(limit: 500);
      final List<BookEntry> todo = all
          .where((BookEntry book) => !installed.contains(book.id))
          .toList();
      if (todo.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.libraryAllInstalled)),
        );
        return;
      }
      int done = 0;
      for (final BookEntry book in todo) {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 30),
            content: Text(
              l10n.libraryInstallingAll(done + 1, todo.length, book.title),
            ),
          ),
        );
        await for (final BookInstallProgress progress
            in repository.install(book.id)) {
          if (progress.phase == BookInstallPhase.failed) break;
        }
        done++;
      }
      ref.read(libraryRevisionProvider.notifier).state++;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.libraryAllInstalled)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: context.l10n.libraryInstallAll,
      icon: const Icon(Icons.download_for_offline_outlined),
      onPressed: _run,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';
import 'package:awan/features/shamila_library/presentation/providers/library_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The reader.
///
/// **Rendering.** A book is stored as ordered chunks (2-4 KB each, split on
/// section headings and printed pages). The list pages through them *by window*
/// ([AppConstants.libraryReaderPageSize] chunks per item), so one provider read
/// serves a screenful: a 6 000-chunk book scrolls without 6 000 database reads,
/// and a window already read comes from the provider cache.
///
/// **Position.** The exact resume point is the chunk index, saved while scrolling.
/// The *scroll* offset is restored from the saved ratio, then refined once: the
/// list only knows how tall its items are after it has built some, so the first
/// jump teaches it the height and the second lands on it. A book re-opens at the
/// passage the reader stopped at, not at a pixel.
class BookReaderScreen extends ConsumerStatefulWidget {
  const BookReaderScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

String _cleanReaderText(String text) {
  return text.replaceAll(RegExp(r'#?\s*[Pp]age[Vv]\d+[Pp]\d+|[Pp]age[Vv]\d+|[Pp]age[Pp]\d+'), '').trim();
}

String _cleanPage(String? raw) {
  if (raw == null) return '';
  final String cleaned = raw.replaceAll(RegExp(r'^[Pp]age[Vv]\d+[Pp]|^[Pp]age[Vv]|^[Pp]age[Pp]|[^0-9]'), '');
  return cleaned.replaceFirst(RegExp(r'^0+'), '');
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  static const int _window = AppConstants.libraryReaderPageSize;

  final ScrollController _scroll = ScrollController();
  Timer? _saveTimer;
  int _savedChapter = -1;
  bool _resumed = false;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _scroll.removeListener(_scheduleSave);
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    // Debounced: the reader is scrolling, not writing.
    _saveTimer = Timer(const Duration(milliseconds: 700), _persist);
  }

  /// How far through the scroll the reader is, 0..1.
  ///
  /// Deliberately *not* "the last window the list built": `ListView` builds ahead
  /// by its cache extent, so that window sits below the reader and the saved
  /// position would creep forward on every open. The scroll ratio is what the
  /// reader actually sees, and — because the restore uses the same ratio — saving
  /// and resuming can never disagree.
  double get _progress {
    if (!_scroll.hasClients) return 0;
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scroll.offset / max).clamp(0.0, 1.0);
  }

  /// The saved position, resolved to a chunk index.
  int _chapterFor(double progress) =>
      _total <= 1 ? 0 : (progress * (_total - 1)).round();

  Future<void> _persist({bool bump = false}) async {
    if (_total <= 0) return;
    final double progress = _progress;
    final int chapter = _chapterFor(progress);
    if (chapter == _savedChapter) return;
    _savedChapter = chapter;

    final LibraryRepository repository =
        await ref.read(libraryRepositoryProvider.future);
    await repository.savePosition(widget.bookId, chapter, progress);
    if (bump && mounted) {
      ref.read(libraryRevisionProvider.notifier).state++;
    }
  }

  /// Restores the reading position, reading it fresh from the repository.
  ///
  /// Deliberately not from the widget's `bookEntryProvider`: that provider is
  /// cached for the *catalogue*, so the value it hands back is the one from before
  /// this book was last read. A saved position is state the reader just changed,
  /// and asking the database is the only way the second visit sees the first
  /// visit's ending.
  Future<void> _restorePosition() async {
    if (_resumed || _total <= 0) return;
    _resumed = true;

    final LibraryRepository repository =
        await ref.read(libraryRepositoryProvider.future);
    final BookEntry? entry = await repository.book(widget.bookId);
    if (entry == null || !mounted) return;

    _savedChapter = entry.lastChapter;

    // Below a hair of progress the honest thing is the first page, not "94% of 0".
    final double fraction = entry.progress.clamp(0.0, 1.0);
    if (fraction <= 0.02) return;

    // A `ListView` measures lazily, so `maxScrollExtent` is only an estimate for
    // the first frames after open and a single jump lands short. Jumping on a few
    // consecutive frames converges on the saved place; it costs a few frames and
    // beats opening a 400-page book at the wrong page.
    int frames = 0;
    void step(Duration _) {
      if (!mounted || !_scroll.hasClients) return;
      final double target = _scroll.position.maxScrollExtent * fraction;
      if ((_scroll.offset - target).abs() > 1) _scroll.jumpTo(target);
      if (++frames < 12) WidgetsBinding.instance.addPostFrameCallback(step);
    }

    WidgetsBinding.instance.addPostFrameCallback(step);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppSettings settings = ref.watch(settingsProvider);
    final AsyncValue<BookEntry?> entryValue =
        ref.watch(bookEntryProvider(widget.bookId));
    final AsyncValue<int> totalValue =
        ref.watch(bookChunkCountProvider(widget.bookId));

    final BookEntry? entry = entryValue.valueOrNull;
    final int total = totalValue.valueOrNull ?? 0;
    final int windows = total == 0 ? 0 : ((total + _window - 1) ~/ _window);
    _total = total;

    if (total > 0 && !_resumed) unawaited(_restorePosition());

    final bool night = settings.libraryReaderNight;

    return Scaffold(
      backgroundColor: night ? Colors.black : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              entry?.title ?? l10n.readerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            if ((entry?.author ?? '').isNotEmpty)
              Text(
                entry!.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: <Widget>[
          // Search and contents read the book itself, so they only exist once it
          // is installed.
          if (total > 0) ...<Widget>[
            IconButton(
              tooltip: l10n.readerSearch,
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchSheet(context),
            ),
            IconButton(
              tooltip: l10n.readerContents,
              icon: const Icon(Icons.list_alt),
              onPressed: () => _showContentsSheet(context),
            ),
          ],
          PopupMenuButton<String>(
            tooltip: l10n.readerFontSize,
            onSelected: (String choice) {
              if (choice == 'night') {
                ref
                    .read(settingsControllerProvider.notifier)
                    .setLibraryReaderNight(!night);
              } else {
                _showDisplaySheet(context, settings);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'night',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      night ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  title: Text(l10n.readerNightMode),
                ),
              ),
              PopupMenuItem<String>(
                value: 'text',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.text_fields),
                  title: Text(l10n.readerFontSize),
                ),
              ),
            ],
          ),
        ],
      ),
      body: PopScope(
        // Leaving the reader is the moment the shelf's "last read" line and the
        // home card should catch up: one invalidation per visit, not one per
        // page turn.
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (didPop) ref.read(libraryRevisionProvider.notifier).state++;
        },
        // Three states, not two. A book that was marked downloaded but whose
        // text never arrived used to sit on a spinner forever — indistinguishable
        // from a slow disk and impossible to fix from the screen that broke.
        child: totalValue.isLoading && total == 0
            ? const Center(child: CircularProgressIndicator())
            : total == 0
                ? _BookNeedsRepair(bookId: widget.bookId)
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: windows,
              itemBuilder: (BuildContext context, int index) => _ChunkWindow(
                bookId: widget.bookId,
                index: index,
                count: _window,
                fontSize: settings.libraryReaderFontSize,
                night: night,
              ),
            ),
      ),
      bottomNavigationBar: _ReaderFooter(
        total: total,
        onBackToTop: _progress > 0.02 ? () => _scroll.jumpTo(0) : null,
      ),
    );
  }

  /// Moves the reader to a chunk index.
  ///
  /// The same mapping the position is saved with, run backwards: a ratio of the
  /// scrollable height. Items are variable height, so this lands near the heading
  /// rather than exactly on it — and it lands *there*, not a screen away.
  void _jumpToChapter(int chapter) {
    if (_total <= 0 || !_scroll.hasClients) return;
    final double ratio = _total <= 1
        ? 0
        : (chapter / (_total - 1)).clamp(0.0, 1.0);
    _scroll.jumpTo(_scroll.position.maxScrollExtent * ratio);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent * ratio);
    });
  }

  Future<void> _showContentsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _ContentsSheet(
        bookId: widget.bookId,
        onJump: (int chapter) {
          Navigator.of(sheetContext).pop();
          _jumpToChapter(chapter);
        },
      ),
    );
  }

  Future<void> _showSearchSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _SearchSheet(
        bookId: widget.bookId,
        onJump: (int chapter) {
          Navigator.of(sheetContext).pop();
          _jumpToChapter(chapter);
        },
      ),
    );
  }

  Future<void> _showDisplaySheet(
    BuildContext context,
    AppSettings settings,
  ) async {
    final AppLocalizations l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.readerFontSize,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? _) {
                final double size =
                    ref.watch(settingsProvider).libraryReaderFontSize;
                return Row(
                  children: <Widget>[
                    const Icon(Icons.text_decrease, size: 18),
                    Expanded(
                      child: Slider(
                        min: 12,
                        max: 34,
                        divisions: 22,
                        value: size,
                        label: size.round().toString(),
                        onChanged: (double value) => ref
                            .read(settingsControllerProvider.notifier)
                            .setLibraryReaderFontSize(value),
                      ),
                    ),
                    const Icon(Icons.text_increase, size: 18),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.readerNight),
              value: ref.watch(settingsProvider).libraryReaderNight,
              onChanged: (bool value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setLibraryReaderNight(value),
            ),
          ],
        ),
      ),
    );
  }
}


/// The book's own table of contents.
///
/// Rows are the chunks the corpus gave a heading, so a book that has none says so
/// instead of showing a list of paragraphs.
class _ContentsSheet extends ConsumerWidget {
  const _ContentsSheet({required this.bookId, required this.onJump});

  final String bookId;
  final void Function(int chapter) onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<BookChapter>> chapters =
        ref.watch(bookChaptersProvider(bookId));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: chapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(child: Text('$error')),
        data: (List<BookChapter> values) => values.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.readerContentsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            // A book whose only titles are page numbers gets its pages, labelled
            // as pages rather than passed off as chapters.
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      values.first.isPageMarker
                          ? l10n.readerPages
                          : l10n.readerContents,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Expanded(child: ListView.separated(
                itemCount: values.length,
                separatorBuilder: (BuildContext context, int _) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final BookChapter chapter = values[index];
                  final String page = _cleanPage(chapter.page);
                  if (chapter.isPageMarker) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.description_outlined,
                          size: 18, color: Theme.of(context).colorScheme.outline),
                      title: Text(chapter.title),
                      onTap: () => onJump(chapter.chapter),
                    );
                  }
                  return ListTile(
                    dense: true,
                    title: Text(chapter.title, maxLines: 2),
                    subtitle: page.isEmpty
                        ? null
                        : Text('ص $page',
                            style: Theme.of(context).textTheme.labelSmall),
                    onTap: () => onJump(chapter.chapter),
                  );
                },
                  )),
                ],
              ),
      ),
    );
  }
}

/// Search inside one book.
///
/// The query is debounced before it reaches the database — typing "الصلاة" must
/// not run five scans — and the run itself is keyed by (book, query), so going
/// back to a previous phrase is free.
class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet({required this.bookId, required this.onJump});

  final String bookId;
  final void Function(int chapter) onJump;

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<BookHit>> hits = ref.watch(
      bookSearchProvider((bookId: widget.bookId, query: _query)),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.readerSearchHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: hits.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => Center(child: Text('$error')),
                data: (List<BookHit> values) {
                  if (_query.trim().length < 2) {
                    return Center(
                      child: Text(l10n.readerSearchPrompt,
                          style: Theme.of(context).textTheme.bodySmall),
                    );
                  }
                  if (values.isEmpty) {
                    return Center(child: Text(l10n.readerSearchEmpty));
                  }
                  return ListView.separated(
                    itemCount: values.length,
                    separatorBuilder: (BuildContext context, int _) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final BookHit hit = values[index];
                      final String page = _cleanPage(hit.page);
                      final String where = <String>[
                        if ((hit.title ?? '').trim().isNotEmpty) hit.title!.trim(),
                        if (page.isNotEmpty) 'ص $page',
                      ].join(' · ');
                      return ListTile(
                        title: _HitSnippet(hit: hit),
                        subtitle: where.isEmpty
                            ? null
                            : Text(
                                where,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                        onTap: () => widget.onJump(hit.chapter),
                      );
                    },
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

/// One search result, with the matched words picked out.
class _HitSnippet extends StatelessWidget {
  const _HitSnippet({required this.hit});

  final BookHit hit;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final int at = hit.matchText.isEmpty ? -1 : hit.snippet.indexOf(hit.matchText);
    if (at < 0) {
      return Text(hit.snippet, maxLines: 3, overflow: TextOverflow.ellipsis);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: <TextSpan>[
          TextSpan(text: hit.snippet.substring(0, at)),
          TextSpan(
            text: hit.snippet.substring(at, at + hit.matchText.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: hit.snippet.substring(at + hit.matchText.length)),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// One window of the book: [count] consecutive chunks.
class _ChunkWindow extends ConsumerWidget {
  const _ChunkWindow({
    required this.bookId,
    required this.index,
    required this.count,
    required this.fontSize,
    required this.night,
  });

  final String bookId;
  final int index;
  final int count;
  final double fontSize;
  final bool night;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BookChunk>> chunks =
        ref.watch(bookChunksProvider(
      (bookId: bookId, from: index * count, count: count),
    ));

    return chunks.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (Object error, StackTrace _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('$error'),
      ),
      data: (List<BookChunk> values) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final BookChunk chunk in values) ...<Widget>[
            if ((chunk.title ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      chunk.title!.trim(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 1.05,
                        fontWeight: FontWeight.w700,
                        color: night
                            ? const Color(0xFFE8E2D4)
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (_cleanPage(chunk.page).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'ص \${_cleanPage(chunk.page)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize * 0.65,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            Text(
              _cleanReaderText(chunk.text),
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.85,
                color: night ? const Color(0xFFE8E2D4) : null,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReaderFooter extends StatelessWidget {
  const _ReaderFooter({required this.total, this.onBackToTop});

  final int total;
  final VoidCallback? onBackToTop;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: <Widget>[
            Text(
              l10n.libraryChaptersCount(total),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Spacer(),
            if (onBackToTop != null)
              TextButton.icon(
                onPressed: onBackToTop,
                icon: const Icon(Icons.vertical_align_top, size: 16),
                label: Text(l10n.readerBackToTop),
              ),
          ],
        ),
      ),
    );
  }
}

/// The book exists in the catalogue but carries no text on this device.
///
/// The reader used to sit on a spinner here forever. It now repairs itself:
/// every book that ships with the app can be re-installed from the bundle with
/// no network at all, so the honest first action is to *do* it rather than to
/// ask. The button stays for when the automatic attempt fails.
class _BookNeedsRepair extends ConsumerStatefulWidget {
  const _BookNeedsRepair({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookNeedsRepair> createState() => _BookNeedsRepairState();
}

class _BookNeedsRepairState extends ConsumerState<_BookNeedsRepair> {
  @override
  void initState() {
    super.initState();
    // After the first frame: starting an install during initState would touch
    // providers while the tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final LibraryActionsController actions =
        ref.read(libraryActionsProvider.notifier);
    if (actions.isBusy(widget.bookId)) return;
    actions.start(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookInstallProgress? progress =
        ref.watch(bookInstallProvider(widget.bookId));
    final bool busy = progress != null &&
        (progress.phase == BookInstallPhase.downloading ||
            progress.phase == BookInstallPhase.installing);

    // A finished install changes the answer to "how many chunks?"; refresh it so
    // the page that replaced this one is the book, not this card again.
    ref.listen<BookInstallProgress?>(
      bookInstallProvider(widget.bookId),
      (BookInstallProgress? previous, BookInstallProgress? next) {
        if (next?.phase == BookInstallPhase.done) {
          ref.invalidate(bookChunkCountProvider(widget.bookId));
        }
      },
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (busy)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(Icons.menu_book_outlined,
                  size: 44, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 14),
            Text(
              busy ? l10n.bookRepairing : l10n.bookNeedsRepair,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!busy) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.bookReinstall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

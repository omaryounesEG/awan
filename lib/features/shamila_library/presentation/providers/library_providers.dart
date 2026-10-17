import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/network/api_client.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/isar_service.dart';
import 'package:awan/features/shamila_library/data/datasources/library_local_datasource.dart';
import 'package:awan/features/shamila_library/data/datasources/library_remote_datasource.dart';
import 'package:awan/features/shamila_library/data/repositories/library_repository_impl.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// Wiring for the library.
///
/// The catalogue and the book texts live in Isar (offline-first); only two things
/// ever cross the network — the index, and the archive of a book the reader asked
/// for. Reading an installed book never does.
final FutureProvider<LibraryRepository> libraryRepositoryProvider =
    FutureProvider<LibraryRepository>((Ref ref) async {
  final IsarService isarService = ref.watch(isarServiceProvider);
  final ApiClient api = ref.watch(apiClientProvider);
  final Directory cache = await getTemporaryDirectory();

  return LibraryRepositoryImpl(
    remote: DioLibraryRemoteDataSource(api.dio),
    local: IsarLibraryLocalDataSource(isarService.isar),
    // Read through the settings each time, so a mirror typed into the screen takes
    // effect on the next sync rather than on the next launch.
    baseUrl: () => ref.read(settingsProvider).libraryCdnBaseUrl,
    cacheDir: Directory('${cache.path}/awan_library'),
    indexTtl: AppConstants.libraryIndexTtl,
  );
});

/// Bumped after anything that changes local state (sync, install, remove,
/// resume). Query providers watch it, so no screen has to remember to refresh.
final StateProvider<int> libraryRevisionProvider =
    StateProvider<int>((Ref ref) => 0);

// ------------------------------------------------------------------ catalogue
final StateProvider<String> libraryQueryProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<String?> libraryCategoryProvider =
    StateProvider<String?>((Ref ref) => null);

final FutureProvider<List<BookEntry>> libraryResultsProvider =
    FutureProvider<List<BookEntry>>((Ref ref) async {
  ref.watch(libraryRevisionProvider);
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.search(
    query: ref.watch(libraryQueryProvider),
    category: ref.watch(libraryCategoryProvider),
  );
});

final FutureProvider<List<({String name, int count})>>
    libraryCategoriesProvider =
    FutureProvider<List<({String name, int count})>>((Ref ref) async {
  ref.watch(libraryRevisionProvider);
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.categories();
});

final FutureProvider<List<BookEntry>> libraryShelfProvider =
    FutureProvider<List<BookEntry>>((Ref ref) async {
  ref.watch(libraryRevisionProvider);
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.bookshelf();
});

/// One catalogue row — the reader's header, and its resume point.
final FutureProviderFamily<BookEntry?, String> bookEntryProvider =
    FutureProvider.family<BookEntry?, String>((Ref ref, String bookId) async {
  ref.watch(libraryRevisionProvider);
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.book(bookId);
});

// --------------------------------------------------------------------- reader
/// A window of one book's text. Keyed by the window itself, so scrolling back to
/// a window already read is free.
/// The book's own headings, read once per book.
final FutureProviderFamily<List<BookChapter>, String> bookChaptersProvider =
    FutureProvider.family<List<BookChapter>, String>((Ref ref, String bookId) async {
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.chapters(bookId);
});

/// Matches for one (book, query) pair. Keyed by the pair, so a query already run
/// costs nothing to show again.
final FutureProviderFamily<List<BookHit>, ({String bookId, String query})>
    bookSearchProvider = FutureProvider.family<List<BookHit>,
        ({String bookId, String query})>(
    (Ref ref, ({String bookId, String query}) request) async {
  final String query = request.query.trim();
  if (query.length < 2) return const <BookHit>[];
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.searchInside(request.bookId, query);
});

final FutureProviderFamily<List<BookChunk>,
        ({String bookId, int from, int count})> bookChunksProvider =
    FutureProvider.family<List<BookChunk>, ({String bookId, int from, int count})>(
        (Ref ref, ({String bookId, int from, int count}) window) async {
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.chunks(
    window.bookId,
    from: window.from,
    count: window.count,
  );
});

final FutureProviderFamily<int, String> bookChunkCountProvider =
    FutureProvider.family<int, String>((Ref ref, String bookId) async {
  final LibraryRepository repository =
      await ref.watch(libraryRepositoryProvider.future);
  return repository.chunkCount(bookId);
});

// ----------------------------------------------------------------------- sync
/// What the last index sync did, or why it could not run.
class LibraryIndexState {
  const LibraryIndexState({this.busy = false, this.report, this.failure});

  final bool busy;
  final LibrarySyncReport? report;
  final Failure? failure;

  bool get hasRun => report != null;

  LibraryIndexState copyWith({
    bool? busy,
    LibrarySyncReport? report,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      LibraryIndexState(
        busy: busy ?? this.busy,
        report: report ?? this.report,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class LibraryIndexController extends StateNotifier<LibraryIndexState> {
  LibraryIndexController(this._resolveRepository, this._onChanged)
      : super(const LibraryIndexState());

  /// Resolved per call, not in the constructor: the screen can be shown before
  /// Isar has finished opening, and a sync started from a cold start still works.
  final Future<LibraryRepository> Function() _resolveRepository;
  final void Function() _onChanged;

  /// [force] skips the freshness window — that is what a pull-to-refresh is for.
  Future<void> sync({bool force = false}) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearFailure: true);

    try {
      final LibraryRepository repository = await _resolveRepository();
      final Either<Failure, LibrarySyncReport> result =
          await repository.syncIndex(force: force);
      result.fold(
        (Failure failure) => state = LibraryIndexState(
          report: state.report,
          failure: failure,
        ),
        (LibrarySyncReport report) {
          state = LibraryIndexState(report: report);
          _onChanged();
        },
      );
    } catch (error) {
      state = LibraryIndexState(
        report: state.report,
        failure: CacheFailure(cause: error),
      );
    }
  }
}

final StateNotifierProvider<LibraryIndexController, LibraryIndexState>
    libraryIndexProvider =
    StateNotifierProvider<LibraryIndexController, LibraryIndexState>((Ref ref) {
  return LibraryIndexController(
    () => ref.read(libraryRepositoryProvider.future),
    () => ref.read(libraryRevisionProvider.notifier).state++,
  );
});

// -------------------------------------------------------------------- actions
/// Installs and removals in flight, keyed by book id.
///
/// One controller for the whole screen rather than one per tile: a tile that
/// rebuilds must not lose the progress of the download it started.
class LibraryActionsController
    extends StateNotifier<Map<String, BookInstallProgress>> {
  LibraryActionsController(this._resolveRepository, this._onChanged)
      : super(const <String, BookInstallProgress>{});

  final Future<LibraryRepository> Function() _resolveRepository;
  final void Function() _onChanged;

  final Map<String, StreamSubscription<BookInstallProgress>> _subscriptions =
      <String, StreamSubscription<BookInstallProgress>>{};

  bool isBusy(String bookId) {
    final BookInstallProgress? progress = state[bookId];
    return progress != null &&
        (progress.phase == BookInstallPhase.downloading ||
            progress.phase == BookInstallPhase.installing);
  }

  Future<void> start(String bookId) async {
    if (_subscriptions.containsKey(bookId)) return;

    _put(
      bookId,
      const BookInstallProgress(phase: BookInstallPhase.downloading, ratio: 0),
    );

    final LibraryRepository repository = await _resolveRepository();
    final StreamSubscription<BookInstallProgress> subscription = repository
        .install(bookId)
        .listen(
      (BookInstallProgress progress) {
        _put(bookId, progress);
        if (progress.phase == BookInstallPhase.done) {
          _subscriptions.remove(bookId)?.cancel();
          _onChanged();
        } else if (progress.phase == BookInstallPhase.failed) {
          _subscriptions.remove(bookId)?.cancel();
        }
      },
      onError: (Object error) {
        _put(
          bookId,
          BookInstallProgress(
            phase: BookInstallPhase.failed,
            ratio: 0,
            error: error,
          ),
        );
        _subscriptions.remove(bookId)?.cancel();
      },
      cancelOnError: true,
    );
    _subscriptions[bookId] = subscription;
  }

  Future<void> cancel(String bookId) async {
    final LibraryRepository repository = await _resolveRepository();
    await repository.cancelInstall(bookId);
  }

  /// Deletes an installed book's text. The catalogue row stays — the book is
  /// still known, it is just no longer on the device.
  Future<void> remove(String bookId) async {
    final LibraryRepository repository = await _resolveRepository();
    await repository.remove(bookId);
    _onChanged();
  }

  /// Clears a finished or failed row so the tile goes back to its normal look.
  void dismiss(String bookId) {
    final Map<String, BookInstallProgress> next =
        Map<String, BookInstallProgress>.of(state)..remove(bookId);
    state = next;
  }

  void _put(String bookId, BookInstallProgress progress) {
    state = <String, BookInstallProgress>{...state, bookId: progress};
  }

  @override
  void dispose() {
    for (final StreamSubscription<BookInstallProgress> subscription
        in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}

final StateNotifierProvider<LibraryActionsController,
        Map<String, BookInstallProgress>> libraryActionsProvider =
    StateNotifierProvider<LibraryActionsController,
        Map<String, BookInstallProgress>>((Ref ref) {
  return LibraryActionsController(
    () => ref.read(libraryRepositoryProvider.future),
    () => ref.read(libraryRevisionProvider.notifier).state++,
  );
});

/// Convenience: the install row for one book, if any.
final ProviderFamily<BookInstallProgress?, String> bookInstallProvider =
    Provider.family<BookInstallProgress?, String>((Ref ref, String bookId) {
  return ref.watch(libraryActionsProvider)[bookId];
});

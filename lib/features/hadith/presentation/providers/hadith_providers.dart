import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/hadith/data/hadith_repository.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';

final Provider<HadithRepository> hadithRepositoryProvider =
    Provider<HadithRepository>((Ref ref) => HadithRepository());

final FutureProvider<HadithCorpus> hadithCorpusProvider =
    FutureProvider<HadithCorpus>(
  (Ref ref) => ref.watch(hadithRepositoryProvider).load(),
);

/// What the screen is asking for: a query, and the filters narrowing it.
class HadithFilter {
  const HadithFilter({
    this.query = '',
    this.books = const <int>{},
    this.grades = const <int>{},
    this.chapterBook,
    this.chapterId,
  });

  final String query;
  final Set<int> books;
  final Set<int> grades;
  final int? chapterBook;
  final int? chapterId;

  bool get hasFilters =>
      books.isNotEmpty || grades.isNotEmpty || chapterId != null;

  bool get isIdle => query.trim().isEmpty && !hasFilters;

  int get activeCount =>
      books.length + grades.length + (chapterId == null ? 0 : 1);

  HadithFilter copyWith({
    String? query,
    Set<int>? books,
    Set<int>? grades,
    int? chapterBook,
    int? chapterId,
    bool clearChapter = false,
  }) =>
      HadithFilter(
        query: query ?? this.query,
        books: books ?? this.books,
        grades: grades ?? this.grades,
        chapterBook: clearChapter ? null : (chapterBook ?? this.chapterBook),
        chapterId: clearChapter ? null : (chapterId ?? this.chapterId),
      );
}

class HadithController extends StateNotifier<HadithFilter> {
  HadithController() : super(const HadithFilter());

  void setQuery(String value) => state = state.copyWith(query: value);

  void toggleBook(int book) {
    final Set<int> next = <int>{...state.books};
    if (!next.remove(book)) next.add(book);
    state = state.copyWith(books: next);
  }

  void toggleGrade(int grade) {
    final Set<int> next = <int>{...state.grades};
    if (!next.remove(grade)) next.add(grade);
    state = state.copyWith(grades: next);
  }

  void setChapter(int book, int? chapter) => state = chapter == null
      ? state.copyWith(clearChapter: true, books: <int>{book})
      : state.copyWith(chapterBook: book, chapterId: chapter, books: <int>{book});

  void clear() => state = const HadithFilter();
}

final StateNotifierProvider<HadithController, HadithFilter>
    hadithFilterProvider =
    StateNotifierProvider<HadithController, HadithFilter>(
  (Ref ref) => HadithController(),
);

/// The most the list renders at once. Everything is searched; only the head of
/// the result is drawn, and the header says how many were found.
const int kHadithResultCap = 200;

class HadithResults {
  const HadithResults({required this.items, required this.total});

  final List<Hadith> items;
  final int total;

  bool get capped => total > items.length;
}

final Provider<HadithResults?> hadithResultsProvider =
    Provider<HadithResults?>((Ref ref) {
  final HadithCorpus? corpus = ref.watch(hadithCorpusProvider).valueOrNull;
  final HadithFilter filter = ref.watch(hadithFilterProvider);
  if (corpus == null) return null;

  final String query = normalizeArabic(filter.query);
  final List<Hadith> hits = <Hadith>[];

  if (filter.isIdle) {
    // Browsing rather than searching: the books in order, so the reader can walk
    // them without typing anything.
    for (final Hadith hadith in corpus.hadiths) {
      if (hits.length >= kHadithResultCap) break;
      hits.add(hadith);
    }
    return HadithResults(items: hits, total: corpus.hadiths.length);
  }

  final List<Hadith> matched = <Hadith>[];
  for (int i = 0; i < corpus.hadiths.length; i++) {
    final Hadith hadith = corpus.hadiths[i];
    if (filter.books.isNotEmpty && !filter.books.contains(hadith.book)) continue;
    if (filter.grades.isNotEmpty && !filter.grades.contains(hadith.grade)) {
      continue;
    }
    if (filter.chapterId != null &&
        (hadith.book != filter.chapterBook ||
            hadith.chapterId != filter.chapterId)) {
      continue;
    }
    if (query.isNotEmpty && !corpus.search[i].contains(query)) continue;
    matched.add(hadith);
  }

  // A match that lands early in the text is the one the reader means: «النية»
  // in «إنما الأعمال بالنيات» beats the same word buried in a long isnad.
  if (query.isNotEmpty) {
    matched.sort((Hadith a, Hadith b) {
      final int ra = corpus.search[a.index].indexOf(query);
      final int rb = corpus.search[b.index].indexOf(query);
      if (ra != rb) return ra.compareTo(rb);
      return a.text.length.compareTo(b.text.length);
    });
  }

  for (int i = 0; i < matched.length && i < kHadithResultCap; i++) {
    hits.add(matched[i]);
  }
  return HadithResults(items: hits, total: matched.length);
});

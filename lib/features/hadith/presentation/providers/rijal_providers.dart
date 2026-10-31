import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/hadith/data/rijal_repository.dart';
import 'package:awan/features/hadith/domain/entities/hadith.dart';
import 'package:awan/features/hadith/domain/entities/narrator.dart';

final Provider<RijalRepository> rijalRepositoryProvider =
    Provider<RijalRepository>((Ref ref) => RijalRepository());

final FutureProvider<RijalIndex> rijalIndexProvider =
    FutureProvider<RijalIndex>(
  (Ref ref) => ref.watch(rijalRepositoryProvider).load(),
);

/// What the researcher is asking of the narrator index.
class RijalQuery {
  const RijalQuery({this.query = '', this.categories = const <int>{}});

  final String query;
  final Set<int> categories;
}

class RijalController extends StateNotifier<RijalQuery> {
  RijalController() : super(const RijalQuery());

  void setQuery(String value) => state = RijalQuery(
        query: value,
        categories: state.categories,
      );

  void toggleCategory(int category) {
    final Set<int> next = <int>{...state.categories};
    if (!next.remove(category)) next.add(category);
    state = RijalQuery(query: state.query, categories: next);
  }
}

final StateNotifierProvider<RijalController, RijalQuery> rijalQueryProvider =
    StateNotifierProvider<RijalController, RijalQuery>(
  (Ref ref) => RijalController(),
);

const int kRijalResultCap = 300;

final Provider<List<Narrator>?> rijalResultsProvider =
    Provider<List<Narrator>?>((Ref ref) {
  final RijalIndex? index = ref.watch(rijalIndexProvider).valueOrNull;
  final RijalQuery query = ref.watch(rijalQueryProvider);
  if (index == null) return null;

  final String needle = normalizeArabic(query.query);
  final List<Narrator> hits = <Narrator>[];
  for (int i = 0; i < index.narrators.length; i++) {
    final Narrator narrator = index.narrators[i];
    if (query.categories.isNotEmpty &&
        !query.categories.contains(narrator.category)) {
      continue;
    }
    if (needle.isNotEmpty && !index.search[i].contains(needle)) continue;
    hits.add(narrator);
    if (hits.length >= kRijalResultCap) break;
  }
  return hits;
});

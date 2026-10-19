import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/midad/data/midad_engine.dart';
import 'package:awan/features/midad/domain/entities/midad_entities.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';

/// One index for the whole app session: the text is already in memory for the
/// reader, so the lab prepares its own normalised copy once and never again.
final FutureProvider<MidadIndex> midadIndexProvider =
    FutureProvider<MidadIndex>((Ref ref) async {
  final QuranText text = await ref.watch(quranTextProvider.future);
  final MushafIndex mushaf = await ref.watch(mushafIndexProvider.future);

  final Map<int, List<List<int>>> positions = <int, List<List<int>>>{};
  final Set<int> meccan = <int>{};
  for (final Surah surah in text.surahs) {
    if (surah.isMeccan) meccan.add(surah.id);
    final int count = text.ayahsOf(surah.id).length;
    final List<List<int>> rows = <List<int>>[];
    for (int ayah = 1; ayah <= count; ayah++) {
      final AyahPosition? p = mushaf.positionOf(surah.id, ayah);
      rows.add(<int>[p?.page ?? 0, p?.juz ?? 0, p?.hizb ?? 0, p?.sajda ?? 0]);
    }
    positions[surah.id] = rows;
  }

  return buildMidadIndexAsync(
    midadPayload(ayahs: text.ayahs, positions: positions, meccan: meccan),
  );
});

/// The live settings of the bench. Every change re-runs the count.
final StateProvider<MidadQuery> midadQueryProvider =
    StateProvider<MidadQuery>((Ref ref) => const MidadQuery());

/// The answer for the current query, recomputed synchronously — one pass over
/// 6 236 short strings, which is faster than a spinner would be honest.
final Provider<AsyncValue<MidadResult>> midadResultProvider =
    Provider<AsyncValue<MidadResult>>((Ref ref) {
  final AsyncValue<MidadIndex> index = ref.watch(midadIndexProvider);
  final MidadQuery query = ref.watch(midadQueryProvider);
  return index.whenData((MidadIndex i) => runMidadQuery(i, query));
});

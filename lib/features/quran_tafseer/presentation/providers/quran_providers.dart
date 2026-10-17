import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/quran_tafseer/data/datasources/quran_asset_datasource.dart';
import 'package:awan/features/quran_tafseer/data/repositories/quran_repository_impl.dart';
import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/domain/repositories/quran_repository.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';

final Provider<QuranLocalDataSource> quranLocalDataSourceProvider =
    Provider<QuranLocalDataSource>((Ref ref) => QuranLocalDataSource());

final Provider<QuranRepository> quranRepositoryProvider =
    Provider<QuranRepository>(
  (Ref ref) => QuranRepositoryImpl(
    local: ref.watch(quranLocalDataSourceProvider),
    isar: ref.watch(isarServiceProvider).isar,
  ),
);

/// The text, parsed once per process inside an isolate.
final FutureProvider<QuranText> quranTextProvider =
    FutureProvider<QuranText>((Ref ref) => ref.watch(quranRepositoryProvider).text());

/// The printed-Mushaf map. Only the paged reader and the page marker need it, so it
/// is a separate provider from the text.
final FutureProvider<MushafIndex> mushafIndexProvider =
    FutureProvider<MushafIndex>((Ref ref) => ref.watch(quranRepositoryProvider).index());

final FutureProviderFamily<TafsirText, int> tafsirProvider =
    FutureProvider.family<TafsirText, int>(
  (Ref ref, int id) => ref.watch(quranRepositoryProvider).tafsir(id),
);

final FutureProviderFamily<List<QuranSearchHit>, String> quranSearchProvider =
    FutureProvider.family<List<QuranSearchHit>, String>(
  (Ref ref, String query) => ref.watch(quranRepositoryProvider).search(query),
);

final FutureProvider<List<BookmarkedAyah>> quranBookmarksProvider =
    FutureProvider<List<BookmarkedAyah>>(
  (Ref ref) => ref.watch(quranRepositoryProvider).bookmarks(),
);

/// «علامة الوقوف» — the single verse the reader stopped at.
final FutureProvider<AyahRef?> quranStopMarkProvider =
    FutureProvider<AyahRef?>((Ref ref) => ref.watch(quranRepositoryProvider).stopMark());

/// Where to resume, newest first.
final FutureProvider<AyahRef?> quranLastReadProvider =
    FutureProvider<AyahRef?>((Ref ref) => ref.watch(quranRepositoryProvider).lastRead());

/// `سورة:آية` ⇄ the app-wide Mushaf number (1..6236) that the Mutashabihat
/// corpus addresses ayat by. Built from the surah table the Quran asset already
/// carries, so it costs a 114-iteration loop and no extra asset.
final Provider<MushafNumbering> mushafNumberingProvider =
    Provider<MushafNumbering>((Ref ref) {
  final QuranText? text = ref.watch(quranTextProvider).valueOrNull;
  if (text == null) {
    return MushafNumbering.empty();
  }
  return MushafNumbering.fromSurahs(text.surahs);
});

/// The absolute id of the verse the reader last stopped at — what the home card
/// opens the graph on, so the two sections are tied together instead of the
/// graph always landing on the same fixed verse.
final Provider<int?> quranLastReadAbsoluteIdProvider = Provider<int?>((Ref ref) {
  final AyahRef? last = ref.watch(quranLastReadProvider).valueOrNull;
  final MushafNumbering numbering = ref.watch(mushafNumberingProvider);
  if (last == null || !numbering.isReady) {
    return null;
  }
  final int id = numbering.idOf(last.surah, last.ayah);
  return id == 0 ? null : id;
});

/// Whether the reader tints the ayat that carry a similarity relation.
final Provider<bool> quranShowMutashabihatProvider =
    Provider<bool>((Ref ref) => ref.watch(settingsProvider).quranShowMutashabihat);

/// The reader's look: font, sizes and surface, all from the settings the user
/// changed (so they survive a restart without a second store).
final Provider<QuranAppearance> quranAppearanceProvider =
    Provider<QuranAppearance>((Ref ref) {
  final AppSettings settings = ref.watch(settingsProvider);
  return QuranAppearance(
    font: quranFontOf(settings.quranFontKey),
    ayahSize: settings.quranFontScale,
    tafsirSize: settings.quranTafsirScale,
    palette: QuranPaletteStyle.fromKey(settings.quranPalette),
  );
});

/// The write side of the reader, in one place so every screen behaves identically.
final Provider<QuranActions> quranActionsProvider = Provider<QuranActions>(
  (Ref ref) => QuranActions(ref),
);

class QuranActions {
  QuranActions(this._ref);

  final Ref _ref;

  QuranRepository get _repository => _ref.read(quranRepositoryProvider);

  Future<void> setStopMark(AyahRef ref) async {
    await _repository.setStopMark(ref);
    _ref.invalidate(quranStopMarkProvider);
    _ref.invalidate(quranLastReadProvider);
  }

  Future<void> clearStopMark() async {
    await _repository.clearStopMark();
    _ref.invalidate(quranStopMarkProvider);
  }

  Future<void> saveLastRead(AyahRef ref) async {
    await _repository.saveLastRead(ref);
    _ref.invalidate(quranLastReadProvider);
  }

  /// Returns true when the verse is bookmarked *after* the call.
  Future<bool> toggleBookmark(AyahRef ref) async {
    final bool exists = await _repository.isBookmarked(ref);
    if (exists) {
      await _repository.removeBookmark(ref);
    } else {
      await _repository.addBookmark(ref);
    }
    _ref.invalidate(quranBookmarksProvider);
    return !exists;
  }

  Future<void> setFont(String key) =>
      _ref.read(settingsControllerProvider.notifier).setQuranFont(key);

  Future<void> setAyahSize(double size) =>
      _ref.read(settingsControllerProvider.notifier).setQuranFontScale(size);

  Future<void> setTafsirSize(double size) =>
      _ref.read(settingsControllerProvider.notifier).setQuranTafsirSize(size);

  Future<void> setPalette(QuranPalette palette) => _ref
      .read(settingsControllerProvider.notifier)
      .setQuranPalette(palette.key);
}

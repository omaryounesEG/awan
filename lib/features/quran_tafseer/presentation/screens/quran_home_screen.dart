import 'package:flutter/material.dart';

import 'package:awan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_bookmarks_screen.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_reader_screen.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_search_screen.dart';

/// The Quran tab: resume, the stop marker, and the index of the 114 surahs.
///
/// Deliberately three things and nothing else. A reader who opens the Quran wants to
/// continue reading — the fastest path to that is one card that says exactly where
/// they stopped, not a dashboard.
class QuranHomeScreen extends ConsumerWidget {
  const QuranHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranPalette palette = appearance.palette;

    final AsyncValue<QuranText> textAsync = ref.watch(quranTextProvider);
    final MushafIndex index = ref.watch(mushafIndexProvider).valueOrNull ?? MushafIndex.empty;
    final AyahRef? lastRead = ref.watch(quranLastReadProvider).valueOrNull;
    final AyahRef? marker = ref.watch(quranStopMarkProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        elevation: 0,
        title: Text(
          l10n.quranTitle,
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.searchQuran,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QuranSearchScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.bookmarksTitle,
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QuranBookmarksScreen()),
            ),
          ),
        ],
      ),
      body: textAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Text('$error', style: TextStyle(color: palette.dim)),
        ),
        data: (QuranText text) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
          children: <Widget>[
            _ResumeCard(
              appearance: appearance,
              text: text,
              index: index,
              lastRead: lastRead,
              onRead: (AyahRef aref) => _open(context, ref, aref),
            ),
            const SizedBox(height: 10),
            _MarkerCard(
              appearance: appearance,
              text: text,
              index: index,
              marker: marker,
              onGo: (AyahRef aref) => _open(context, ref, aref),
              onClear: () => ref.read(quranActionsProvider).clearStopMark(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
              child: Text(
                l10n.surahIndex,
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            for (final Surah surah in text.surahs)
              _SurahTile(
                appearance: appearance,
                surah: surah,
                page: index.positionOf(surah.id, 1)?.page,
                placeLabel: surah.isMeccan ? l10n.makki : l10n.madani,
                ayahLabel: l10n.ayahWord,
                onTap: () => _open(context, ref, AyahRef(surah.id, 1)),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, AyahRef aref) {
    ref.read(quranActionsProvider).saveLastRead(aref);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(surah: aref.surah, ayah: aref.ayah),
      ),
    );
  }
}

/// «متابعة القراءة» — where the reader was, in one line, with one button.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.appearance,
    required this.text,
    required this.index,
    required this.lastRead,
    required this.onRead,
  });

  final QuranAppearance appearance;
  final QuranText text;
  final MushafIndex index;
  final AyahRef? lastRead;
  final void Function(AyahRef aref) onRead;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final QuranPalette palette = appearance.palette;
    final AyahRef aref = lastRead ?? const AyahRef(1, 1);
    final int? page = index.pageOf(aref.surah, aref.ayah);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_stories_outlined, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                lastRead == null ? l10n.startReading : l10n.continueReading,
                style: TextStyle(color: palette.dim, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${text.surah(aref.surah).nameAr} · '
            '${l10n.ayahWord} ${arabicDigits(aref.ayah)}'
            '${page == null ? '' : ' · ${l10n.page} ${arabicDigits(page)}'}',
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: palette.accent),
            onPressed: () => onRead(aref),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(l10n.continueButton),
          ),
        ],
      ),
    );
  }
}

/// «علامة الوقوف» — the one place the reader asked the app to remember.
class _MarkerCard extends StatelessWidget {
  const _MarkerCard({
    required this.appearance,
    required this.text,
    required this.index,
    required this.marker,
    required this.onGo,
    required this.onClear,
  });

  final QuranAppearance appearance;
  final QuranText text;
  final MushafIndex index;
  final AyahRef? marker;
  final void Function(AyahRef aref) onGo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final QuranPalette palette = appearance.palette;

    if (marker == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.bookmark_border, size: 18, color: palette.dim),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.noStopMarker,
                style: TextStyle(color: palette.dim, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    final int? page = index.pageOf(marker!.surah, marker!.ayah);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: palette.markWash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent, width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.bookmark, size: 19, color: palette.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.stopMarker,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${text.surah(marker!.surah).nameAr} · '
                  '${l10n.ayahWord} ${arabicDigits(marker!.ayah)}'
                  '${page == null ? '' : ' · ${l10n.page} ${arabicDigits(page)}'}',
                  style: TextStyle(color: palette.text, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.stopMarkerCleared,
            icon: Icon(Icons.close, size: 18, color: palette.dim),
            onPressed: onClear,
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.accent),
            onPressed: () => onGo(marker!),
            child: Text(l10n.goToStopMarker),
          ),
        ],
      ),
    );
  }
}

/// One surah in the index. The number sits in a decorated plate, as in print.
class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.appearance,
    required this.surah,
    required this.page,
    required this.placeLabel,
    required this.ayahLabel,
    required this.onTap,
  });

  final QuranAppearance appearance;
  final Surah surah;
  final int? page;
  final String placeLabel;
  final String ayahLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final QuranPalette palette = appearance.palette;
    // Built from a local copy: a `final` field is not promoted by a null check,
    // so `arabicDigits(page)` would not compile without this.
    final int? pageNumber = page;
    final String pagePart =
        pageNumber == null ? '' : ' · صفحة ${arabicDigits(pageNumber)}';
    return Card(
      elevation: 0,
      color: palette.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              arabicDigits(surah.id),
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          surah.nameAr,
          style: TextStyle(
            fontFamily: appearance.font.family,
            fontFamilyFallback: kQuranFallback,
            color: palette.text,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          '$placeLabel · ${arabicDigits(surah.ayahCount)} $ayahLabel$pagePart',
          style: TextStyle(color: palette.dim, fontSize: 11.5),
        ),
        trailing: Icon(Icons.chevron_left, color: palette.dim),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:awan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/graph_screen.dart';
import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/ayah_view.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/quran_settings_sheet.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/tafsir_sheet.dart';

/// How the reader pages through the text.
enum QuranReaderMode { pages, surah }

/// The reader.
///
/// Two honest ways to read the same text:
///
/// * [QuranReaderMode.pages] — like the printed Mushaf: one fixed page at a time,
///   604 of them, each with its own height. This is the default because it is what
///   makes «علامة الوقوف» exact: the marker *is* a page, so reopening the app lands
///   on the same words, not near them.
/// * [QuranReaderMode.surah] — the continuous flow, for reading a whole surah.
///
/// Nothing here needs the network: the text, the page map and the tafsir are all
/// bundled.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({
    super.key,
    this.surah,
    this.ayah,
    this.page,
    this.mode = QuranReaderMode.pages,
  });

  /// Open at a verse…
  final int? surah;
  final int? ayah;

  /// …or at a Mushaf page.
  final int? page;

  final QuranReaderMode mode;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  PageController? _pageController;
  ScrollController? _scrollController;
  late QuranReaderMode _mode;

  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentAyah = 1;

  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _currentPage = widget.page ?? 1;
    _currentSurah = widget.surah ?? 1;
    _currentAyah = widget.ayah ?? 1;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pageController?.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  /// The resume point is written on a debounce: sliding through five pages costs
  /// one write, not five — and never a write per scroll frame.
  void _remember(AyahRef aref) {
    _currentSurah = aref.surah;
    _currentAyah = aref.ayah;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(quranActionsProvider).saveLastRead(aref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final AsyncValue<QuranText> textAsync = ref.watch(quranTextProvider);
    final AsyncValue<MushafIndex> indexAsync = ref.watch(mushafIndexProvider);
    final AyahRef? marker = ref.watch(quranStopMarkProvider).valueOrNull;

    // «إظهار المتشابهات»: tint the verses the corpus knows about, so a reader can
    // see where the graph has something to say. The id set is a single Isar scan
    // per session, and it is only watched while the tint is on.
    final bool tintSimilar = ref.watch(quranShowMutashabihatProvider);
    final MushafNumbering numbering = ref.watch(mushafNumberingProvider);
    final Set<int> similarIds = tintSimilar
        ? (ref.watch(mutashabihatInvolvedIdsProvider).valueOrNull ??
            const <int>{})
        : const <int>{};

    final QuranText? text = textAsync.valueOrNull;
    final MushafIndex index = indexAsync.valueOrNull ?? MushafIndex.empty;

    if (text == null) {
      return Scaffold(
        backgroundColor: appearance.palette.background,
        appBar: AppBar(backgroundColor: appearance.palette.surface),
        body: Center(
          child: textAsync.hasError
              ? const Icon(Icons.error_outline, size: 34)
              : const CircularProgressIndicator(),
        ),
      );
    }

    // Promote a verse request into a page request once the index is known.
    if (_mode == QuranReaderMode.pages && _pageController == null && index.bySurah.isNotEmpty) {
      final int start = index.pageOf(_currentSurah, _currentAyah) ?? _currentPage;
      _currentPage = start;
      _pageController = PageController(initialPage: start - 1);
    }
    if (_mode == QuranReaderMode.surah && _scrollController == null) {
      _scrollController = ScrollController();
    }

    return Scaffold(
      backgroundColor: appearance.palette.background,
      appBar: AppBar(
        backgroundColor: appearance.palette.surface,
        foregroundColor: appearance.palette.text,
        elevation: 0,
        title: Text(
          _mode == QuranReaderMode.pages
              ? '${l10n.page} ${arabicDigits(_currentPage)}'
              : text.surah(_currentSurah).nameAr,
          style: TextStyle(
            fontFamily: appearance.font.family,
            fontFamilyFallback: kQuranFallback,
            fontSize: 18,
            color: appearance.palette.text,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.quranShowMutashabihat,
            icon: Icon(
              tintSimilar ? Icons.grain : Icons.grain_outlined,
              color: tintSimilar ? appearance.palette.accent : null,
            ),
            onPressed: () {
              ref
                  .read(settingsControllerProvider.notifier)
                  .setQuranShowMutashabihat(!tintSimilar);
              if (!tintSimilar) {
                // The corpus records 1298 of the 6236 ayat, so say what the tint
                // means once, instead of leaving the reader wondering why most
                // verses stay plain.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.quranShowMutashabihatOn)),
                );
              }
            },
          ),
          IconButton(
            tooltip: l10n.readingSettings,
            icon: const Icon(Icons.text_fields),
            onPressed: () => showQuranSettingsSheet(context, ref),
          ),
          IconButton(
            tooltip: l10n.stopMarker,
            icon: Icon(
              marker == null ? Icons.bookmark_border : Icons.bookmark,
              color: marker == null ? null : appearance.palette.accent,
            ),
            onPressed: () => _toggleMarker(marker),
          ),
          IconButton(
            tooltip: l10n.modeSurah,
            icon: Icon(
              _mode == QuranReaderMode.pages
                  ? Icons.auto_stories_outlined
                  : Icons.grid_view_outlined,
            ),
            onPressed: () => setState(() {
              _mode = _mode == QuranReaderMode.pages
                  ? QuranReaderMode.surah
                  : QuranReaderMode.pages;
              _scrollController?.dispose();
              _scrollController = null;
              _pageController?.dispose();
              _pageController = null;
            }),
          ),
        ],
      ),
      body: _mode == QuranReaderMode.pages
          ? _buildPagesMode(
              text, index, appearance, marker, numbering, similarIds)
          : _buildSurahMode(
              text, index, appearance, marker, numbering, similarIds),
    );
  }

  // ------------------------------------------------------------------ page mode
  Widget _buildPagesMode(
    QuranText text,
    MushafIndex index,
    QuranAppearance appearance,
    AyahRef? marker,
    MushafNumbering numbering,
    Set<int> similarIds,
  ) {
    if (_pageController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: index.pageCount,
      onPageChanged: (int position) {
        setState(() => _currentPage = position + 1);
        final AyahRef? first = index.firstRefOfPage(position + 1);
        if (first != null) _remember(first);
      },
      itemBuilder: (BuildContext context, int position) => _MushafPage(
        page: position + 1,
        text: text,
        index: index,
        appearance: appearance,
        marker: marker,
        numbering: numbering,
        similarIds: similarIds,
        onAyahTap: (AyahRef aref) => _openAyah(aref, numbering, similarIds),
      ),
    );
  }

  // ----------------------------------------------------------------- surah mode
  Widget _buildSurahMode(
    QuranText text,
    MushafIndex index,
    QuranAppearance appearance,
    AyahRef? marker,
    MushafNumbering numbering,
    Set<int> similarIds,
  ) {
    final Surah surah = text.surah(_currentSurah);
    final List<String> ayahs = text.ayahsOf(surah.id);
    if (_scrollController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // The resume point in this mode is an estimate from the scroll fraction: the
    // tiles have different heights, so only the *page* mode can be exact. It is
    // used for "continue reading", never for the marker.
    void rememberFromScroll() {
      if (!_scrollController!.hasClients) return;
      final double max = _scrollController!.position.maxScrollExtent;
      if (max <= 0 || ayahs.isEmpty) return;
      final double ratio = (_scrollController!.offset / max).clamp(0.0, 1.0);
      final int ayah = (ratio * (ayahs.length - 1)).round() + 1;
      _remember(AyahRef(surah.id, ayah));
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (ScrollEndNotification notification) {
        rememberFromScroll();
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 30),
        itemCount: ayahs.length + 1,
        itemBuilder: (BuildContext context, int position) {
          if (position == 0) {
            return SurahHeader(
              appearance: appearance,
              name: surah.nameAr,
              place: surah.isMeccan ? context.l10n.makki : context.l10n.madani,
              ayahCount: surah.ayahCount,
              ayahLabel: context.l10n.ayahWord,
              showBasmala: surah.bismillahPre,
            );
          }
          final int ayah = position;
          final AyahRef aref = AyahRef(surah.id, ayah);
          final AyahPosition? where = index.positionOf(surah.id, ayah);
          final bool pageStarts = position == 1 ||
              index.positionOf(surah.id, ayah - 1)?.page != where?.page;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (pageStarts && where != null)
                PageDivider(
                  appearance: appearance,
                  page: where.page,
                  juz: where.juz,
                  pageLabel: context.l10n.page,
                  juzLabel: context.l10n.juz,
                ),
              if (marker == aref) StopRibbon(appearance: appearance, label: context.l10n.stopMarker),
              AyahView(
                text: ayahs[ayah - 1],
                number: ayah,
                appearance: appearance,
                marked: marker == aref,
                similar: similarIds.contains(numbering.idOf(surah.id, ayah)),
                isSajda: where?.isSajda ?? false,
                sajdaLabel: context.l10n.sajdaAyah,
                onTap: () => _openAyah(aref, numbering, similarIds),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Opening a verse: the tafsir sheet, unless the reader turned the similarity
  /// tint on and this verse is one the corpus knows — then the graph, which is
  /// what makes the two sections work together.
  void _openAyah(AyahRef aref, MushafNumbering numbering, Set<int> similarIds) {
    _remember(aref);
    if (similarIds.isNotEmpty) {
      final int id = numbering.idOf(aref.surah, aref.ayah);
      if (id != 0 && similarIds.contains(id)) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext _) => GraphScreen(absoluteAyahId: id),
          ),
        );
        return;
      }
    }
    showTafsirSheet(context, ref, aref);
  }

  // ------------------------------------------------------------------- marker
  Future<void> _toggleMarker(AyahRef? marker) async {
    final AppLocalizations l10n = context.l10n;
    final QuranActions actions = ref.read(quranActionsProvider);

    if (marker != null) {
      await actions.clearStopMark();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stopMarkerCleared)),
        );
      }
      return;
    }

    final MushafIndex index = ref.read(mushafIndexProvider).valueOrNull ?? MushafIndex.empty;
    final AyahRef target = _mode == QuranReaderMode.pages
        ? (index.firstRefOfPage(_currentPage) ?? AyahRef(_currentSurah, _currentAyah))
        : AyahRef(_currentSurah, _currentAyah);
    await actions.setStopMark(target);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stopMarkerSet)),
      );
    }
  }
}

/// One printed page: its heading («surah · juz · page»), the verses it carries, and
/// the page number under them.
class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.page,
    required this.text,
    required this.index,
    required this.appearance,
    required this.marker,
    required this.numbering,
    required this.similarIds,
    required this.onAyahTap,
  });

  final int page;
  final QuranText text;
  final MushafIndex index;
  final QuranAppearance appearance;
  final AyahRef? marker;
  final MushafNumbering numbering;
  final Set<int> similarIds;
  final void Function(AyahRef aref) onAyahTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<AyahRef> refs = index.pageRefs(page);
    final bool isMarked = isMarkedPage(marker, index, page);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PageHeading(
            appearance: appearance,
            surahName: refs.isEmpty ? '' : text.surah(refs.first.surah).nameAr,
            juz: refs.isEmpty ? 1 : (index.positionOf(refs.first.surah, refs.first.ayah)?.juz ?? 1),
            page: page,
            pageLabel: l10n.page,
            juzLabel: l10n.juz,
          ),
          if (isMarked)
            StopRibbon(appearance: appearance, label: l10n.stopMarker),
          for (final AyahRef aref in refs)
            AyahView(
              text: text.ayah(aref.surah, aref.ayah)?.text ?? '',
              number: aref.ayah,
              appearance: appearance,
              marked: marker == aref,
              similar:
                  similarIds.contains(numbering.idOf(aref.surah, aref.ayah)),
              isSajda: index.positionOf(aref.surah, aref.ayah)?.isSajda ?? false,
              sajdaLabel: l10n.sajdaAyah,
              onTap: () => onAyahTap(aref),
            ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              arabicDigits(page),
              style: TextStyle(
                fontFamily: appearance.font.family,
                fontFamilyFallback: kQuranFallback,
                fontSize: 15,
                color: appearance.palette.dim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The running head of a Mushaf page.
class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.appearance,
    required this.surahName,
    required this.juz,
    required this.page,
    required this.pageLabel,
    required this.juzLabel,
  });

  final QuranAppearance appearance;
  final String surahName;
  final int juz;
  final int page;
  final String pageLabel;
  final String juzLabel;

  @override
  Widget build(BuildContext context) {
    final QuranPalette palette = appearance.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              surahName,
              style: TextStyle(
                fontFamily: appearance.font.family,
                fontFamilyFallback: kQuranFallback,
                fontSize: 14,
                color: palette.accent,
              ),
            ),
          ),
          Text(
            '$juzLabel ${arabicDigits(juz)} · $pageLabel ${arabicDigits(page)}',
            style: TextStyle(fontSize: 11.5, color: palette.dim),
          ),
        ],
      ),
    );
  }
}

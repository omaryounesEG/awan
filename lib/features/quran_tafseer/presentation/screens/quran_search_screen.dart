import 'dart:async';

import 'package:flutter/material.dart';

import 'package:awan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_reader_screen.dart';
import 'package:awan/features/semantic_search/domain/entities/semantic_entities.dart';
import 'package:awan/features/semantic_search/presentation/providers/semantic_providers.dart';

/// Full-text search over the Mushaf, offline.
///
/// The query is typed with whatever diacritics the keyboard produces and matched
/// against a normalised copy of the text (see `QuranRepositoryImpl.search`), which is
/// why searching «الرحمن» finds «ٱلرَّحْمَـٰنِ». The corpus is prepared once per
/// process, so each keystroke costs a scan and not a re-parse.
class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
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
    // One scan per pause, not one per keystroke — 6,236 verses deserve a debounce.
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  /// Searching on a phone keyboard is a chore — and for an older reader it is the
  /// hardest part of the screen. These are the words people look for, one tap each.
  static const List<String> _suggestions = <String>[
    // A phrase, not a word: it is the shortest demonstration that the search
    // reads meaning — no verse contains these words together.
    'الصبر عند فقدان العمل',
    'الرحمن',
    'الصبر',
    'الجنة',
    'موسى',
    'الصلاة',
    'اليتيم',
  ];

  void _search(String query) {
    _controller.text = query;
    setState(() => _query = query);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranPalette palette = appearance.palette;
    // Words and meaning, fused. With no encoder on the device this silently
    // degrades to the lexical half rather than showing an empty screen.
    final AsyncValue<List<SemanticHit>> results = _query.length < 2
        ? const AsyncValue<List<SemanticHit>>.data(<SemanticHit>[])
        : ref.watch(semanticSearchProvider(_query));
    final SemanticModelState model = ref.watch(semanticModelProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: palette.text),
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: l10n.searchHint,
            hintStyle: TextStyle(color: palette.dim),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close, color: palette.dim),
            onPressed: () {
              _controller.clear();
              setState(() => _query = '');
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: <Widget>[
                Icon(Icons.wifi_off_outlined, size: 14, color: palette.dim),
                const SizedBox(width: 6),
                Text(
                  l10n.searchOffline,
                  style: TextStyle(color: palette.dim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (model.phase != SemanticModelPhase.ready)
            _SemanticBanner(model: model, palette: palette),
          Expanded(
            child: results.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: palette.accent),
                ),
              ),
              error: (Object error, StackTrace stack) => Center(
                child: Text('$error', style: TextStyle(color: palette.dim)),
              ),
              data: (List<SemanticHit> hits) {
                if (_query.length < 2) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            l10n.searchHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.dim, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String word in _suggestions)
                                ActionChip(
                                  label: Text(
                                    word,
                                    style: TextStyle(
                                      fontFamily: appearance.font.family,
                                      fontFamilyFallback: kQuranFallback,
                                      fontSize: 15,
                                      color: palette.text,
                                    ),
                                  ),
                                  backgroundColor: palette.surface,
                                  side: BorderSide(color: palette.divider),
                                  onPressed: () => _search(word),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (hits.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.searchNoResults,
                      style: TextStyle(color: palette.dim, fontSize: 15),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: hits.length,
                  separatorBuilder: (_, __) => Divider(color: palette.divider, height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final SemanticHit hit = hits[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => QuranReaderScreen(
                            surah: hit.surah,
                            ayah: hit.ayah,
                          ),
                        ),
                      ),
                      title: Row(
                        children: <Widget>[
                          Text(
                            '${hit.surahName} · ${l10n.ayahWord} ${arabicDigits(hit.ayah)}',
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hit.matchedByMeaning && !hit.matchedByWords) ...<Widget>[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: palette.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.semanticMeaningChip,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          hit.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: appearance.font.family,
                            fontFamilyFallback: kQuranFallback,
                            fontSize: appearance.ayahSize * 0.62,
                            height: 1.8,
                            color: palette.text,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// «البحث بالمعنى» needs a 118 MB encoder that cannot live in the APK.
///
/// The banner is one row, not a screen: say what it is, how big it is, and let
/// the reader start it — and keep the word search working underneath meanwhile.
class _SemanticBanner extends ConsumerWidget {
  const _SemanticBanner({required this.model, required this.palette});

  final SemanticModelState model;
  final QuranPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool downloading = model.phase == SemanticModelPhase.downloading;
    final bool failed = model.phase == SemanticModelPhase.failed;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withOpacity(0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome_outlined, size: 16, color: palette.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              downloading
                  ? l10n.semanticDownloading((model.progress * 100).round())
                  : failed
                      ? l10n.semanticFailed
                      : l10n.semanticModelHint,
              style: TextStyle(color: palette.dim, fontSize: 11),
            ),
          ),
          if (downloading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: model.progress == 0 ? null : model.progress,
                color: palette.accent,
              ),
            )
          else
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => ref
                  .read(semanticModelProvider.notifier)
                  .download(ref.read(settingsProvider).libraryCdnBaseUrl),
              child: Text(
                failed ? l10n.semanticRetry : l10n.semanticDownload,
                style: TextStyle(color: palette.accent, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}

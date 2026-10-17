import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/utils/arabic_text.dart';
import 'package:awan/features/knowledge_graph/domain/entities/ayah_reference.dart';
import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The ayah number as the interface language writes numbers.
String _digits(int value, bool arabicUi) => arabicUi ? arabicDigits(value) : '$value';

/// What the reader chose in [showAyahSearch].
///
/// Either a verse, or a request for the surah/ayah dropdowns — the sheet is the
/// fast path, never the only path.
class AyahSearchOutcome {
  const AyahSearchOutcome.ayah(this.absoluteId) : bySurah = false;
  const AyahSearchOutcome.bySurah()
      : absoluteId = 0,
        bySurah = true;

  final int absoluteId;
  final bool bySurah;
}

/// Search the Mushaf by words or by reference, from inside the graph screen.
Future<AyahSearchOutcome?> showAyahSearch(BuildContext context) {
  return showModalBottomSheet<AyahSearchOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => const _AyahSearchSheet(),
  );
}

class _AyahSearchSheet extends ConsumerStatefulWidget {
  const _AyahSearchSheet();

  @override
  ConsumerState<_AyahSearchSheet> createState() => _AyahSearchSheetState();
}

class _AyahSearchSheetState extends ConsumerState<_AyahSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Typing a reference does not need the corpus; typing words does, so the
  /// scan starts only after the reader pauses.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  int? Function(String) _nameResolver(QuranText? text) {
    if (text == null) return (String _) => null;
    final Map<String, int> byName = <String, int>{
      for (final Surah surah in text.surahs) normalizeArabic(surah.nameAr): surah.id,
    };
    return (String name) => byName[name];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final QuranText? text = ref.watch(quranTextProvider).valueOrNull;
    final MushafNumbering numbering = ref.watch(mushafNumberingProvider);

    final String trimmed = _query.trim();
    final AyahReference? reference =
        AyahReference.parse(trimmed, surahIdOfName: _nameResolver(text));
    final bool validReference = reference != null &&
        numbering.ayahCountOf(reference.surah) >= reference.ayah;

    final AsyncValue<List<QuranSearchHit>> hits = trimmed.length >= 2 &&
            !validReference
        ? ref.watch(quranSearchProvider(normalizeArabic(trimmed)))
        : const AsyncValue<List<QuranSearchHit>>.data(<QuranSearchHit>[]);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 4.h, 16.w, 8.h),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.ayahSearchHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (validReference)
              ListTile(
                leading: const Icon(Icons.my_location_outlined),
                title: Text(
                  l10n.ayahSearchGoTo(
                    text?.surah(reference.surah).nameAr ?? _digits(reference.surah, arabicUi),
                    _digits(reference.ayah, arabicUi),
                  ),
                ),
                subtitle: Text(
                  text?.ayah(reference.surah, reference.ayah)?.text ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(
                  AyahSearchOutcome.ayah(numbering.idOf(reference.surah, reference.ayah)),
                ),
              )
            else if (trimmed.length < 2)
              Expanded(
                child: _SearchHint(
                  title: l10n.ayahSearchHint,
                  subtitle: l10n.ayahSearchExamples,
                  suggestions: <String>[
                    l10n.ayahSearchExampleWords,
                    l10n.ayahSearchExampleReference,
                    l10n.ayahSearchExampleNamed,
                  ],
                  // A tap has to fill the field the same way typing would, or the
                  // example teaches nothing about what the field accepts.
                  onSuggestion: (String value) {
                    _controller.text = value;
                    setState(() => _query = value);
                  },
                ),
              )
            else
              Expanded(
                child: hits.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace _) =>
                      Center(child: Text(l10n.searchNoResults)),
                  data: (List<QuranSearchHit> results) {
                    if (results.isEmpty) {
                      return Center(child: Text(l10n.searchNoResults));
                    }
                    return ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final QuranSearchHit hit = results[index];
                        return ListTile(
                          title: Text(
                            l10n.graphNodeNamedLabel(hit.surahName, _digits(hit.ayah, arabicUi)),
                            style: TextStyle(fontSize: 13.sp),
                          ),
                          subtitle: Text(
                            hit.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15.sp),
                          ),
                          onTap: () => Navigator.of(context).pop(
                            AyahSearchOutcome.ayah(numbering.idOf(hit.surah, hit.ayah)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(const AyahSearchOutcome.bySurah()),
                icon: const Icon(Icons.list_alt),
                label: Text(l10n.ayahSearchBySurah),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    required this.title,
    required this.subtitle,
    required this.suggestions,
    required this.onSuggestion,
  });

  final String title;
  final String subtitle;
  final List<String> suggestions;
  final void Function(String value) onSuggestion;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
        child: Column(
          children: <Widget>[
            Icon(Icons.search, size: 34.sp, color: Theme.of(context).colorScheme.outline),
            SizedBox(height: 10.h),
            Text(title, textAlign: TextAlign.center),
            SizedBox(height: 4.h),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final String suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestion(suggestion),
                  ),
              ],
            ),
          ],
        ),
      );
}

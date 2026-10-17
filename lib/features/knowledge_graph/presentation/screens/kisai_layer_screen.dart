import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/knowledge_graph/domain/entities/kisai_entities.dart';
import 'package:awan/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/graph_screen.dart';
import 'package:awan/features/quran_tafseer/domain/entities/mushaf_numbering.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/l10n/app_localizations.dart';

/// الكسائي's two lists, browsable.
///
/// The graph answers «what looks like *this* verse?»; this answers «which verses
/// did the earliest author on the subject mark at all?» — including the ones he
/// marked as having no counterpart, which is the same judgement the graph uses to
/// drop a link.
class KisaiLayerScreen extends ConsumerStatefulWidget {
  const KisaiLayerScreen({super.key});

  @override
  ConsumerState<KisaiLayerScreen> createState() => _KisaiLayerScreenState();
}

class _KisaiLayerScreenState extends ConsumerState<KisaiLayerScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _unique = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _digits(int value, bool arabicUi) => arabicUi ? arabicDigits(value) : '$value';

  void _open(int absoluteAyahId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GraphScreen(absoluteAyahId: absoluteAyahId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool arabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final QuranText? text = ref.watch(quranTextProvider).valueOrNull;
    final MushafNumbering numbering = ref.watch(mushafNumberingProvider);
    final AsyncValue<KisaiLayer> layerAsync = ref.watch(kisaiLayerProvider);
    final Set<int> inGraph =
        ref.watch(mutashabihatInvolvedIdsProvider).valueOrNull ?? const <int>{};

    // `surah()` indexes the table directly, so an id outside 1..114 would throw
    // rather than answer — and an unresolved id is exactly what a stale asset can
    // hand us.
    String nameOf(int surah) =>
        (surah >= 1 && surah <= 114) ? (text?.surah(surah).nameAr ?? '') : '';

    String labelFor(KisaiVerse verse) {
      final int surah = verse.surah > 0 ? verse.surah : (numbering.locate(verse.absoluteAyahId)?.surah ?? 0);
      final int ayah = verse.ayah > 0 ? verse.ayah : (numbering.locate(verse.absoluteAyahId)?.ayah ?? 0);
      final String name = nameOf(surah);
      if (name.isEmpty) {
        return l10n.graphNodeLabel(_digits(surah, arabicUi), _digits(ayah, arabicUi));
      }
      return l10n.graphNodeNamedLabel(name, _digits(ayah, arabicUi));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kisaiLayerTitle)),
      body: layerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(child: Text(l10n.graphSeedFailed)),
        data: (KisaiLayer layer) {
          final List<KisaiVerse> all = _unique ? layer.unique : layer.similar;
          final List<KisaiVerse> shown = layer.filter(all, _query, nameOf: nameOf);

          return Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.w, 10.h, 16.w, 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.kisaiLayerSubtitle(
                        _digits(layer.similar.length, arabicUi),
                        _digits(layer.unique.length, arabicUi),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _controller,
                      onChanged: (String value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.kisaiFilterHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(l10n.kisaiSimilarTab(_digits(layer.similar.length, arabicUi))),
                          selected: !_unique,
                          onSelected: (_) => setState(() => _unique = false),
                        ),
                        ChoiceChip(
                          label: Text(l10n.kisaiUniqueTab(_digits(layer.unique.length, arabicUi))),
                          selected: _unique,
                          onSelected: (_) => setState(() => _unique = true),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    if (_unique)
                      Text(
                        l10n.kisaiUniqueHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: shown.isEmpty
                    ? Center(child: Text(l10n.kisaiNoMatch))
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final KisaiVerse verse = shown[index];
                          final String detail =
                              verse.bookText.isNotEmpty ? verse.bookText : verse.quoted;
                          return ListTile(
                            title: Text(
                              labelFor(verse),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: detail.isEmpty
                                ? null
                                : Text(
                                    detail,
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                            trailing: !_unique && inGraph.contains(verse.absoluteAyahId)
                                ? Icon(
                                    Icons.hub_outlined,
                                    size: 18.sp,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : Icon(
                                    Icons.chevron_left,
                                    size: 18.sp,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            onTap: () => _open(verse.absoluteAyahId),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

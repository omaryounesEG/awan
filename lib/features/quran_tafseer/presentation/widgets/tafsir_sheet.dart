import 'package:flutter/material.dart';

import 'package:awan/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/widgets/ayah_ornament.dart';

/// The tafsir card for one verse.
///
/// Opened by tapping a verse while reading, so it is a sheet and not a screen: the
/// reader keeps the verse on screen behind it, and closing it puts them back exactly
/// where they were. Sizes are controllable here (the tafsir has its own scale), and
/// the marker button is the «علامة الوقوف» the reader asked for — set from the very
/// verse they are looking at.
Future<void> showTafsirSheet(
  BuildContext context,
  WidgetRef ref,
  AyahRef aref,
) {
  final QuranAppearance appearance = ref.read(quranAppearanceProvider);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: appearance.palette.background,
    builder: (BuildContext sheetContext) => _TafsirSheet(aref: aref),
  );
}

class _TafsirSheet extends ConsumerWidget {
  const _TafsirSheet({required this.aref});

  final AyahRef aref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranPalette palette = appearance.palette;
    final AsyncValue<QuranText> text = ref.watch(quranTextProvider);
    final AsyncValue<TafsirText> tafsir = ref.watch(tafsirProvider(16));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.menu_book_outlined, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.quranTitle} · ${arabicDigits(aref.surah)}:${arabicDigits(aref.ayah)}',
                  style: TextStyle(
                    color: palette.dim,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.copyAyah,
                icon: Icon(Icons.copy_all_outlined, size: 19, color: palette.dim),
                onPressed: () async {
                  final String verse =
                      text.valueOrNull?.ayah(aref.surah, aref.ayah)?.text ?? '';
                  await Clipboard.setData(ClipboardData(text: verse));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copied)),
                    );
                  }
                },
              ),
            ],
          ),
          text.when(
            data: (QuranText value) => Text.rich(
              ayahWithMedallion(
                text: value.ayah(aref.surah, aref.ayah)?.text ?? '',
                ayah: aref.ayah,
                appearance: appearance,
                palette: palette,
                sizeFactor: 0.9,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: appearance.font.family,
                fontFamilyFallback: kQuranFallback,
                fontSize: appearance.ayahSize * appearance.font.sizeFactor * 0.9,
                height: appearance.lineHeight,
                color: palette.text,
              ),
            ),
            loading: () => const SizedBox(height: 40),
            error: (Object error, StackTrace stack) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.divider),
          const SizedBox(height: 8),
          tafsir.when(
            data: (TafsirText value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            value.name,
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (value.author.isNotEmpty)
                            Text(
                              value.author,
                              style: TextStyle(color: palette.dim, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    _SizeStepper(
                      appearance: appearance,
                      onBigger: () => ref
                          .read(quranActionsProvider)
                          .setTafsirSize(appearance.tafsirSize + 1.5),
                      onSmaller: () => ref
                          .read(quranActionsProvider)
                          .setTafsirSize(appearance.tafsirSize - 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value.textFor(aref.surah, aref.ayah) ?? '',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: appearance.tafsirSize,
                    height: 1.85,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (Object error, StackTrace stack) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.background,
                ),
                onPressed: () async {
                  await ref.read(quranActionsProvider).setStopMark(aref);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.stopMarkerSet)),
                    );
                  }
                },
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: Text(l10n.setStopHere),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.text,
                  side: BorderSide(color: palette.accent),
                ),
                onPressed: () => ref.read(quranActionsProvider).toggleBookmark(aref),
                icon: const Icon(Icons.star_border, size: 18),
                label: Text(l10n.bookmark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeStepper extends StatelessWidget {
  const _SizeStepper({
    required this.appearance,
    required this.onBigger,
    required this.onSmaller,
  });

  final QuranAppearance appearance;
  final VoidCallback onBigger;
  final VoidCallback onSmaller;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onSmaller,
            icon: const Icon(Icons.text_decrease, size: 19),
            tooltip: '−',
          ),
          IconButton(
            onPressed: onBigger,
            icon: const Icon(Icons.text_increase, size: 19),
            tooltip: '+',
          ),
        ],
      );
}

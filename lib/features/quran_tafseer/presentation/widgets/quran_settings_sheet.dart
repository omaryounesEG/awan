import 'package:flutter/material.dart';

import 'package:awan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';

/// The reader's controls, kept in one sheet so the reading screen stays clean.
///
/// Everything here writes straight to the settings store, so a size chosen at night
/// is still the size in the morning — the reader never has to be configured twice.
Future<void> showQuranSettingsSheet(BuildContext context, WidgetRef ref) {
  final QuranAppearance appearance = ref.read(quranAppearanceProvider);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: appearance.palette.background,
    builder: (BuildContext sheetContext) => const _QuranSettingsSheet(),
  );
}

class _QuranSettingsSheet extends ConsumerWidget {
  const _QuranSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranPalette palette = appearance.palette;
    final QuranActions actions = ref.read(quranActionsProvider);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        children: <Widget>[
          Text(
            l10n.readingSettings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: palette.text),
          ),
          const SizedBox(height: 14),

          // ------------------------------------------------------------ the font
          _Label(text: l10n.quranFont, color: palette.dim),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final QuranFont font in kQuranFonts)
                ChoiceChip(
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? font.labelAr
                        : font.labelEn,
                    style: TextStyle(
                      fontFamily: font.family,
                      color: appearance.font.key == font.key ? palette.background : palette.text,
                    ),
                  ),
                  selected: appearance.font.key == font.key,
                  selectedColor: palette.accent,
                  backgroundColor: palette.surface,
                  onSelected: (bool _) => actions.setFont(font.key),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // ----------------------------------------------------------- the sizes
          _Label(
            text: '${l10n.ayahFontSize} · ${appearance.ayahSize.round()}',
            color: palette.dim,
          ),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => actions.setAyahSize(appearance.ayahSize - 2),
                icon: Icon(Icons.text_decrease, color: palette.text),
              ),
              Expanded(
                child: Slider(
                  value: appearance.ayahSize.clamp(20, 60),
                  min: 20,
                  max: 60,
                  divisions: 20,
                  activeColor: palette.accent,
                  onChanged: actions.setAyahSize,
                ),
              ),
              IconButton(
                onPressed: () => actions.setAyahSize(appearance.ayahSize + 2),
                icon: Icon(Icons.text_increase, color: palette.text),
              ),
            ],
          ),
          Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: appearance.font.family,
              fontFamilyFallback: kQuranFallback,
              fontSize: appearance.ayahSize * appearance.font.sizeFactor,
              height: appearance.lineHeight,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 16),
          _Label(
            text: '${l10n.tafsirFontSize} · ${appearance.tafsirSize.round()}',
            color: palette.dim,
          ),
          Slider(
            value: appearance.tafsirSize.clamp(13, 30),
            min: 13,
            max: 30,
            divisions: 17,
            activeColor: palette.accent,
            onChanged: actions.setTafsirSize,
          ),
          const SizedBox(height: 10),

          // -------------------------------------------------------- the surface
          _Label(text: l10n.screenColour, color: palette.dim),
          Row(
            children: <Widget>[
              for (final QuranPalette option in QuranPalette.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: _Swatch(
                    palette: option,
                    selected: option == palette,
                    label: _paletteLabel(l10n, option),
                    onTap: () => actions.setPalette(option),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _paletteLabel(AppLocalizations l10n, QuranPalette palette) => switch (palette) {
      QuranPalette.paper => l10n.palettePaper,
      QuranPalette.sepia => l10n.paletteSepia,
      QuranPalette.dark => l10n.paletteDark,
      QuranPalette.oled => l10n.paletteOled,
    };

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final QuranPalette palette;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              width: 54,
              height: 40,
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? palette.accent : palette.divider,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Text('ا', style: TextStyle(color: palette.text, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10.5, color: palette.dim)),
          ],
        ),
      );
}

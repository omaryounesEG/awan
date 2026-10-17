import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_home_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The Quran on the home screen: not a fifth square in the shortcut grid but a
/// card of its own, because it is the one destination a reader comes back to
/// daily and the card can say *where they stopped*.
///
/// It reads the saved position off the same repository the reader writes to, so
/// the card and the «متابعة القراءة» card can never disagree.
class QuranShortcutCard extends ConsumerWidget {
  const QuranShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSettings settings = ref.watch(settingsProvider);
    final AsyncValue<QuranText> text = ref.watch(quranTextProvider);
    final int surah = settings.lastReadSurah;
    final int ayah = settings.lastReadAyah;

    final String subtitle;
    if (text.isLoading) {
      subtitle = l10n.quranTitle;
    } else if (text.hasError) {
      subtitle = l10n.readerMode;
    } else {
      final QuranText? value = text.valueOrNull;
      final Surah? row = value?.surah(surah);
      final bool arabic = settings.localeCode == 'ar';
      final String name = row == null
          ? ''
          : (arabic ? row.nameAr : (row.nameEn.isEmpty ? row.nameAr : row.nameEn));
      subtitle = name.isEmpty
          ? l10n.startReading
          : '${l10n.continueReading} · $name ${l10n.ayahWord} $ayah';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const QuranHomeScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_outlined,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.quranTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

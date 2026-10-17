import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/l10n/app_localizations.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_reader_screen.dart';

/// Saved verses — the user's own list, not the single stop marker.
class QuranBookmarksScreen extends ConsumerWidget {
  const QuranBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final QuranAppearance appearance = ref.watch(quranAppearanceProvider);
    final QuranPalette palette = appearance.palette;
    final AsyncValue<List<BookmarkedAyah>> bookmarks = ref.watch(quranBookmarksProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        title: Text(l10n.bookmarksTitle, style: TextStyle(color: palette.text)),
      ),
      body: bookmarks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text('$error', style: TextStyle(color: palette.dim))),
        data: (List<BookmarkedAyah> rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l10n.noBookmarks,
                style: TextStyle(color: palette.dim, fontSize: 15),
              ),
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(color: palette.divider, height: 1),
            itemBuilder: (BuildContext context, int index) {
              final BookmarkedAyah row = rows[index];
              return ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QuranReaderScreen(surah: row.surah, ayah: row.ayah),
                  ),
                ),
                leading: Icon(Icons.bookmark, color: palette.accent, size: 19),
                title: Text(
                  '${row.surahName} · ${l10n.ayahWord} ${arabicDigits(row.ayah)}',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    row.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: appearance.font.family,
                      fontFamilyFallback: kQuranFallback,
                      fontSize: appearance.ayahSize * 0.6,
                      height: 1.8,
                      color: palette.text,
                    ),
                  ),
                ),
                trailing: IconButton(
                  tooltip: l10n.stopMarkerCleared,
                  icon: Icon(Icons.delete_outline, size: 19, color: palette.dim),
                  onPressed: () => ref
                      .read(quranActionsProvider)
                      .toggleBookmark(AyahRef(row.surah, row.ayah)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
